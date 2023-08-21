# nix-daml-sdk

Nix package and shell for the [daml-sdk](https://docs.daml.com/getting-started/installation.html).

Use `nix-shell` to enter the shell. Once inside, you can run `daml` commands.

The `daml studio` command invokes vscode and tries to ensure that the daml extension has been installed. The provided nix-shell installs vscode and a pinned version of the daml extension. Other extensions can be added to shell.nix.

## Nix Binary Cache

1. [Install Nix](https://nixos.org/nix/). If you already have Nix installed, make sure you have version 2.0 or higher. To check your current version, run nix-env --version.

2. Set up nix caches
    1. If you are running NixOS, add this to `/etc/nixos/configuration.nix`:
        ```nix
        nix.binaryCaches = [ "s3://obsidian-open-source" ];
        nix.binaryCachePublicKeys = [ "obsidian-open-source:KP1UbL7OIibSjFo9/2tiHCYLm/gJMfy8Tim7+7P4o0I=" ];
        ```
        and rebuild your NixOS configuration (e.g. `sudo nixos-rebuild switch`).
    2. If you are using another operating system or Linux distribution, ensure that these lines are present in your Nix configuration file (`/etc/nix/nix.conf` on most systems; [see full list](https://nixos.org/nix/manual/#sec-conf-file)):
        ```nix
        binary-caches = https://cache.nixos.org s3://obsidian-open-source
        binary-cache-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= obsidian-open-source:KP1UbL7OIibSjFo9/2tiHCYLm/gJMfy8Tim7+7P4o0I=
        binary-caches-parallel-connections = 40
        ```
