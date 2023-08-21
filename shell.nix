{ vimMode ? false , extraPackages ? (_:[])
, system ? builtins.currentSystem
, jdkVersion ? "jdk"
}:
let
  pkgs = damlPkgs.pkgs;
  damlPkgs = import ./default.nix {
    inherit vimMode extraPackages system jdkVersion;
  };
in
  pkgs.mkShell {
    name = "daml-sdk";
    packages = [
      damlPkgs.sdk
      damlPkgs.vscode
    ] ++ damlPkgs.extra;
  }
