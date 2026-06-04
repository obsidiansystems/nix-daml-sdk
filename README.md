<div align="center">

# nix-daml-sdk

### The Daml toolchain, made reproducible.

`daml` · `canton` · `dpm` · `vscode` - pinned and cached, one `nix-shell` away.

![Built with Daml](https://img.shields.io/badge/Daml-1D345D) [![Built with Nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://nixos.org) [![Obsidian](https://img.shields.io/badge/Obsidian-Systems-white)](https://obsidian.systems) [![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](./LICENSE)

</div>

```console
$ nix-shell                  # pull the pinned toolchain (prebuilt, from the cache)

[nix-shell]$ daml version    # daml, canton, and dpm are now on your PATH
SDK 3.4.11
```

Reproducible [Nix](https://nixos.org/) packaging of the [Daml
SDK](https://docs.daml.com): the SDK toolchain, a matching
[Canton](https://canton.network/) runtime, the Daml Package Manager (DPM), and a
ready-to-go VS Code. `nix-shell` drops you into a shell with `daml`, `canton`,
and `dpm` on your `PATH`, plus an editor with the pinned Daml extension. The same
derivations double as `buildInputs`, so you can compile your Daml project — and
produce `.dar` files — hermetically and reproducibly in CI.

## Why nix-daml-sdk?

The upstream install path (`curl … | sh` from `get.daml.com`, then `daml
install`) mutates a global `~/.daml`, isn't pinned, and is awkward to reproduce
across a team or in CI. nix-daml-sdk trades that for a Nix-native workflow:

- **Reproducible & pinned.** The SDK, Canton, DPM, JDK, and the VS Code Daml
  extension are all pinned by hash, so every machine and every CI run gets
  identical tools: no global mutable state, no "works on my machine."
- **The whole stack, together.** One shell gives you the SDK, a Canton runtime
  that matches it, DPM, the right JDK, and an editor with the Daml extension
  already wired up.
- **Any version with one flag.** Switch SDK versions with `--argstr
  sdkVersion`; each supported release is a small JSON pin you can add yourself.
- **CI-friendly.** Build `.dar`s inside Nix's sandbox with no network, no
  global state, and byte-for-byte repeatable.
- **Cached.** Obsidian publishes a [binary cache](#nix-binary-cache), so you
  download prebuilt artifacts instead of compiling them.
- **Composable.** Drop it into an existing Nix project, or use it to add Nix to
  a Daml project that doesn't have it yet.

## What you get

Importing this repo yields an attribute set of derivations:

- **`sdk`**: the `daml` assistant and SDK toolchain (auto-install is disabled
  and `daml` is wrapped with a JDK on its `PATH`).
- **`canton`**: a [Canton](https://canton.network/) runtime. Open-source by
  default. Set `cantonEnterprise = true` for the enterprise build (which you
  must supply yourself: see below). Sets `CANTON_HOME` automatically.
- **`dpm`**: the Daml Package Manager, Digital Asset's drop-in replacement for
  the now-deprecated Daml Assistant.
- **`vscode`**: VS Code preloaded with the Daml extension pinned to your SDK
  version. `daml studio` launches it.
- **`jdk`**: the JDK the toolchain runs on (selectable via `jdkVersion`).
- **`scribe`**: optional (`enableScribe = true`). Off by default and requires
  you to supply the distribution.

## Quick start

```sh
nix-shell
```

Inside the shell you can run any [`daml` command](https://docs.daml.com/tools/assistant.html)
(`daml build`, `daml start`, …), use `canton` and `dpm`, and open the bundled
editor with `daml studio`.

Pick a specific SDK version and/or JDK:

```sh
nix-shell --argstr sdkVersion 2.8.0 --argstr jdkVersion jdk17
```

Other arguments accepted by `shell.nix` / `default.nix`: `cantonEnterprise`
(use the enterprise Canton build), `enableScribe`, `vimMode` (adds the Vim
extension to VS Code), and `extraPackages` (a function `pkgs: [ … ]` for adding
more tools to the shell).

### Supported versions

Each supported release is pinned by a file in [`versions/`](./versions). For example:

```
2.5.5  2.6.4  2.6.5  2.7.1  2.8.0
3.3.0-snapshot.*  3.4.10  3.4.11
```

To add a release, add a `versions/<version>.json` alongside the others with the
relevant hashes.

## Project integration

nix-daml-sdk can be added to an existing Nix-based project, or used to bring
Nix to a Daml project that doesn't currently use it. Vendor this repo however
you pin Nix dependencies — e.g. [niv](https://github.com/nmattia/niv),
[nix-thunk](https://github.com/obsidiansystems/nix-thunk), a flake input, or a
plain `fetchTarball`:

```nix
import (builtins.fetchTarball {
  url = "https://github.com/obsidiansystems/nix-daml-sdk/archive/<rev>.tar.gz";
  # sha256 = "…";   # fill in the hash Nix reports
}) { sdkVersion = "3.4.11"; }
```

### A dev shell for your project

Pull the SDK, Canton, DPM, and editor into your own `shell.nix`, alongside
whatever else your project needs:

```nix
{}:
let
  pkgs = import ./nixpkgs {};
  nix-daml-sdk = import ./nix-daml-sdk { sdkVersion = "3.4.11"; };
in
  pkgs.mkShell {
    name = "daml-shell";
    buildInputs = [
      nix-daml-sdk.sdk      # the `daml` assistant + SDK
      nix-daml-sdk.canton   # Canton runtime (sets CANTON_HOME)
      nix-daml-sdk.dpm      # Daml Package Manager
      nix-daml-sdk.vscode   # VS Code with the pinned Daml extension

      pkgs.cabal-install    # add anything else your project needs
      pkgs.ghcid
    ];
  }
```

`nix-shell` now gives everyone on the team the same `daml`, `canton`, and
`dpm`, and `daml studio` opens the bundled VS Code. To add more editor
extensions, edit the `vscode` derivation in this repo (see `default.nix`).

### Building your project

Use the `sdk` and `jdk` derivations as `buildInputs` to compile a `.dar`
reproducibly. Because the build runs in Nix's sandbox, it's hermetic — no
network access, no `~/.daml`:

```nix
{ sdkVersion ? "3.4.11"
, jdkVersion ? "jdk17"
, pkgs ? import ./nixpkgs {}
}:
let
  nix-daml-sdk = import ./nix-daml-sdk { inherit sdkVersion jdkVersion; };
in pkgs.stdenvNoCC.mkDerivation {
  name = "my-daml-project";
  src = pkgs.lib.cleanSource ./.;
  buildInputs = [ nix-daml-sdk.jdk nix-daml-sdk.sdk ];
  buildPhase = "daml build -o my-project.dar";
  installPhase = ''
    mkdir -p $out
    cp my-project.dar $out/
  '';
}
```

`nix-build` produces the artifact at `result/my-project.dar`.

### Enterprise Canton

Canton Enterprise lives behind Digital Asset's Artifactory, so it can't be
fetched automatically. With `cantonEnterprise = true`, Nix will ask you to add
the matching tarball to your store (via `nix-store --add-fixed`); see
`canton.nix` for the exact filename and hash it expects.

## Nix Binary Cache

Obsidian publishes prebuilt artifacts to a public cache so you don't have to
compile the toolchain yourself.

1. [Install Nix](https://nixos.org/nix/). If you already have Nix installed, make sure you have
   version 2.0 or higher (`nix-env --version`).

2. Set up the caches:
    1. If you are running NixOS, add this to `/etc/nixos/configuration.nix`:
        ```nix
        nix.binaryCaches = [ "s3://obsidian-open-source" ];
        nix.binaryCachePublicKeys = [ "obsidian-open-source:KP1UbL7OIibSjFo9/2tiHCYLm/gJMfy8Tim7+7P4o0I=" ];
        ```
        and rebuild your NixOS configuration (e.g. `sudo nixos-rebuild switch`).
    2. On other systems, ensure these lines are present in your Nix configuration file
       (`/etc/nix/nix.conf` on most systems;
       [see full list](https://nixos.org/nix/manual/#sec-conf-file)):
        ```nix
        binary-caches = https://cache.nixos.org s3://obsidian-open-source
        binary-cache-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= obsidian-open-source:KP1UbL7OIibSjFo9/2tiHCYLm/gJMfy8Tim7+7P4o0I=
        binary-caches-parallel-connections = 40
        ```

## About Obsidian Systems

nix-daml-sdk is built and maintained by **[Obsidian
Systems](https://obsidian.systems)**. We provide frontier engineering for
high-assurance systems. We're long-time stewards of open-source Nix and Haskell
tooling, including [Obelisk](https://github.com/obsidiansystems/obelisk),
[Reflex](https://reflex-frp.org/), and
[nix-thunk](https://github.com/obsidiansystems/nix-thunk) — and we build
production Daml and Canton applications.

If you're working with Daml, Canton, or Nix and want a partner to help design,
build, or ship it, we'd love to hear from you.

- Website — <https://obsidian.systems>
- Blog — <https://blog.obsidian.systems>
- GitHub — <https://github.com/obsidiansystems>

## License

nix-daml-sdk is released under the [BSD-3-Clause License](./LICENSE), © 2023–2026
Obsidian Systems LLC. The Daml SDK, Canton, DPM, and the other tools it packages
are distributed under their own upstream licenses.
