# extension

## Introduction

> What does the `extension` command do?

It extends your life span by 10 seconds with its automatic installation and configuration of your browser extensions, unless you have OCD, in which case you lose 10 years.

## Installation

> How do I install this tool?

First off, you need Homebrew. If it's not already installed, you can find the instructions on the [Homebrew website](https://brew.sh/).

Once you've got Homebrew, installing `extension` is as simple as entering these commands in your terminal:

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

If the extension is already installed, `extension` will just apply the configuration script.

## Command Line Arguments

> Can you explain these command line arguments?

- `browser` is the name of the Chromium-based browser you want to manage extensions for.
- `extensionId` is the ID of the extension you want to install. You can find this ID on the Chrome Web Store page for the extension.
- `configFilePath` (optional) is the path to a JavaScript file that contains the configuration script for the extension. If you skip this argument, `extension` will just install the extension without configuring it.

## Configuration Scripts

> What's a configuration script?

Configuration scripts are JavaScript files that are used to configure an extension. They're designed to be idempotent, which means they can run multiple times without causing any unwanted system changes.

## Limitations

> Any limitations I should know about?

At the moment, `extension` is only supported on macOS. It uses UI automation, so any unexpected events like user interactions or system notifications could potentially interfere with its operation.

Also, `extension` requires certain permissions to work. When it was created, it needed access to `System Settings > Privacy & Security > Accessibility`. But keep in mind that the specific permissions required may change as macOS evolves.

In theory, `extension` supports any Chromium-based browser, but only Chrome has been tested. Currently, `extension` doesn't support browsers like Firefox or Safari.
