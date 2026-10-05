{ pkgs
, jdkVersion ? "jdk"
, version
  # Since SDK 3.5, Canton is versioned independently of the SDK (e.g. SDK
  # 3.5.12 ships Canton 3.5.19); version pins then give it as `version`.
, cantonVersion ? version.version or version.number
, cantonSource ? {
    url = "https://github.com/digital-asset/daml/releases/download/v${cantonVersion}/canton-open-source-${cantonVersion}.tar.gz";
    inherit (version) sha256;
  }
, cantonEnterpriseTarball ? pkgs.requireFile {
    name = "canton-enterprise-${cantonVersion}.tar.gz";
    url = "https://digitalasset.jfrog.io/artifactory/canton-enterprise/canton-enterprise-${cantonVersion}.tar.gz";
    inherit (version) sha256;
  }
}:
let
  jdk = pkgs.${jdkVersion};
  useEnterprise = version.type == "enterprise";
  # Since 3.5, open-source Canton is no longer attached to GitHub releases;
  # it's only published to DA's OCI registry.  Version pins for those
  # releases give the digests of the artifact's layers instead of a sha256.
  useOci = !useEnterprise && version ? oci;

  fetchOciLayer = import ./oci.nix { inherit (pkgs) fetchurl; };
  ociLayer = title: suffix: fetchOciLayer {
    repository = "components/canton-open-source";
    digest = version.oci.${title};
    name = "canton-open-source-${cantonVersion}-${title}${suffix}";
  };

  setCantonHome = ''
    # Set CANTON_HOME automatically.
    mkdir -p $out/nix-support
    echo export CANTON_HOME=$out > $out/nix-support/setup-hook
  '';
in
if useOci then pkgs.stdenvNoCC.mkDerivation {
  name = "canton-${version.type}-${cantonVersion}";
  # The "lib" layer is a gzipped tarball of the lib/ directory holding the jar.
  src = ociLayer "lib" ".tar.gz";
  sourceRoot = ".";
  nativeBuildInputs = [pkgs.makeWrapper];
  # The OCI artifact has no launcher script (DPM runs the jar directly), so
  # provide `canton` ourselves.
  installPhase = ''
    mkdir -p $out/bin
    cp -r lib $out/
    cp ${ociLayer "LICENSE" ""} $out/LICENSE
    makeWrapper ${jdk}/bin/java $out/bin/canton \
      --add-flags "-jar $out/lib/canton-open-source-${cantonVersion}.jar"
  '';
  preFixup = setCantonHome;
}
else pkgs.stdenvNoCC.mkDerivation {
  name = "canton-${version.type}-${cantonVersion}";
  src = if useEnterprise then cantonEnterpriseTarball else builtins.fetchurl cantonSource;
  nativeBuildInputs = [pkgs.makeWrapper];
  buildInputs = [jdk];
  installPhase = "mkdir -p $out; cp -r * $out";
  preFixup = setCantonHome;
}
