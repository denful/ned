let
  # ---------------------------------------------------------------------------
  # run :: drivers -> cycleC -> sinks
  #
  # Cycle.js fixed-point: each source is its driver applied to the matching
  # sink. Nix laziness makes the mutual recursion safe.
  # ---------------------------------------------------------------------------
  run =
    drivers: cycleC:
    let
      sources = builtins.mapAttrs (name: driverD: driverD sinks.${name}) drivers;
      sinks = cycleC sources;
    in
    sinks;
in
{
  ned = { inherit run; };
}
