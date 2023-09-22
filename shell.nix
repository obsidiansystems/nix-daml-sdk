{ vimMode ? false
, extraPackages ? (_:[])
, system ? builtins.currentSystem
, jdkVersion ? "jdk"
, sdkSpec ? builtins.fromJSON(builtins.readFile ./versions/2.6.4.json)
, cantonEnterprise ? false
}:
(import ./default.nix {
  inherit vimMode extraPackages system jdkVersion cantonEnterprise sdkSpec;
}).shell
