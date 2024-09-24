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
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      sdkSpec = builtins.fromJSON (builtins.readFile (./versions + "/${sdkVersion}.json"));
      daml-vscode-extension = pkgs.vscode-utils.extensionFromVscodeMarketplace {
        name = "daml";
        publisher = "DigitalAssetHoldingsLLC";
        version = sdkVersion;
        sha256 = sdkSpec.sdk.extensionSha256;
      };
      vscode = pkgs.vscode-with-extensions.override {
        vscodeExtensions = with pkgs.vscode-extensions; [
          haskell.haskell
          daml-vscode-extension
        ];
      };
      jdk = pkgs.${jdkVersion};
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
      canton = import ./canton.nix {
        inherit pkgs jdkVersion;
        version = sdkSpec.canton // {
          number = sdkVersion;
        };
      };
    in
    {
      packages."x86_64-linux" = {
        inherit
          daml-sdk
          jdk
          vscode
          canton
          daml-vscode-extension
          ;
      };

      devShells."x86_64-linux".default = pkgs.mkShell {
        name = "DAML";
        packages = [
          daml-sdk
          vscode
          canton
          pkgs.gitFull
          pkgs.nodePackages.typescript-language-server
        ];
      };

      formatter."x86_64-linux" = pkgs.nixfmt-rfc-style;
    };
}
