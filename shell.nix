{ vimMode ? false , extraPackages ? (_:[]) }:
let
  rp = import ./dep/reflex-platform {};
  pkgs = rp.nixpkgs;
  vscodeWithExtensions = pkgs.vscode-with-extensions.override {
    vscodeExtensions = with pkgs.vscode-extensions; [
      haskell.haskell
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      { name = "daml";
        publisher = "DigitalAssetHoldingsLLC";
        version = "2.5.3";
        sha256 = "sha256-zJPX9NTXN14Vnc112ZFlUY7IaD09VYENoGkpQZevyME=";
      }
    ] ++ pkgs.lib.optional vimMode vscodevim.vim ;
  };
in
  pkgs.mkShell {
    name = "daml-sdk";
    packages = [
      (import ./sdk.nix { inherit (pkgs) lib stdenv jdk nodePackages nodejs; })
      vscodeWithExtensions
      pkgs.git
      pkgs.nodePackages.typescript-language-server
    ] ++ (extraPackages pkgs);
  }
