{ project ? import ./.
, supportedSystems ? ["x86_64-linux" "x86_64-darwin"]
}:
let

  native-pkgs = (project {}).pkgs;
  inherit (native-pkgs) lib;

  perPlatform = lib.genAttrs supportedSystems (system: let
    args = {
      inherit system;
    };
  in lib.mapAttrs (_: lib.recurseIntoAttrs) {
    project = project args;
    project-with-vim = project (args // { vimMode = true; });
  });

in lib.mapAttrs (_: lib.recurseIntoAttrs) perPlatform
