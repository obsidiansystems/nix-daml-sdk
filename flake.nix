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
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };

      getStuff =
        {
          jdkVersion ? "jdk",
          sdkVersion ? "2.6.5",
        }:
        rec {
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
        };

      homeModule =
        { config, lib, ... }:
        let
          cfg = config.programs.daml-sdk;
        in
        {
          options.programs.daml-sdk = with lib.types; {
            enable = lib.mkOption {
              type = bool;
              default = false;
              description = "Enable DAML SDK";
            };
            version = lib.mkOption {
              type = string;
              default = "2.6.5";
              description = "Version of the DAML SDK";
            };
            canton.enterprise = lib.mkOption {
              type = bool;
              default = false;
              description = "Whether to use the Enterprise version of Canton";
            };
          };
          config = lib.mkIf cfg.enable (
            let
              stuff = getStuff { sdkVersion = cfg.version; };
            in
            {
              home.packages = with stuff; [
                jdk
                (if cfg.canton.enterprise then canton-enterprise else canton-free)
                daml-sdk
              ];
              programs.vscode.extensions = [ stuff.vscode-extension ];
            }
          );
        };

      defaultStuff = getStuff { };
    in
    {
      packages."x86_64-linux" = {
        inherit (defaultStuff)
          jdk
          vscode
          canton-free
          canton-enterprise
          daml-sdk
          ;
        vscode-extensions.DigitalAssetHoldingsLLC.daml = defaultStuff.vscode-extension;
        default = defaultStuff.daml-sdk;
      };

      devShells."x86_64-linux".default = pkgs.mkShell {
        name = "DAML";
        packages = [
          pkgs.bashInteractive
          pkgs.gitFull
          pkgs.nodePackages.typescript-language-server
          defaultStuff.canton-free
          defaultStuff.daml-sdk
          defaultStuff.vscode
        ];
      };

      homeModules.default = homeModule;

      formatter."x86_64-linux" = pkgs.nixfmt-rfc-style;
    };
}
