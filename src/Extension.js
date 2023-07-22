import playwright from "playwright";
import { WebSocketServer } from "ws";

export const enableExtension = async (id) => {
  return await chrome.management.setEnabled(id, true);
};

export const handleWebSocket = (options) => (handleMessage) => () => {
  const wss = new WebSocketServer(options);

  wss.on("connection", (ws) => {
    ws.on("message", (data) => {
      handleMessage(data)();
    });
  });
};

export const connectOverCDPImpl = (endpointURL) => async () => {
  return await playwright.chromium.connectOverCDP(endpointURL);
};

export const newPage = (browser) => (url) => async () => {
  const defaultContext = browser.contexts()[0];
  const page = await defaultContext.newPage();
  await page.goto(url);
  return page;
};

export const evaluateImpl = (page) => (script) => (scriptArg) => async () => {
  return await page.evaluate(script, scriptArg);
};

export const closePage = (page) => async () => {
  await page.close();
};

export const closeBrowser = (browser) => async () => {
  await browser.close();
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
