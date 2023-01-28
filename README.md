# nix-daml-sdk

Nix package and shell for the [daml-sdk](https://docs.daml.com/getting-started/installation.html).

Use `nix-shell` to enter the shell. Once inside, you can run `daml` commands.

The `daml studio` command invokes vscode and tries to ensure that the daml extension has been installed. The provided nix-shell installs vscode and a pinned version of the daml extension. Other extensions can be added to shell.nix.
