import playwright from "playwright";

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

export const close = (browser) => async () => {
  await browser.close();
};
