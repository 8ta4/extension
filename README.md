# extension

## Introduction

> What does the `extension` command do?

It extends your life span by 10 seconds with its automatic installation and configuration of your browser extensions, unless you have OCD, in which case you lose 10 years.

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

Well, let me give you an example. Say you want to install the Video Speed Controller extension on Chrome. You'd use this command:

```sh
extension chrome nffaoalbilbmmfgbnbgppjihopabppdk
```

Here, `chrome` is the browser you want to manage extensions for and `nffaoalbilbmmfgbnbgppjihopabppdk` is the ID of the Video Speed Controller extension.

The `extension` command works by using UI automation. Just a heads up, try not to mess with it while it's running, like clicking around or having system notifications pop up.

> How can I configure the `extension` command to modify settings of the Video Speed Controller extension?

You can do that by providing a path to a script that modifies the desired settings of the extension. For instance, if you wish to enable the `Work on audio` option in the Video Speed Controller extension, your command might look like this:

```sh
extension chrome nffaoalbilbmmfgbnbgppjihopabppdk configScript.js
```

The `configScript.js` file should contain JavaScript code that sets the `audioBoolean` to `true`, which corresponds to the `Work on audio` feature.

The JavaScript code in `configScript.js` would look like this:

```javascript
// configScript.js
chrome.storage.sync.set({audioBoolean: true});
```

These scripts are designed to be idempotent, meaning they can be run multiple times without causing any unintended changes to your system.

> What happens if the extension is already installed?

If the extension is already installed, `extension` will just apply the configuration script.

## Limitations

> Can I use `extension` on all operating systems?

No. Currently, `extension` only supports macOS.

> Does `extension` require any specific permissions to work?

Yes. `extension` requires access to `System Settings > Privacy & Security > Accessibility`. But the specific permissions it needs could change as macOS updates.

> Is `extension` compatible with all browsers?

No. Currently, `extension` supports Chrome and Edge. While it could theoretically support other Chromium-based browsers, only Chrome and Edge have been tested. `extension` doesn't currently support non-Chromium browsers like Firefox or Safari.
