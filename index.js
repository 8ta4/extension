#!/usr/bin/env node
// The 'spago bundle-app' command in the Purescript build process has
// an issue where 'Dynamic require of "stream" is not supported'.
// Therefore as a workaround, we're using the 'spago build' command.
// Invoking the 'spago build' command generates 'index.js' in './output/Main/'.
// https://github.com/purescript/spago/blob/6c2deb244ca8b8ee81016c4be0fcdd7027e77945/README.md?plain=1#L88-L96
import("./output/Main/index.js").then((m) => m.main());
