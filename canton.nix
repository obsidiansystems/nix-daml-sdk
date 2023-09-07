{ pkgs
, jdkVersion ? "jdk"
, version ? { type = "open-source"; number = "2.5.5"; }
, cantonSource ? {
    url = "https://github.com/digital-asset/daml/releases/download/v${version.number}/canton-open-source-${version.number}.tar.gz";
    sha256 = "111ffm8a4n6jgaw7h83q15z128ixxs66768y1103jqv7pql7jrm3";
  }
}:
let
  jdk = pkgs.${jdkVersion};
in
pkgs.stdenvNoCC.mkDerivation {
  name = "canton-${version.type}-${version.number}";
  src = builtins.fetchurl cantonSource;
  nativeBuildInputs = [pkgs.makeWrapper];
  buildInputs = [jdk];
  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/lib
    cp bin/canton $out/bin
    makeWrapper ${jdk}/bin/java $out/bin/canton
    cp -r lib/* $out/lib/
  '';
}
