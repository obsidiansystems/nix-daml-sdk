{ lib, stdenv, jdk, nodePackages, nodejs
, sdkSpec
}:
let
  release-version = sdkSpec.number;
  sdk-version = if sdkSpec ? sdk-version then sdkSpec.sdk-version else release-version;
  tarball = if stdenv.isDarwin then macos-tarball else linux-tarball;
  linux-tarball = fetchTarball {
    url = "https://github.com/digital-asset/daml/releases/download/v${release-version}/daml-sdk-${sdk-version}-linux.tar.gz";
    sha256 = sdkSpec.linuxSha256;
  };
  macos-tarball = fetchTarball {
    url = "https://github.com/digital-asset/daml/releases/download/v${release-version}/daml-sdk-${sdk-version}-macos-x86_64.tar.gz";
    sha256 = sdkSpec.macSha256;
  };
in
  stdenv.mkDerivation {
    version = release-version;
    name = "daml-sdk";
    src = tarball;
    buildPhase = "patchShebangs .";
    installPhase = ''
      DAML_HOME=$out ./install.sh
      sed -i "s/auto-install: true/auto-install: false/" $out/daml-config.yaml
    '';
    propagatedBuildInputs = [ jdk nodePackages.npm nodejs ];
    meta = with lib; {
      description = "SDK for Daml smart contract language";
      homepage = "https://github.com/digital-asset/daml";
      license = licenses.asl20;
    };
  }
