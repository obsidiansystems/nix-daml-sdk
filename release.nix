{ project ? import ./.
, supportedSystems ? ["x86_64-linux" "x86_64-darwin" "aarch64-darwin"]
, jdks ? ["jdk" "jdk17" "jdk19"]
}:
let

  native-pkgs = (project {}).pkgs;
  inherit (native-pkgs) lib;

  allVersions = lib.genAttrs supportedSystems (system: let

    perJdk = lib.genAttrs jdks (jdkVersion: let
      args = {
        inherit system jdkVersion;
      };
    in lib.mapAttrs (_: lib.recurseIntoAttrs) {
      project = project args;
      project-with-vim = project (args // { vimMode = true; });
    });

    in lib.mapAttrs (_: lib.recurseIntoAttrs) perJdk
  );
in lib.mapAttrs (_: lib.recurseIntoAttrs) allVersions
