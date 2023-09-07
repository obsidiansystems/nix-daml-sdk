{ vimMode ? false , extraPackages ? (_:[])
, system ? builtins.currentSystem
, jdkVersion ? "jdk"
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
  sdk = import ./sdk.nix {
    inherit (pkgs) lib stdenv nodePackages nodejs;
    jdk = pkgs.${jdkVersion};
  };
  canton = import ./canton.nix {
    inherit pkgs jdkVersion;
  };
  canton-enterprise = import ./canton.nix {
    inherit pkgs jdkVersion;
    useEnterprise = true;
  };
in rec {
  inherit sdk canton canton-enterprise;
  vscode = vscodeWithExtensions;
  jdk = pkgs.${jdkVersion};
  extra = [
      pkgs.gitFull
      pkgs.nodePackages.typescript-language-server
    ] ++ (extraPackages pkgs);
  inherit pkgs;
  shell = pkgs.mkShell {
    name = "daml-sdk";
    packages = [
      sdk
      vscode
    ] ++ extra;
  };
}
