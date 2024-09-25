{
  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-24.05";
    };
  };

  outputs =
    { self, nixpkgs }:
    let
      sdkVersion = "2.8.0";
      jdkVersion = "jdk";
      scribeVersion = "0.1.1";

      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };

      jdk = pkgs.${jdkVersion};
      sdkSpec = builtins.fromJSON (builtins.readFile (./versions + "/${sdkVersion}.json"));

      vscode-extension = pkgs.vscode-utils.extensionFromVscodeMarketplace {
        name = "daml";
        publisher = "DigitalAssetHoldingsLLC";
        version = sdkVersion;
        sha256 = sdkSpec.sdk.extensionSha256;
      };
      vscode = pkgs.vscode-with-extensions.override {
        vscodeExtensions = with pkgs.vscode-extensions; [
          haskell.haskell
          vscode-extension
        ];
      };

      daml-sdk = import ./sdk.nix {
        inherit (pkgs)
          lib
          stdenv
          nodePackages
          nodejs
          ;
        inherit jdk;
        sdkSpec = sdkSpec.sdk // {
          number = sdkVersion;
        };
      };

      canton-free = import ./canton.nix {
        inherit pkgs jdkVersion;
        version = sdkSpec.canton // {
          number = sdkVersion;
        };
      };
      canton-enterprise = import ./canton.nix {
        inherit pkgs jdkVersion;
        version = sdkSpec.cantonEnterprise // {
          number = sdkVersion;
        };
      };

      scribe = import ./scribe.nix {
        inherit pkgs jdkVersion;
        version = (import (./scribe-versions + "/${scribeVersion}.nix")) // { number = scribeVersion; };
      };
    in
    {
      packages."x86_64-linux" = {
        inherit
          jdk
          vscode
          canton-free
          canton-enterprise
          scribe
          daml-sdk
          ;
        vscode-extensions.DigitalAssetHoldingsLLC.daml = vscode-extension;
        default = daml-sdk;
      };

      devShells."x86_64-linux".default = pkgs.mkShell {
        name = "DAML";
        packages = [
          pkgs.bashInteractive
          pkgs.gitFull
          pkgs.nodePackages.typescript-language-server
          canton-free
          daml-sdk
          vscode
        ];
      };

      formatter."x86_64-linux" = pkgs.nixfmt-rfc-style;
    };
}
