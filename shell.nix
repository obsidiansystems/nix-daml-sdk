{ vimMode ? false
, extraPackages ? (_:[])
, system ? builtins.currentSystem
, jdkVersion ? "jdk"
, sdkVersion ? "3.3.0-snapshot.20250507.0"
, sdkSpec ? builtins.fromJSON(builtins.readFile (./versions + "/${sdkVersion}.json"))
, cantonEnterprise ? false
}:
(import ./default.nix {
  inherit vimMode extraPackages system jdkVersion cantonEnterprise sdkVersion sdkSpec;
}).shell
