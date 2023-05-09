{ lib, stdenv, jdk, nodePackages, nodejs }:
let 
  version = "2.6.4";
  tarball = fetchTarball {
    url = "https://github.com/digital-asset/daml/releases/download/v${version}/daml-sdk-${version}-linux.tar.gz";
    sha256 = "sha256:1cxv1plv6jn83ngv110z76ppngvmvxhj2sn85jqfm3viry66rjab";
  };
in
  stdenv.mkDerivation {
    inherit version;
    name = "daml-sdk";
    src = tarball;
    buildPhase = "patchShebangs .";
    installPhase = "DAML_HOME=$out ./install.sh";
    propagatedBuildInputs = [ jdk nodePackages.npm nodejs ];
    meta = with lib; {
      description = "SDK for Daml smart contract language";
      homepage = "https://github.com/digital-asset/daml";
      license = licenses.asl20;
    };
  }
