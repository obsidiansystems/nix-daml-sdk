# nix-daml-sdk

Nix package and shell for the [daml-sdk](https://docs.daml.com/getting-started/installation.html).

Use `nix-shell` to enter the shell. Once inside, you can run [`daml` commands](https://docs.daml.com/tools/assistant.html).

The `daml studio` command invokes vscode and tries to ensure that the daml extension has been installed. The provided nix-shell installs vscode and a pinned version of the daml extension. Other extensions can be added to shell.nix.

## Project Integration

nix-daml-sdk is designed can be integrated into an existing nix-based project or added to a daml project that doesn't currently use nix.

### Creating a shell for your project

You can import nix-daml-sdk into your shell.nix file, and include the daml sdk, vscode, and canton in your shell's `buildInputs`. For example:

```nix
{}:
let
  pkgs = import ./nixpkgs {};
  nix-daml-sdk = import ./nix/nix-daml-sdk {};
in
  pkgs.mkShell {
    name = "daml-shell";
    buildInputs = [
      pkgs.cabal-install
      pkgs.ghcid
      nix-daml-sdk.sdk
      nix-daml-sdk.vscode
      nix-daml-sdk.canton
    ];
  }
```

### Building your project

To build your daml nix project, you can import nix-daml-sdk and use the sdk, jdk, and canton fields that it provides as buildInputs in your own nix derivation. For example, the code below will build a daml project and produce a `.dar` file using nix.

```nix
{ jdkVersion ? "jdk17"
, sdkVersion ? "2.7.1"
, pkgs ? import ./nixpkgs {}
}:
let
  damlSdk = import ./nix-daml-sdk { inherit jdkVersion sdkVersion; };
in pkgs.stdenvNoCC.mkDerivation {
    name = "My Daml Project";
    src = pkgs.lib.cleanSource ./.;
    buildInputs = [ damlSdk.jdk damlSdk.sdk ];
    buildPhase = ''
      mkdir dist
      daml build -o dist.dar
    '';
    installPhase = ''
      mkdir $out
      cp dist.dar $out/
    '';
  }
```

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
