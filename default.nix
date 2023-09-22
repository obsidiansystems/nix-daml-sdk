{ vimMode ? false , extraPackages ? (_:[])
, system ? builtins.currentSystem
, jdkVersion ? "jdk"
, sdkVersion ? {
    number = "2.6.4";
    linuxSha256 = "sha256:1cxv1plv6jn83ngv110z76ppngvmvxhj2sn85jqfm3viry66rjab";
    macSha256 = "sha256:0fxw53aiqkq20z179p5i4a1zd0myq0vkvfp1k7hfnws2v6615ss6";
    extensionSha256 = "sha256-kVHXjuCNqJWKSZRT72Dg3eqf3R8xKo7N+qY9ISyrKHM="; 
  }
, cantonVersion ? {
    type = "open-source"; # or "enterprise"
    number = "2.6.4";
    sha256 = "sha256:0acj4gaz0lml1h7qgxp3772zmqlvx72mrl7q7lsqin3fnahfs7l6";
    # enterprise v2.6.4 sha256 = "sha256:0ywh5xghjwv855g1y19z41b881b42s35grc82mzsd3s0xyhkfbgj";
  }
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
        version = sdkVersion.number;
        sha256 = sdkVersion.extensionSha256;
      }
    ] ++ pkgs.lib.optional vimMode vscodevim.vim ;
  };
  sdk = import ./sdk.nix {
    inherit (pkgs) lib stdenv nodePackages nodejs;
    jdk = pkgs.${jdkVersion};
    inherit sdkVersion;
  };
  canton = import ./canton.nix {
    inherit pkgs jdkVersion;
    version = cantonVersion;
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
