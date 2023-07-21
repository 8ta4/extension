import playwright from "playwright";
import { WebSocketServer } from "ws";

export const handleWebSocket = () => {
  // https://github.com/websockets/ws#simple-server
  const wss = new WebSocketServer({ port: 8080 });

  wss.on("connection", function connection(ws) {
    ws.on("error", console.error);

    ws.on("message", function message(data) {
      console.log("received: %s", data);
    });

    ws.send("something");
  });
};

export const runInBrowserImpl = (endpointURL) => (url) => (script) => () =>
  new Promise(async (resolve, reject) => {
    try {
      const browser = await playwright.chromium.connectOverCDP(endpointURL);
      const defaultContext = browser.contexts()[0];
      const page = await defaultContext.newPage();
      await page.goto(url);
      const result = await page.evaluate(script);
      resolve(result);
    } catch (e) {
      reject(e);
    }
  });

export const getAll = async () => {
  return await chrome.management.getAll();
};

export const addListener = () => {
  // https://developer.mozilla.org/en-US/docs/Web/API/WebSocket#examples
  // Create WebSocket connection.
  const socket = new WebSocket("ws://localhost:8080");

  // Connection opened
  socket.addEventListener("open", (event) => {
    socket.send("Hello Server!");
  });

  // Listen for messages
  socket.addEventListener("message", (event) => {
    console.log("Message from server ", event.data);
  });
  chrome.storage.onChanged.addListener((changes, area) => {
    socket.send(JSON.stringify([changes, area]));
  });
};
