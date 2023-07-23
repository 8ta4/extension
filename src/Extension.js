import { WebSocketServer } from "ws";

export const enableExtension = async (id) => {
  return await chrome.management.setEnabled(id, true);
};

export const toScript = (value) => value;

export const handleWebSocket = (options) => (handleMessage) => () => {
  const wss = new WebSocketServer(options);

  wss.on("connection", (ws) => {
    ws.on("message", (data) => {
      handleMessage(data)();
    });
  });
};

export const getAll = async () => {
  return await chrome.management.getAll();
};

export const addListener = (scriptArg) => {
  // Create WebSocket connection.
  const socket = new WebSocket(scriptArg.webSocket);

  // https://developer.chrome.com/docs/extensions/reference/storage/#event-onChanged#method-onChanged-callback
  chrome.storage.onChanged.addListener((changes, areaName) => {
    socket.send(
      JSON.stringify({
        url: scriptArg.extension,
        changes: changes,
        areaName: areaName,
      }),
    );
  });
};
