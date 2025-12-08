(ns main
  (:require
   [app-root-path :refer [toString]]
   [child_process :refer [execSync]]
   [cljs-node-io.core :refer [make-parents slurp]]
   [fs :refer [cpSync mkdtempSync]]
   [os :refer [homedir tmpdir]]
   [path :refer [join]]
   [playwright :refer [chromium]]
   [promesa.core :as promesa]))

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
  [browser extension-id]
  (join (browser-external-extension-paths browser) (str extension-id ".json")))

(defn install-extension-preference-file
  [browser extension-id]
  (js/console.log (str "Installing " extension-id " for " browser))
  (make-parents (get-preference-target-path browser extension-id))
  (cpSync (get-preference-source-path browser) (get-preference-target-path browser extension-id)))

(def browser-app-names
  {"arc" "Arc"
   "chrome" "Google Chrome"
   "edge" "Microsoft Edge"})

(defn get-quit-command
  [browser]
  (str "osascript -e 'quit app \"" (browser-app-names browser) "\"'"))

(def quit-browser
  (comp execSync get-quit-command))

(defn browser-running?
  [browser]
  (try (execSync (str "pgrep -x '" (browser-app-names browser) "'"))
       true
       (catch js/Error _ false)))

(defn wait-for-browser-exit
  [browser]
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

(defn clone-user-data
  [browser]
  (cpSync (browser-user-data-paths browser) app-temp-directory (clj->js {:recursive true})))

(def remote-debugging-port
  "9222")

(defn get-launch-command
  [browser]
  (str "open -a '" (browser-app-names browser) "' --args --remote-debugging-port=" remote-debugging-port " --user-data-dir=" app-temp-directory))

(def launch-browser
  (comp execSync get-launch-command))

(defn get-manifest-url
  [id]
  (str "chrome-extension://" id "/manifest.json"))

(def init-path
  (join (toString) "public/js/init.js"))

(defn enable-extension
  [id]
  (js/chrome.management.setEnabled id true))

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

(defn install-extension-in-browser
  [id script]
  (promesa/let [page (get-page)]
    (.goto page extensions-url)
    (.evaluate page enable-extension id)
    (.evaluate page script)))

(defn relaunch-browser
  [browser]
  (quit-browser browser)
  (promesa/do (wait-for-browser-exit browser)
              (clone-user-data browser)
              (launch-browser browser)))

(defn install
  [{:keys [browser id script]}]
  (install-extension-preference-file browser id)
  (promesa/do (relaunch-browser browser)
              (install-extension-in-browser id script)
              (quit-browser browser)))

(defn get-extensions
  []
  (promesa/let [page (get-page)]
    (.goto page extensions-url)
    (.evaluate page #(js/chrome.management.getAll))))

(defn listen-extension
  [id]
  (promesa/let [page (get-page)]
    (.addInitScript page (clj->js {:path init-path}))
    (.goto page (get-manifest-url id))))

(defn listen
  [browser]
  (relaunch-browser browser)
  (promesa/let [extensions (get-extensions)]
    (run! (comp listen-extension :id) (js->clj extensions :keywordize-keys true))))

(defn main
  [& args]
  (case (first args)
    "install" (install {:browser (second args)
                        :id (nth args 2)
                        :script (if (> (count args) 3)
                                  (slurp (nth args 3))
                                  "console.log('No script provided')")})
    "listen" (listen (second args))))