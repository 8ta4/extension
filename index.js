#!/usr/bin/env node
// https://github.com/purescript/spago#:~:text=You%20can%20already,main%20with%20Node.
import("./output/Main/index.js").then((m) => m.main());
