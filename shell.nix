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
        version = "2.6.4";
        sha256 = "sha256-kU8yoQe4mjQqgVbrmucn/ucKaiU7HsrkF36dArzX8Tg=";
      }
    ] ++ pkgs.lib.optional vimMode vscodevim.vim ;
  };
in
  pkgs.mkShell {
    name = "daml-sdk";
    packages = [
      (import ./sdk.nix { inherit (pkgs) lib stdenv jdk nodePackages nodejs; })
      vscodeWithExtensions
      pkgs.gitFull
      pkgs.nodePackages.typescript-language-server
    ] ++ (extraPackages pkgs);
  }
