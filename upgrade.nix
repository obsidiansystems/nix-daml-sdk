{ pkgs
, jdkVersion ? "jdk"
, version ? { number = "2.1.0"; sha256 = "0lgzawnmrmlkp4jxgy7cs7v7v88p6kb2r9jm9g372rm75nfzxgxk"; }
}:
let
  daml-upgrade-source = pkgs.requireFile {
    name = "daml-upgrade-${version.number}.tar.gz";
    url = "";
    inherit (version) sha256;
  };
in pkgs.stdenv.mkDerivation {
  name = "daml-upgrade-${version.number}";
  src = daml-upgrade-source;
  nativeBuildInputs = with pkgs; [
    autoPatchelfHook
  ];
  buildInputs = with pkgs; [
    gmp
    zlib
  ];
  unpackPhase = ''
    tar xvf $src
  '';
  buildPhase = ''
    for i in $(dir); do
     if [[ -d $i ]]; then
       tar xvf $i/layer.tar
     else
       echo "No tarball"
     fi
    done
    mkdir -p $out/
    cp -r home/user/* $out
    mkdir -p $out/bin
    ln -s $out/codegen/upgrade-codegen $out/bin/upgrade-codegen
  '';
}
