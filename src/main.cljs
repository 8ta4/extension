(ns main)

(def external-extension-paths
  {"arc" "/Library/Application Support/Arc/User Data/External Extensions"
; https://developer.chrome.com/docs/extensions/mv3/external_extensions/#preference-mac
   "chrome" "/Library/Application Support/Google/Chrome/External Extensions"
; https://learn.microsoft.com/en-us/microsoft-edge/extensions-chromium/developer-guide/alternate-distribution-options#using-a-preferences-json-file-macos-and-linux
   "edge" "/Library/Application Support/Microsoft Edge/External Extensions"})

(defn main
  [])