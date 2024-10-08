{ pkgs, ... }:

{
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = [
    pkgs.git
    pkgs.gitleaks
    # pkgs.spago is not used due to an error encountered during GitHub Actions.
    # The error was: "Git output: fatal: destination path '.' already exists and is not an empty directory."
    # Using npm to install spago avoids this issue.
  ];

  # https://devenv.sh/scripts/
  scripts.hello.exec = "echo hello from $GREET";
  scripts.build.exec = "spago build";
  scripts.run.exec = ''
    command="$@"
    spago run -wb "$command"
  '';

  enterShell = ''
    hello
    git --version
    export PATH="$DEVENV_ROOT/node_modules/.bin:$PATH"
    npm install
    # TODO: Incorporate dependency installation via enterShell
  '';

  # https://devenv.sh/languages/
  # languages.nix.enable = true;
  languages.purescript.enable = true;

  # https://devenv.sh/pre-commit-hooks/
  # pre-commit.hooks.shellcheck.enable = true;
  pre-commit.hooks = {
    gitleaks = {
      enable = true;
      # https://github.com/gitleaks/gitleaks/blob/8de8938ad425d11edb0986c38890116525a36035/.pre-commit-hooks.yaml#L4C10-L4C54
      entry = "${pkgs.gitleaks}/bin/gitleaks protect --verbose --redact --staged";
    };
    nixpkgs-fmt.enable = true;
    prettier.enable = true;
    purs-tidy.enable = true;
    # https://github.com/cachix/pre-commit-hooks.nix/issues/31#issuecomment-744657870
    trailing-whitespace = {
      enable = true;
      # https://github.com/pre-commit/pre-commit-hooks/blob/4b863f127224b6d92a88ada20d28a4878bf4535d/.pre-commit-hooks.yaml#L201-L207
      entry = "${pkgs.python3Packages.pre-commit-hooks}/bin/trailing-whitespace-fixer";
      types = [ "text" ];
    };
  };

  # https://devenv.sh/processes/
  # processes.ping.exec = "ping example.com";

  # See full reference at https://devenv.sh/reference/options/
}
