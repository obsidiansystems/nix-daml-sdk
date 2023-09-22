{ pkgs
, jdkVersion ? "jdk"
, version
, cantonSource ? {
    url = "https://github.com/digital-asset/daml/releases/download/v${version.number}/canton-open-source-${version.number}.tar.gz";
    inherit (version) sha256;
  }
, cantonEnterpriseTarball ? pkgs.requireFile {
    name = "canton-enterprise-${version.number}.tar.gz";
    url = "https://digitalasset.jfrog.io/artifactory/canton-enterprise/canton-enterprise-${version.number}.tar.gz";
    inherit (version) sha256;
  }
}:
let
  jdk = pkgs.${jdkVersion};
  useEnterprise = version.type == "enterprise";
in
pkgs.stdenvNoCC.mkDerivation {
  name = "canton-${version.type}-${version.number}";
  src = if useEnterprise then cantonEnterpriseTarball else builtins.fetchurl cantonSource;
  nativeBuildInputs = [pkgs.makeWrapper];
  buildInputs = [jdk];
  installPhase = "mkdir -p $out; cp -r * $out";
  preFixup = ''
    # Set CANTON_HOME automatically.
    mkdir -p $out/nix-support
    echo export CANTON_HOME=$out > $out/nix-support/setup-hook
  '';
}
