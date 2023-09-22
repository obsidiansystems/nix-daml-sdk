{ vimMode ? false , extraPackages ? (_:[])
, system ? builtins.currentSystem
, jdkVersion ? "jdk"
, sdkVersion ? "2.6.4"
, sdkSpec ? builtins.fromJSON(builtins.readFile (./versions + "/${sdkVersion}.json"))
, cantonEnterprise ? false
}:
let
  cantonVersion = if cantonEnterprise then sdkSpec.cantonEnterprise else sdkSpec.canton;
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
        version = sdkVersion;
        sha256 = sdkSpec.sdk.extensionSha256;
      }
    ] ++ pkgs.lib.optional vimMode vscodevim.vim ;
  };
  sdk = import ./sdk.nix {
    inherit (pkgs) lib stdenv nodePackages nodejs;
    jdk = pkgs.${jdkVersion};
    sdkSpec = sdkSpec.sdk // { number = sdkVersion; };
  };
  canton = import ./canton.nix {
    inherit pkgs jdkVersion;
    version = cantonVersion // { number = sdkVersion; };
  };
in rec {
  inherit sdk canton;
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
