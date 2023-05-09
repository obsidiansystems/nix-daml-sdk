{ vimMode ? false , extraPackages ? (_:[]) }:
let
  pkgs = (import ./dep/reflex-platform {}).nixpkgs;
  packages = import ./default.nix { inherit vimMode extraPackages; };
in
  pkgs.mkShell {
    name = "daml-sdk";
    inherit packages;
  }
