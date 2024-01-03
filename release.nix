{ project ? import ./.
, supportedSystems ? ["x86_64-linux" "x86_64-darwin"]
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
      project_255 = project (args // { sdkVersion = "2.5.5"; });
      project_264 = project (args // { sdkVersion = "2.6.4"; });
      project_265 = project (args // { sdkVersion = "2.6.5"; });
      project_271 = project (args // { sdkVersion = "2.7.1"; });
    });

    in lib.mapAttrs (_: lib.recurseIntoAttrs) (perJdk // {
      ghc-shell = let pkgs = (project { inherit system; }).pkgs; in pkgs.mkShell {
        buildInputs = [
	        (pkgs.haskell.packages.ghc8107.ghcWithPackages(hs: with hs; [ http-conduit async optparse-applicative xml HsYAML ansi-terminal ]))
        ];
      };
    })
  );
in lib.mapAttrs (_: lib.recurseIntoAttrs) allVersions
