# extension

## Introduction

> What does the `extension` command do?

The `extension` command installs and configures browser extensions. It extends your lifespan by saving 10 seconds, unless you have OCD, in which case you lose 10 years.

## Installation

> How do I install this tool?

First off, you need Homebrew. If you don't have it already, you can find the instructions on the [Homebrew website](https://brew.sh/).

Once you've got Homebrew, just enter these commands in your terminal:

```sh
brew tap 8ta4/extension
brew install extension
```

## Usage

> How do I use this `extension` command?

Well, let me give you an example. Say you want to install the [Video Speed Controller](https://chrome.google.com/webstore/detail/video-speed-controller/nffaoalbilbmmfgbnbgppjihopabppdk) extension on Chrome. You'd use this command:

```sh
extension install chrome nffaoalbilbmmfgbnbgppjihopabppdk
```

Here, `install` is the action you want to perform, `chrome` is the browser you want to manage extensions for, and `nffaoalbilbmmfgbnbgppjihopabppdk` is the ID of the Video Speed Controller extension.

Just a heads up, try not to click around or have system notifications pop up while it's running.

> Why should I avoid interfering with `extension` while it's running?

The `extension` command works through UI automation. Any user interactions or system notifications could disrupt its operation, leading to unexpected results or errors. This UI automation process is also why `extension` might ask for permissions.

> What should I do if `extension` prompts for permissions?

Just follow the prompts to grant access.

> What if I don't get any prompts when running `extension`?

You can manually grant `extension` the required permissions by going to `System Settings > Privacy & Security > Accessibility`.  Just keep in mind that the specific permissions `extension` needs could change as macOS updates.

> How can I find the ID of an extension?

The ID of an extension can usually be found in the extension's URL on the Chrome Web Store. It's that long string of alphanumeric characters at the end of the URL.

> How can I configure `extension` to modify settings of an extension?

You can do that by providing a path to a script that modifies the desired settings of the extension. For instance, if you wish to enable the `Work on audio` option in the Video Speed Controller extension, your command might look like this:

```sh
extension install chrome nffaoalbilbmmfgbnbgppjihopabppdk configScript.js
```

The `configScript.js` file should contain JavaScript code that sets the `audioBoolean` to `true`, which corresponds to the `Work on audio` feature.

The JavaScript code in `configScript.js` would look like this:

```javascript
chrome.storage.sync.set({audioBoolean: true});
```

These scripts are designed to be idempotent, meaning they can be run multiple times without causing any unintended changes to your system.

> How can I figure out what JavaScript code to write for my `configScript.js` file?

You can use the listen mode of the `extension` command to generate JavaScript code based on changes it detects. For instance, if you want to see what changes the `Work on audio` setting makes to the Video Speed Controller extension, you would use this command:

```sh
extension listen chrome nffaoalbilbmmfgbnbgppjihopabppdk
```

In this command, `listen` is the action, `chrome` is the browser you're targeting, and `nffaoalbilbmmfgbnbgppjihopabppdk` is the ID of the Video Speed Controller extension.

When the `extension` command is in listen mode, it generates JavaScript code based on changes it detects. This code can be used directly or as a reference to modify your `configScript.js` file.

> What happens if the extension is already installed?

If the extension is already installed, `extension` will just apply the configuration script.

> How can I use the `extension` command with Edge?

All you have to do is replace `chrome` with `edge` in the command line argument. For example, if you want to install the Video Speed Controller extension on Edge, your command would look like this:

```sh
extension edge nffaoalbilbmmfgbnbgppjihopabppdk
```

> Can I use `extension` with browsers other than Chrome and Edge?

Unfortunately, at the moment, `extension` only supports Chrome and Edge. It doesn't support other Chromium-based browsers or non-Chromium browsers like Firefox or Safari.

> Can I use `extension` on all operating systems?

Nope. Currently, `extension` only supports macOS.
