# Tests for nix-daml-sdk.  Each test is a derivation, so it runs in the Nix
# build sandbox: offline, with HOME pointing at a scratch directory, and on
# Linux in a private network namespace (so the Canton sandbox's fixed ports
# can't clash with anything).
#
#   nix-build tests --argstr sdkVersion 3.5.12        # all tests
#   nix-build tests --argstr sdkVersion 3.5.12 -A ledger
#
# Tests only cover the components a version pin provides; currently they
# exercise the DPM-based (3.5+) toolchain.
{ sdkVersion ? "3.5.12"
, system ? builtins.currentSystem
}:
let
  nds = import ../. { inherit sdkVersion system; };
  inherit (nds) pkgs sdkSpec;
  inherit (pkgs) lib;

  test = name: deps: script: pkgs.runCommand "nix-daml-sdk-${sdkVersion}-test-${name}" {
    nativeBuildInputs = deps;
  } ''
    set -euo pipefail
    export HOME=$TMPDIR
    cd $TMPDIR
    ${script}
  '';

  cantonVersion = sdkSpec.canton.version or sdkVersion;
in
{
  # The Canton runtime starts and is the version the pin names.
  canton = test "canton" [ nds.canton ] ''
    canton --version | tee version
    grep -qx "Canton: ${cantonVersion}" version
    [ -n "$CANTON_HOME" ] && [ -d "$CANTON_HOME/lib" ]
    cp version $out
  '';

  # The bare dpm binary runs and is the version the pin names.
  dpm = test "dpm" [ nds.dpm ] ''
    dpm --version | tee version
    grep -q "${sdkSpec.dpm.version}" version
    cp version $out
  '';
} // lib.optionalAttrs (nds.dpmSdk != null) rec {
  # dpm with the bundled SDK: no ~/.dpm or network needed, and the SDK's own
  # Canton is the same version as the standalone `canton` above.
  dpm-sdk = test "dpm-sdk" [ nds.dpmSdk ] ''
    dpm version --active | tee active
    grep -q "${sdkVersion}" active
    dpm sandbox --version | tee canton-version
    grep -qx "Canton: ${cantonVersion}" canton-version
    # Nothing should have been written outside the store.
    [ ! -e "$HOME/.dpm" ]
    cat active canton-version > $out
  '';

  # Create, build and test the default project template: a multi-package
  # project with a template and a Daml Script that exercises it.
  project = test "project" [ nds.dpmSdk ] ''
    dpm new proj
    cd proj
    dpm build --all
    # Runs the Daml Script tests on an in-memory ledger.
    (cd test && dpm test)
    mkdir -p $out
    cp main/.daml/dist/*.dar test/.daml/dist/*.dar $out/
  '';

  # Run the project's `setup` script against a real Canton participant:
  # upload the DARs, allocate parties and users, create a contract and
  # exercise a choice on it twice.
  ledger = test "ledger" [ nds.canton nds.dpmSdk pkgs.curl pkgs.jq ] ''
    canton sandbox --no-tty --log-file-name log/canton.log > sandbox.out 2>&1 &
    sandbox=$!
    trap 'kill $sandbox 2>/dev/null || true; wait $sandbox 2>/dev/null || true' EXIT

    # The JSON API answers before the participant has connected to its
    # synchronizer, and commands fail until it has.
    connected() {
      curl -sf http://localhost:6864/v2/state/connected-synchronizers 2>/dev/null \
        | jq -e '.connectedSynchronizers | length > 0' > /dev/null
    }
    for _ in $(seq 1 240); do
      connected && break
      kill -0 $sandbox 2>/dev/null || { cat sandbox.out; exit 1; }
      sleep 1
    done
    connected || { echo "sandbox did not start"; tail -50 log/canton.log; exit 1; }

    dpm script --dar ${project}/proj-test-0.0.1.dar --script-name Test:setup \
      --ledger-host localhost --ledger-port 6865 --upload-dar true \
      --output-file result.json
    # setup returns the id of the final Asset contract.
    jq -e 'type == "string" and length > 0' result.json

    cp result.json $out
  '';
}
