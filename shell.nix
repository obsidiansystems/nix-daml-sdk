{ vimMode ? false
, extraPackages ? (_:[])
, system ? builtins.currentSystem
, jdkVersion ? "jdk"
}:
(import ./default.nix {
  inherit vimMode extraPackages system jdkVersion;
}).shell
