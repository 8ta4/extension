import playwright from "playwright";

export const runInBrowserImpl = (endpointURL) => () =>
  new Promise(async (resolve, reject) => {
    try {
      const browser = await playwright.chromium.connectOverCDP(endpointURL);
      const defaultContext = browser.contexts()[0];
      const page = defaultContext.pages()[0];
      console.log("Running in browser");
      resolve();
    } catch (e) {
      reject(e);
    }
  });
