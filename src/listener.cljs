(ns listener
  (:require [core :refer [port]]))

(defn init
  []
  (when js/chrome.storage
    (let [socket (js/WebSocket. (str "ws://localhost:" port))]
      (js/chrome.storage.onChanged.addListener (fn [changes area-name]
                                                 (.send socket (pr-str {:area-name area-name
                                                                        :changes (js->clj changes :keywordize-keys true)
                                                                        :url js/location.href})))))))