{ pkgs
, jdkVersion ? "jdk"
, version
, scribeSource ? pkgs.requireFile {
    name = "scribe-v${version.number}.tar.gz";
    url = "Scribe URL here";
    inherit (version) sha256;
  }
}: let
  jdk = pkgs.${jdkVersion};
in let
  scribe = pkgs.stdenvNoCC.mkDerivation {
    name = "scribe-${version.number}";
    src = scribeSource;
    nativeBuildInputs = [
      pkgs.makeWrapper
    ];
    buildInputs = [
      jdk
    ];
    installPhase = "mkdir -p $out; cp -r * $out";
  };
in pkgs.writeShellScriptBin "scribe" ''
  ${jdk}/bin/java -jar ${scribe}/scribe.jar $@
''
