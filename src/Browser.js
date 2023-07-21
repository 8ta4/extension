import playwright from "playwright";
import { WebSocketServer } from "ws";

export const handleWebSocket = (options) => (handleMessage) => () => {
  const wss = new WebSocketServer(options);

  wss.on("connection", (ws) => {
    ws.on("message", (data) => {
      handleMessage(data)();
    });
  });
};

export const runInBrowserImpl =
  (endpointURL) => (url) => (script) => (scriptArg) => () =>
    new Promise(async (resolve, reject) => {
      try {
        const browser = await playwright.chromium.connectOverCDP(endpointURL);
        const defaultContext = browser.contexts()[0];
        const page = await defaultContext.newPage();
        await page.goto(url);
        const result = await page.evaluate(script, scriptArg);
        await browser.close();
        resolve(result);
      } catch (e) {
        reject(e);
      }
    });

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
