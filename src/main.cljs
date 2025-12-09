(ns main
  (:require
   [app-root-path :refer [toString]]
   [child_process :refer [execSync]]
   [cljs-node-io.core :refer [make-parents slurp]]
   [clojure.edn :refer [read-string]]
   [core :refer [port]]
   [fs :refer [cpSync mkdtempSync renameSync rmSync]]
   [mount.core :refer [defstate start]]
   [os :refer [homedir tmpdir]]
   [path :refer [join]]
   [playwright :refer [chromium]]
   [promesa.core :as promesa]
   [ws :refer [WebSocketServer]]))

(def browser-external-extension-paths
  {"arc" (join (homedir) "Library/Application Support/Arc/User Data/External Extensions")
; https://developer.chrome.com/docs/extensions/mv3/external_extensions/#preference-mac
   "chrome" (join (homedir) "Library/Application Support/Google/Chrome/External Extensions")
; https://learn.microsoft.com/en-us/microsoft-edge/extensions-chromium/developer-guide/alternate-distribution-options#using-a-preferences-json-file-macos-and-linux
   "edge" (join (homedir) "Library/Application Support/Microsoft Edge/External Extensions")})

(defn get-preference-source-path
  [browser]
  (join (toString) "preferences" (str browser ".json")))

(defn get-preference-target-path
  [browser id]
  (join (browser-external-extension-paths browser) (str id ".json")))

(defn install-extension-preference-file
  [browser id]
  (println (str "Installing " id " for " browser))
  (make-parents (get-preference-target-path browser id))
  (cpSync (get-preference-source-path browser) (get-preference-target-path browser id)))

(def browser-app-names
  {"arc" "Arc"
   "chrome" "Google Chrome"
   "edge" "Microsoft Edge"})

(defn get-quit-command
  [browser]
  (str "osascript -e 'quit app \"" (browser-app-names browser) "\"'"))

(defn browser-running?
  [browser]
  (try (execSync (str "pgrep -x '" (browser-app-names browser) "'"))
       true
       (catch js/Error _ false)))

(defn quit-browser
  [browser]
  (execSync (get-quit-command browser))
  (promesa/loop []
    (when (browser-running? browser)
      (promesa/delay 1000)
      (promesa/recur))))

(def temp-directory
  (tmpdir))

(def app-temp-directory
  (mkdtempSync (join temp-directory "extension-")))

(def browser-user-data-paths
  {"arc" (join (homedir) "Library/Application Support/Arc/User Data")
; https://chromium.googlesource.com/chromium/src/+/main/docs/user_data_dir.md#:~:text=%5BChrome%5D%20~/Library/Application%20Support/Google/Chrome
   "chrome" (join (homedir) "Library/Application Support/Google/Chrome")
   "edge" (join (homedir) "Library/Application Support/Microsoft Edge")})

(defn stage-user-data
  [browser]
  (cpSync (browser-user-data-paths browser) app-temp-directory (clj->js {:recursive true})))

(def remote-debugging-port
  "9222")

(defn get-launch-command
  [browser]
  (str "open -a '" (browser-app-names browser) "' --args --remote-debugging-port=" remote-debugging-port " --user-data-dir=" app-temp-directory))

(def launch-browser
  (comp execSync get-launch-command))

(defn relaunch-browser
  [browser]
  (promesa/do (quit-browser browser)
              (stage-user-data browser)
              (launch-browser browser)))

(def init-path
  (join (toString) "public/js/init.js"))

(defn connect-to-browser
  []
  (promesa/loop []
    (promesa/catch (.connectOverCDP chromium (str "http://localhost:" remote-debugging-port))
                   (fn [_]
                     (promesa/delay 1000)
                     (promesa/recur)))))

(defn get-page
  []
  (promesa/-> (connect-to-browser)
              .contexts
              first
              .newPage))

(def extensions-url
  "chrome://extensions")

(defn enable-extension
  [id]
  (promesa/let [page (get-page)]
    (.goto page extensions-url)
    (.evaluate page #(js/chrome.management.setEnabled % true) id)))

(defn get-manifest-url
  [id]
  (str "chrome-extension://" id "/manifest.json"))

(defn run-in-page
  [url code]
  (promesa/let [page (get-page)]
    (.goto page url)
    (.evaluate page code)))

(defn commit-user-data
  [browser]
  (rmSync (browser-user-data-paths browser) (clj->js {:recursive true}))
  (renameSync app-temp-directory (browser-user-data-paths browser) (clj->js {:recursive true})))

(defn install
  [{:keys [browser id script]}]
  (install-extension-preference-file browser id)
  (promesa/do (relaunch-browser browser)
              (enable-extension id)
              (when script
                (run-in-page (get-manifest-url id) (slurp script)))
              (quit-browser browser)
              (commit-user-data browser)))

(defn handle-message
  [message]
  (let [{:keys [url area-name changes]} (read-string (.toString message))]
    (println url)
    (run! (fn [[k v]]
            (println (str "chrome.storage." area-name ".set({\"" (name k) "\": " (js/JSON.stringify (clj->js (:newValue v))) "});")))
          changes)))

(defn handle-connection
  [socket]
  (.on socket "message" handle-message))

(defstate server
  :start (.on (WebSocketServer. (clj->js {:port port})) "connection" handle-connection)
  :stop (.close server))

(defn inject-listener
  [id]
  (run-in-page (get-manifest-url id) (slurp init-path)))

(defn listen
  [browser]
  (println (str "Listening for changes in extensions for " browser))
  (println (str "Please manually quit " browser " when you're done listening for changes. "
                "Not closing " browser " might expose the remote debugging port which is a potential security risk."))
  (relaunch-browser browser)
  (start)
  (promesa/let [extensions (run-in-page extensions-url #(js/chrome.management.getAll))]
    (run! (comp inject-listener :id) (js->clj extensions :keywordize-keys true))))

(defn main
  [& args]
  (case (first args)
    "install" (install {:browser (second args)
                        :id (nth args 2)
                        :script (if (> (count args) 3)
                                  (nth args 3)
                                  nil)})
    "listen" (listen (second args))))