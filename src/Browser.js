import playwright from "playwright";
import { WebSocketServer } from "ws";

export const handleWebSocket = (options) => (handleMessage) => () => {
  // https://github.com/websockets/ws#simple-server
  const wss = new WebSocketServer(options);

  wss.on("connection", function connection(ws) {
    ws.on("error", console.error);

    ws.on("message", function message(data) {
      handleMessage(data)();
      console.log("received: %s", data);
    });

    ws.send("something");
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
  // https://developer.mozilla.org/en-US/docs/Web/API/WebSocket#examples
  // Create WebSocket connection.
  const socket = new WebSocket(scriptArg.webSocket);

  // Connection opened
  socket.addEventListener("open", (event) => {
    socket.send("Hello Server!");
  });

  // Listen for messages
  socket.addEventListener("message", (event) => {
    console.log("Message from server ", event.data);
  });
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
