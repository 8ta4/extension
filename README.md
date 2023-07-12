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

Just specify the name of the Chromium-based browser, the ID of the extension you want to install, and optionally, the path to a configuration script, like this:

```sh
extension browser extensionId path/to/configScript.js
```

- `browser` is the name of the Chromium-based browser you want to manage extensions for.
- `extensionId` is the ID of the extension you want to install. You can find this ID on the Chrome Web Store page for the extension.
- `configFilePath` (optional) is the path to a JavaScript file that contains the configuration script for the extension. If you skip this argument, `extension` will just install the extension without configuring it.

`extension` operates using UI automation. This means that unexpected events such as user interactions or system notifications could potentially disrupt its operation.

> What is a configuration script?

A configuration script is a JavaScript file used to set up an extension. These scripts are designed to be idempotent, meaning they can be run multiple times without causing any unintended changes to your system.

> What happens if the extension is already installed?

If the extension is already installed, `extension` will just apply the configuration script.

## Limitations

> Can I use `extension` on operating systems other than macOS?

No, `extension` only supports macOS.

> Does `extension` require any specific permissions to work?

Yes, `extension` requires access to `System Settings > Privacy & Security > Accessibility`. But the specific permissions it needs could change as macOS updates.

> Is `extension` compatible with all browsers?

No. At the moment, `extension` supports Chrome and Edge. While it could theoretically support other Chromium-based browsers, only Chrome and Edge have been tested. `extension` doesn't currently support non-Chromium browsers like Firefox or Safari.
