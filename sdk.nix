{ lib, stdenv, jdk }:
let 
  version = "2.5.1";
  tarball = fetchTarball {
    url = "https://github.com/digital-asset/daml/releases/download/v${version}/daml-sdk-${version}-linux.tar.gz";
    sha256 = "sha256:1n59rsi4i3mk0b7c0sxy0yvbr7xjqslcml1d7l5s210fzdbmankg";
  };
in
  stdenv.mkDerivation {
    inherit version;
    name = "daml-sdk";
    src = tarball;
    buildPhase = "patchShebangs .";
    installPhase = "DAML_HOME=$out ./install.sh";
    propagatedBuildInputs = [ jdk ];
    meta = with lib; {
      description = "SDK for Daml smart contract language";
      homepage = "https://github.com/digital-asset/daml";
      license = licenses.asl20;
    };
  }
