{ lib, config, ... }:
let
  inherit (config.priv) ctxD st;

  # osConfigD :: ST comp -> ST comp
  #
  # Contextual driver: reads active host scope, applies component to build
  # osConfiguration (via nixpkgs.lib.nixosSystem or nix-darwin.lib.darwinSystem).
  # Maps result to { host, osConfiguration } for downstream grouping.
  osConfigD =
    compS:
    st (
      { host }:
      (ctxD { inherit host; } compS).map (osConfiguration: {
        inherit host osConfiguration;
      })
    );

in
{
  priv = { inherit osConfigD; };
}
