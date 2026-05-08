{
  lib,
  config,
  fx,
  ...
}:
let
  inherit (config.priv) wrap st ctxD;

  # ---------------------------------------------------------------------------
  # topo.hosts :: ST topology -> ST comp -> ST result
  #
  # Fan-out driver over topology hosts.
  # Topology shape: { hosts.${system}.${name} = { ...hostAttrs... }; }
  #
  # Builds host objects: { name, system } // hostAttrs
  # Merges host attrs across topologies by (system, name)
  # Scopes compS with { host = hostObj; } via ctxD per host.
  # Concatenates all per-host result streams — never materialises to list.
  # ---------------------------------------------------------------------------
  hostsT =
    topoS: compS:
    let
      topologies = topoS.toList;
      hostsByKey = lib.foldl' (
        acc: topo:
        lib.foldlAttrs (
          acc2: sys: sysAttrs:
          lib.foldlAttrs (
            acc3: name: hostAttrs:
            let
              key = "${sys}/${name}";
            in
            acc3
            // {
              ${key} = if acc3 ? ${key} then lib.recursiveUpdate acc3.${key} hostAttrs else hostAttrs;
            }
          ) acc2 sysAttrs
        ) acc (topo.hosts or { })
      ) { } topologies;

      hosts = builtins.map (
        key:
        let
          parts = lib.splitString "/" key;
          system = builtins.elemAt parts 0;
          hostAttrs = hostsByKey.${key};
        in
        {
          name = builtins.elemAt parts 1;
          inherit system;
          class = hostAttrs.class or (if lib.hasSuffix "darwin" system then "darwin" else "nixos");
        }
        // hostAttrs
      ) (builtins.attrNames hostsByKey);
    in
    (wrap (fx.stream.fromList hosts)).flatMap (host: ctxD { inherit host; } compS);
in
{
  priv = { inherit hostsT; };
}
