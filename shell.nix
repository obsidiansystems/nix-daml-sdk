let
  rp = import ./reflex-platform {};
  pkgs = rp.nixpkgs;
in
  pkgs.mkShell {
    name = "daml-sdk";
    packages = [ (import ./. { inherit (pkgs) lib stdenv jdk; }) ];
  }
