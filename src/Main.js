import playwright from "playwright";

export const getAllImpl = async () => {
  return await chrome.management.getAll();
};

export const runInBrowserImpl = (endpointURL) => (url) => (script) => () =>
  new Promise(async (resolve, reject) => {
    try {
      const browser = await playwright.chromium.connectOverCDP(endpointURL);
      const defaultContext = browser.contexts()[0];
      const page = defaultContext.pages()[0];
      await page.goto(url);
      const all = await page.evaluate(script);
      resolve(all);
    } catch (e) {
      reject(e);
    }
  });
