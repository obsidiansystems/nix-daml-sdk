{ lib, stdenv, jdk, nodePackages, nodejs
, sdkVersion
}:
let
  version = sdkVersion.number;
  tarball = if stdenv.isDarwin then macos-tarball else linux-tarball;
  linux-tarball = fetchTarball {
    url = "https://github.com/digital-asset/daml/releases/download/v${version}/daml-sdk-${version}-linux.tar.gz";
    sha256 = sdkVersion.linuxSha256;
  };
  macos-tarball = fetchTarball {
    url = "https://github.com/digital-asset/daml/releases/download/v${version}/daml-sdk-${version}-macos.tar.gz";
    sha256 = sdkVersion.macSha256;
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
