{ vimMode ? false , extraPackages ? (_:[])
, system ? builtins.currentSystem
}:
let
  pkgs = import ./dep/nixpkgs {
    inherit system;
    config = { allowUnfree = true; };
  };
  vscodeWithExtensions = pkgs.vscode-with-extensions.override {
    vscodeExtensions = with pkgs.vscode-extensions; [
      haskell.haskell
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      { name = "daml";
        publisher = "DigitalAssetHoldingsLLC";
        version = sdk.version;
        sha256 = "sha256-kVHXjuCNqJWKSZRT72Dg3eqf3R8xKo7N+qY9ISyrKHM=";
      }
    ] ++ pkgs.lib.optional vimMode vscodevim.vim ;
  };
  sdk = import ./sdk.nix { inherit (pkgs) lib stdenv jdk nodePackages nodejs; };
in {
  sdk = sdk;
  vscode = vscodeWithExtensions;
  jdk = pkgs.jdk;
  extra = [
      pkgs.gitFull
      pkgs.nodePackages.typescript-language-server
    ] ++ (extraPackages pkgs);
  inherit pkgs;
  }
