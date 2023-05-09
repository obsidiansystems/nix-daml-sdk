{ vimMode ? false , extraPackages ? (_:[]) }:
let
  pkgs = (import ./dep/reflex-platform {}).nixpkgs;
  damlPkgs = import ./default.nix { inherit vimMode extraPackages; };
in
  pkgs.mkShell {
    name = "daml-sdk";
    packages = [
      damlPkgs.sdk
      damlPkgs.vscode
    ] ++ damlPkgs.extra;
  }
