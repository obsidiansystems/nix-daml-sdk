{ pkgs
, jdkVersion ? "jdk"
, version ? { type = "open-source"; number = "2.5.5"; }
, useEnterprise ? false
, cantonSource ? {
    url = "https://github.com/digital-asset/daml/releases/download/v${version.number}/canton-open-source-${version.number}.tar.gz";
    sha256 = "111ffm8a4n6jgaw7h83q15z128ixxs66768y1103jqv7pql7jrm3";
  }
, cantonEnterpriseTarball ? pkgs.requireFile {
    name = "canton-enterprise-${version.number}.tar.gz";
    url = "https://digitalasset.jfrog.io/artifactory/canton-enterprise/canton-enterprise-${version.number}.tar.gz";
    sha256 = "00kisb6pygbqk6y3klzpff06myh44nyw95y7znn7y5v09zb8asxi";
  }
}:
let
  jdk = pkgs.${jdkVersion};
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
