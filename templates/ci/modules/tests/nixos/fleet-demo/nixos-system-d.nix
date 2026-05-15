{ inputs, ... }:
{
  # nixos-system-d :: [module] -> ST {hostName, module} -> {hostName -> nixosConfig}
  #
  # Terminal driver: groups nixos sink by hostName, builds nixosSystem per host.
  # Auto-discovers host names from stream — no hardcoded list needed.
  fleet-demo.nixos-system-d =
    base-mods: nixos-sink:
    let
      by-host = builtins.groupBy (e: e.hostName) nixos-sink.toList;
    in
    builtins.mapAttrs (
      _: entries:
      (inputs.nixpkgs.lib.nixosSystem {
        modules = base-mods ++ map (e: e.module) entries;
      }).config
    ) by-host;
}
