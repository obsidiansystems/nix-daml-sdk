{ lib
, stdenv
, fetchurl
, system ? builtins.currentSystem
, version
, dpmSpec
}:
let
  dpmTarballs =
    let
      baseUrl = os: arch: "https://artifactregistry.googleapis.com/download/v1/projects/da-images/locations/europe/repositories/public-generic/files/dpm-sdk:${version}:dpm-${version}-${os}-${arch}.tar.gz:download?alt=media";
    in
    {
      "x86_64-linux" = {
        url = baseUrl "linux" "amd64";
        sha256 = dpmSpec.linuxSha256;
      };
      "aarch64-darwin" = {
        url = baseUrl "darwin" "arm64";
        sha256 = dpmSpec.macSha256;
      };
    };
  dpmTarball = fetchTarball (dpmTarballs.${system} or (builtins.abort "There is currently no DPM tarball defined for ${system}."));

  # The SDK tarball above bundles every SDK component (over 1GB for 3.5), of
  # which we only keep bin/dpm.  Newer version pins instead give the digest of
  # the dpm binary itself in DA's OCI registry, which is the same file.
  useOci = dpmSpec ? oci;
  fetchOciLayer = import ./oci.nix { inherit fetchurl; };
  dpmBinary = fetchOciLayer {
    repository = "components/dpm";
    digest = dpmSpec.oci.${system} or (builtins.abort "There is currently no DPM binary defined for ${system}.");
    name = "dpm-${dpmSpec.version}";
  };
in
  stdenv.mkDerivation ({
    inherit version;

    name = "dpm";
    src = dpmTarball;
    buildPhase = "patchShebangs .";
    installPhase = ''
      mkdir -p $out/bin
      cp ./bin/dpm $out/bin/dpm
    '';
    nativeBuildInputs = [ ];
    propagatedBuildInputs = [ ];
    meta = with lib; {
      description = "Drop-in replacement for the (now deprecated) Daml Assistant.";
      homepage = "https://get.digitalasset.com/install";
      license = licenses.asl20;
    };
  } // lib.optionalAttrs useOci {
    src = null;
    dontUnpack = true;
    # Install the binary exactly as published (and pinned by its digest).
    dontStrip = true;
    buildPhase = ":";
    installPhase = ''
      install -D -m755 ${dpmBinary} $out/bin/dpm
    '';
  })
