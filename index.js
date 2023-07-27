#!/usr/bin/env node
// The 'spago bundle-app' command in the Purescript build process has
// an issue where 'Dynamic require of "stream" is not supported'.
// Therefore as a workaround, we're using the 'spago build' command.
// Invoking the 'spago build' command generates 'index.js' in './output/Main/'.
// https://github.com/purescript/spago#:~:text=You%20can%20already,main%20with%20Node.
import("./output/Main/index.js").then((m) => m.main());
