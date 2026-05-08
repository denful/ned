{
  lib,
  config,
  fx,
  ...
}:
let
  inherit (config.ned) wrap st ctx-d;

  # ---------------------------------------------------------------------------
  # topo.hosts :: ST topology -> ST comp -> ST result
  #
  # Fan-out driver over topology hosts.
  # Topology shape: { hosts.${system}.${name} = { ...host-attrs... }; }
  #
  # Builds host objects: { name, system } // host-attrs
  # Merges host attrs across topologies by (system, name)
  # Scopes comp-s with { host = hostObj; } via ctx-d per host.
  # Concatenates all per-host result streams — never materialises to list.
  # ---------------------------------------------------------------------------
  hosts-t =
    topo-s: comp-s:
    let
      topologies = topo-s.toList;
      hosts-by-key = lib.foldl' (
        acc: topo:
        lib.foldlAttrs (
          acc2: sys: sys-attrs:
          lib.foldlAttrs (
            acc3: name: host-attrs:
            let
              key = "${sys}/${name}";
            in
            acc3
            // {
              ${key} = if acc3 ? ${key} then lib.recursiveUpdate acc3.${key} host-attrs else host-attrs;
            }
          ) acc2 sys-attrs
        ) acc (topo.hosts or { })
      ) { } topologies;

      hosts = builtins.map (
        key:
        let
          parts = lib.splitString "/" key;
          system = builtins.elemAt parts 0;
          host-attrs = hosts-by-key.${key};
        in
        {
          name = builtins.elemAt parts 1;
          inherit system;
          class = host-attrs.class or (if lib.hasSuffix "darwin" system then "darwin" else "nixos");
        }
        // host-attrs
      ) (builtins.attrNames hosts-by-key);
    in
    (wrap (fx.stream.fromList hosts)).flatMap (host: ctx-d { inherit host; } comp-s);
in
{
  ned = { inherit hosts-t; };
}
