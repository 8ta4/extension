(ns listener)

(def port
  8080)

(defn init
  []
  (js/WebSocket. (str "ws://localhost:" port)))