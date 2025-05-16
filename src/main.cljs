(ns main
  (:require ["child_process" :as child-process]
            [cljs-node-io.core :as io]
            [fs]
            [os]
            [path]
            [app-root-path]))

(def browser-external-extension-paths
  {"arc" (path/join (os/homedir) "Library/Application Support/Arc/User Data/External Extensions")
; https://developer.chrome.com/docs/extensions/mv3/external_extensions/#preference-mac
   "chrome" (path/join (os/homedir) "Library/Application Support/Google/Chrome/External Extensions")
; https://learn.microsoft.com/en-us/microsoft-edge/extensions-chromium/developer-guide/alternate-distribution-options#using-a-preferences-json-file-macos-and-linux
   "edge" (path/join (os/homedir) "Library/Application Support/Microsoft Edge/External Extensions")})

(defn get-preference-source-path
  [browser]
  (path/join (app-root-path/toString) "preferences" (str browser ".json")))

(defn get-preference-target-path
  [browser extension-id]
  (path/join (browser-external-extension-paths browser) (str extension-id ".json")))

(defn install-extension-preference-file
  [browser extension-id]
  (js/console.log (str "Installing " extension-id " for " browser))
  (io/make-parents (get-preference-target-path browser extension-id))
  (io/copy (get-preference-source-path browser) (get-preference-target-path browser extension-id)))

(def browser-app-names
  {"arc" "Arc"
   "chrome" "Google Chrome"
   "edge" "Microsoft Edge"})

(defn get-quit-command
  [browser]
  (str "osascript -e 'quit app \"" (browser-app-names browser) "\"'"))

(def quit-browser
  (comp child-process/execSync get-quit-command))

(def temp-directory
  (os/tmpdir))

(def app-temp-directory
  (fs/mkdtempSync (path/join temp-directory "extension-")))

(defn copy
  [source target]
  (fs/cpSync source target (clj->js {:recursive true})))

(def browser-user-data-paths
  {"arc" (path/join (os/homedir) "Library/Application Support/Arc/User Data")
; https://chromium.googlesource.com/chromium/src/+/main/docs/user_data_dir.md#:~:text=%5BChrome%5D%20~/Library/Application%20Support/Google/Chrome
   "chrome" (path/join (os/homedir) "Library/Application Support/Google/Chrome")
   "edge" (path/join (os/homedir) "Library/Application Support/Microsoft Edge")})

(defn clone-user-data
  [browser]
  (copy (browser-user-data-paths browser) app-temp-directory))

(def remote-debugging-port
  "9222")

(defn get-launch-command
  [browser]
  (str "open -a '" (browser-app-names browser) "' --args --remote-debugging-port=" remote-debugging-port))

(def launch-browser
  (comp child-process/execSync get-launch-command))

(defn main
  [& args]
  (case (first args)
    "install" (install-extension-preference-file (second args) (nth args 2))))