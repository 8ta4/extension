# extension

## The Extension's Extension

> What does the `extension` command do?

The `extension` command installs and configures browser extensions.

## Installation

> How do I install this tool?

First off, you need Homebrew. If you don't have it already, you can find the instructions on the [Homebrew website](https://brew.sh/).

Once you've got Homebrew, just enter this command in your terminal:

```sh
brew install 8ta4/extension/extension
```

## Usage

> What's the first argument when I'm installing a Chrome extension?

The first argument is `install`. Let me give you an example. Say you want to install the [Video Speed Controller](https://chrome.google.com/webstore/detail/video-speed-controller/nffaoalbilbmmfgbnbgppjihopabppdk) extension on Chrome. You'd use this command:

```sh
extension install chrome nffaoalbilbmmfgbnbgppjihopabppdk
```

Here, `install` is the action you want to perform, `chrome` is the browser you want to manage extensions for, and `nffaoalbilbmmfgbnbgppjihopabppdk` is the ID of the Video Speed Controller extension.

> How do I find the ID of a Chrome extension?

The ID of a Chrome extension can usually be found in the extension's URL on the Chrome Web Store. It's that long string of alphanumeric characters at the end of the URL.

> What programming language do I use to configure extension settings?

You'll use JavaScript to configure the extension settings.

To set up an extension with specific settings, you can a path to a script that modifies the desired settings of the extension. For instance, if you wish to enable the `Work on audio` option in the Video Speed Controller extension, your command might look like this:

```sh
extension install chrome nffaoalbilbmmfgbnbgppjihopabppdk config.js
```

The `config.js` file should contain JavaScript code that sets the `audioBoolean` to `true`, which corresponds to the `Work on audio` feature.

The JavaScript code in `config.js` would look like this:

```javascript
chrome.storage.sync.set({ audioBoolean: true });
```

These scripts are designed to be idempotent, meaning they can be run multiple times without causing any unintended changes to your system.

> Is it possible to generate the JavaScript code for my configuration file?

Absolutely! You can use the listen mode of the `extension` command to generate JavaScript code based on changes it detects. For instance, if you want to see what changes the `Work on audio` setting makes to the Video Speed Controller extension, you would use this command:

```sh
extension listen chrome
```

In this command, `listen` is the action and `chrome` is the browser you're targeting.

When the `extension` command is in listen mode, it generates JavaScript code based on changes it detects. This code can be used directly or as a reference to modify your `config.js` file.

> Does this tool have any restrictions on the configuration file's name?

No, the `extension` tool doesn't add any extra rules for the configuration file name beyond what your operating system already requires.

> If the extension is already installed, will this tool reinstall it?

No, it won't reinstall an extension that's already there. If you provide a configuration script, it will only apply the script to the existing extension.

> Can I use this tool with Edge?

Yes, you can use the `extension` command with Microsoft Edge. For example, let's say you want to enjoy a dark mode on any website with the [Dark Reader](https://microsoftedge.microsoft.com/addons/detail/dark-reader/ifoakfbpdcdoeenechcleahebpibofpc) extension to match your dim-witted nature. I'm just throwing some shade to help you see better. To install it on Edge, your command would look like this:

```sh
extension install edge ifoakfbpdcdoeenechcleahebpibofpc
```

Here, `ifoakfbpdcdoeenechcleahebpibofpc` is the ID for the Dark Reader extension on the Microsoft Edge Add-ons website.

> Are the IDs for Edge extensions the same as their Chrome counterparts?

Most likely not. Even for the same extension, the Edge Add-ons store and the Chrome Web Store typically use different IDs.

> Can I use the extension command with Arc?

Yes, you can use the `extension` command with the Arc browser, and it works similarly to Chrome.

> Are the IDs for Arc extensions the same as their Chrome counterparts?

Yes. The extension IDs for Arc are actually the same as their Chrome counterparts.

> Can I use extension with other browsers that aren't Chromium-based?

No, currently, the `extension` command only supports Chrome, Edge, and Arc. It doesn't support other Chromium-based browsers or non-Chromium browsers like Firefox or Safari.

> Can I use `extension` on all operating systems?

Nope. Currently, `extension` only supports macOS.
