let
  # ---------------------------------------------------------------------------
  # run :: drivers -> cycle-c -> sinks
  #
  # Cycle.js fixed-point: each source is its driver applied to the matching
  # sink. Nix laziness makes the mutual recursion safe.
  # ---------------------------------------------------------------------------
  run =
    drivers: cycle-c:
    let
      sources = builtins.mapAttrs (name: drv-d: drv-d sinks.${name}) drivers;
      sinks = cycle-c sources;
    in
    sinks;
in
{
  ned = { inherit run; };
}
