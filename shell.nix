{ vimMode ? false }:
let
  rp = import ./reflex-platform {};
  pkgs = rp.nixpkgs;
  vscodeWithExtensions = pkgs.vscode-with-extensions.override {
    vscodeExtensions = with pkgs.vscode-extensions; [
      haskell.haskell
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      { name = "daml";
        publisher = "DigitalAssetHoldingsLLC";
        version = "2.5.1";
        sha256 = "sha256-joe3j38AymdVfqSdVOc45LXpfCNnCWJxDeSRT8IPHsk=";
      }
    ] ++ pkgs.lib.optional vimMode vscodevim.vim ;
  };
in
  pkgs.mkShell {
    name = "daml-sdk";
    packages = [
      (import ./. { inherit (pkgs) lib stdenv jdk; })
      vscodeWithExtensions
      pkgs.git
    ];
  }
