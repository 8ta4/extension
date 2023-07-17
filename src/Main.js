import playwright from "playwright";

export const runInBrowserImpl = (endpointURL) => () =>
  new Promise(async () => {
    const browser = await playwright.chromium.connectOverCDP(endpointURL);
    const defaultContext = browser.contexts()[0];
    const page = defaultContext.pages()[0];
  });
