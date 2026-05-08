{ lib, config, ... }:
let
  inherit (config.ned) ctx-d st;

  # os-config-d :: ST comp -> ST comp
  #
  # Contextual driver: reads active host scope, applies component to build
  # osConfiguration (via nixpkgs.lib.nixosSystem or nix-darwin.lib.darwinSystem).
  # Maps result to { host, osConfiguration } for downstream grouping.
  os-config-d =
    comp-s:
    st (
      { host }:
      (ctx-d { inherit host; } comp-s).map (os-configuration: {
        inherit host;
        inherit os-configuration;
      })
    );

in
{
  ned = { inherit os-config-d; };
}
