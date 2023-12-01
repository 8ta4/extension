import appRoot from "app-root-path";
import { WebSocketServer } from "ws";

export const getAppRootPath = () => {
  // https://github.com/inxilpro/node-app-root-path/blob/baf711a6ec61acf50aeb42fb6e5118e899bcbe4b/README.md?plain=1#L24
  return appRoot.toString();
};

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
  // TODO: Handle case where chrome.storage is undefined. For example, the Old Reddit Redirect extension (https://github.com/tom-james-watson/old-reddit-redirect) may cause this issue.
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
