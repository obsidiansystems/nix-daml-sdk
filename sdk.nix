{ lib, stdenv, jdk, nodePackages, nodejs
, sdkSpec
, foo ? "3.3.0-snapshot.20250528.13806.0.v3cd439fb"
}:
let
  version = sdkSpec.number;
  rev = if sdkSpec ? rev then ".sdkSpec.rev" else "";
  tarball = if stdenv.isDarwin then macos-tarball else linux-tarball;
  linux-tarball = fetchTarball {
    url = "https://github.com/digital-asset/daml/releases/download/v${version}/daml-sdk-${foo}-linux.tar.gz";
    sha256 = sdkSpec.linuxSha256;
  };
  macos-tarball = fetchTarball {
    url = "https://github.com/digital-asset/daml/releases/download/v${version}/daml-sdk-${foo}-macos.tar.gz";
    sha256 = sdkSpec.macSha256;
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
