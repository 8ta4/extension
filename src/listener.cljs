(ns listener
  (:require [core :refer [port]]))

(defn init
  []
  (js/WebSocket. (str "ws://localhost:" port)))