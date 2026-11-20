# A complete DPM SDK: dpm plus every component of an SDK release (damlc,
# daml-script, codegen, Canton, ...), installed from the offline bundle that
# DA's installer uses (https://get.digitalasset.com/install/install.sh).
#
# The installer unpacks the bundle and runs `dpm bootstrap` to copy it into
# ~/.dpm.  We run the same bootstrap at build time into the store instead,
# and wrap dpm to use that as its home, so no SDK has to be installed into a
# mutable ~/.dpm.  Setting DPM_HOME still selects a different home.
{ lib
, stdenvNoCC
, fetchurl
, makeWrapper
, jdk
, system ? builtins.currentSystem
, version
, dpmSpec
}:
let
  platform = {
    x86_64-linux = "linux-amd64";
    aarch64-linux = "linux-arm64";
    x86_64-darwin = "darwin-amd64";
    aarch64-darwin = "darwin-arm64";
  }.${system} or (builtins.abort "DPM has no SDK bundle for ${system}.");

  bundle = fetchurl {
    name = "dpm-sdk-${version}-${platform}.tar.gz";
    url = "https://artifactregistry.googleapis.com/download/v1/projects/da-images/locations/europe/repositories/public-generic/files/dpm-sdk:${version}:dpm-${version}-${platform}.tar.gz:download?alt=media";
    hash = dpmSpec.sdkBundle.${system} or (builtins.abort "There is currently no DPM SDK bundle pinned for ${system}.");
  };
in
stdenvNoCC.mkDerivation {
  pname = "dpm-sdk";
  inherit version;

  src = bundle;
  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    export HOME=$TMPDIR
    export DPM_HOME=$out/share/dpm
    ./bin/dpm bootstrap .

    # The components' launcher scripts start with `#!/usr/bin/env sh` (or
    # bash), which doesn't exist inside Nix build sandboxes, so building a
    # project with dpm in a derivation would fail without this.
    patchShebangs $DPM_HOME/cache/components

    # The bootstrap also keeps a compressed copy of every component, as an
    # OCI layout (1.2GB for 3.5.12), besides the unpacked components dpm runs.
    # dpm only needs the directory to exist (it creates it on startup).
    rm -rf $DPM_HOME/cache/oci-layout
    mkdir $DPM_HOME/cache/oci-layout

    mkdir -p $out/bin
    # daml-script, codegen and Canton run on the JVM, so (as with `daml` in
    # sdk.nix) provide the configured JDK.
    makeWrapper $DPM_HOME/bin/dpm $out/bin/dpm \
      --set-default DPM_HOME $DPM_HOME \
      --prefix PATH : ${jdk}/bin

    runHook postInstall
  '';

  # Otherwise keep the components as bootstrapped.  They're self-contained
  # (damlc and friends ship and run through their own dynamic linker, libc
  # and libstdc++), as with the pre-3.5 SDK tarball in sdk.nix.
  dontFixup = true;

  meta = with lib; {
    description = "Daml SDK ${version}, as installed by DPM";
    homepage = "https://get.digitalasset.com/install";
    license = licenses.asl20;
  };
}
