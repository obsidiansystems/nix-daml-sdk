{ vimMode ? false
, extraPackages ? (_:[])
, system ? builtins.currentSystem
, jdkVersion ? "jdk"
, sdkVersion ? "3.4.10"
, sdkSpec ? builtins.fromJSON(builtins.readFile (./versions + "/${sdkVersion}.json"))
, cantonEnterprise ? false
, enableScribe ? false
}:
(import ./default.nix {
  inherit vimMode extraPackages system jdkVersion cantonEnterprise sdkVersion sdkSpec enableScribe;
}).shell
