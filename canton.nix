{ pkgs
, jdkVersion ? "jdk"
, version ? { type = "open-source"; number = "2.6.4"; }
, cantonSource ? {
    url = "https://github.com/digital-asset/daml/releases/download/v${version.number}/canton-open-source-${version.number}.tar.gz";
    sha256 = "sha256:0acj4gaz0lml1h7qgxp3772zmqlvx72mrl7q7lsqin3fnahfs7l6";
  }
, cantonEnterpriseTarball ? pkgs.requireFile {
    name = "canton-enterprise-${version.number}.tar.gz";
    url = "https://digitalasset.jfrog.io/artifactory/canton-enterprise/canton-enterprise-${version.number}.tar.gz";
    sha256 = "sha256:0ywh5xghjwv855g1y19z41b881b42s35grc82mzsd3s0xyhkfbgj";
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
