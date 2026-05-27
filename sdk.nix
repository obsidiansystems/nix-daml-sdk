{ lib, stdenv, jdk, nodePackages, nodejs, bash
, sdkSpec, makeWrapper, coreutils
}:
let
  version = sdkSpec.number;
  release-version = sdkSpec.number;
  sdk-version = if sdkSpec ? sdk-version then sdkSpec.sdk-version else release-version;
  tarball = if stdenv.isDarwin then macos-tarball else linux-tarball;
  linux-tarball = fetchTarball {
    url = "https://github.com/digital-asset/daml/releases/download/v${release-version}/daml-sdk-${sdk-version}-linux.tar.gz";
    sha256 = sdkSpec.linuxSha256;
  };
  macos-tarball = fetchTarball {
    url = "https://github.com/digital-asset/daml/releases/download/v${release-version}/daml-sdk-${sdk-version}-macos.tar.gz";
    sha256 = sdkSpec.macSha256;
  };
  extra-args = if version == "2.8.0" then "--install-with-custom-version ${version}" else "";
in
  stdenv.mkDerivation {
    version = release-version;
    name = "daml-sdk";
    src = tarball;
    buildPhase = "patchShebangs .";
    installPhase = ''
      DAML_HOME=$out ./install.sh ${extra-args}
      sed -i "s/auto-install: true/auto-install: false/" $out/daml-config.yaml
      wrapProgram $out/bin/daml \
        --set PATH ${lib.makeBinPath [ jdk bash coreutils ]}
    '';
    nativeBuildInputs = [ makeWrapper ];
    propagatedBuildInputs = [ jdk nodePackages.npm nodejs ];
    meta = with lib; {
      description = "SDK for Daml smart contract language";
      homepage = "https://github.com/digital-asset/daml";
      license = licenses.asl20;
    };
  }
