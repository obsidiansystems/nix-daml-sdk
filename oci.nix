# Fetch one layer of an artifact in Digital Asset's public OCI registry
# (europe-docker.pkg.dev/da-images/public), where Canton and DPM components
# have been published since SDK 3.5.  Blobs download anonymously over plain
# HTTPS, and an OCI layer digest is the sha256 of the blob itself, so the
# digest from the artifact's manifest is all that's needed to pin it.
{ fetchurl }:

{ repository   # e.g. "components/canton-open-source"
, digest       # hex sha256, without the "sha256:" prefix
, name
}:
fetchurl {
  inherit name;
  url = "https://europe-docker.pkg.dev/v2/da-images/public/${repository}/blobs/sha256:${digest}";
  sha256 = digest;
}
