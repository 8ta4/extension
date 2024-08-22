# extension

## Setup

> How do I set up this tool's dev environment?

1. Follow the [setup steps](https://github.com/8ta4/extension/blob/4a400d9f96edaeec3f07138689b7c902dc64a412/README.md#installation) in the README.md.

1. Install [devenv](https://github.com/cachix/devenv/blob/5340ef87de79a5e23414e6707cc90009e97745d5/docs/getting-started.md#installation).

1. Install [direnv](https://github.com/cachix/devenv/blob/5340ef87de79a5e23414e6707cc90009e97745d5/docs/automatic-shell-activation.md#installing-direnv).

1. Run the following commands:

   ```sh
   git clone git@github.com:8ta4/extension.git
   cd extension
   direnv allow
   ```

The `devenv.nix` file has got all the scripts you need.
