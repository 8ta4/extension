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

export const getAllImpl = async () => {
  return await chrome.management.getAll();
};

export const addListenerImpl = () => {
  return chrome.storage.onChanged.addListener(console.log);
};

export const runInBrowserImpl = (endpointURL) => (url) => (script) => () =>
  new Promise(async (resolve, reject) => {
    try {
      const browser = await playwright.chromium.connectOverCDP(endpointURL);
      const defaultContext = browser.contexts()[0];
      const page = defaultContext.pages()[0];
      await page.goto(url);
      const result = await page.evaluate(script);
      resolve(result);
    } catch (e) {
      reject(e);
    }
  });
