import { exec } from "child_process";
import playwright from "playwright";

export const runInBrowserImpl = (endpointURL) => (command) => () =>
  new Promise(async () => {
    await exec(command);
    const browser = await playwright.chromium.connectOverCDP(endpointURL);
    const defaultContext = browser.contexts()[0];
    const page = defaultContext.pages()[0];
  });
