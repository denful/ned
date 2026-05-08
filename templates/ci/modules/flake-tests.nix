{
  lib,
  ned,
  inputs,
  ...
}:
{
  config.flake.tests.flake =
    let
      inherit (ned) st ST;

      topo-s = st {
        hosts.x86_64-linux.igloo.users.tux = { };
        hosts.aarch64-darwin.venus.users.tux = { };
      };

      # Component: produces config modules per host
      host-config-s = st (
        { host }:
        {
          networking.hostName = host.name;
          system.stateVersion = if host.class == "darwin" then 25 else 24;
        }
      );

      # Driver: groups host configs by class
      host-config-group-d =
        comp-s:
        st (
          { host }:
          (ned.drive.ctx { inherit host; } comp-s).map (attrs: {
            ${host.class} = attrs;
          })
        );

      # Driver: fan out hosts via topology, then group by class
      host-config-d = comp-s: comp-s host-config-group-d (ned.topo.hosts topo-s);

      # Cycle: groups host configs by class, builds OS configs
      flake-c = sources: {
        hostcfg = host-config-s;
        os = st (
          { host }:
          let
            class-modules =
              if host.class == "nixos" then
                sources.hostcfg (ST.sub.flat "nixos")
              else
                sources.hostcfg (ST.sub.flat "darwin");
          in
          if host.class == "nixos" then
            inputs.nixpkgs.lib.nixosSystem {
              inherit (host) system;
              modules = class-modules.toList;
            }
          else
            inputs.nix-darwin.lib.darwinSystem {
              inherit (host) system;
              modules = class-modules.toList;
            }
        );
        flake = sources.os.flatMap (
          item:
          st {
            nixosConfigurations =
              if item.host.class == "nixos" then st { ${item.host.name} = item.os-configuration; } else st;
            darwinConfigurations =
              if item.host.class == "darwin" then st { ${item.host.name} = item.os-configuration; } else st;
          }
        );
      };

      sinks = ned.run {
        os = ned.fwd.os-config-for topo-s;
        hostcfg = host-config-d;
      } flake-c;
      nixos-configs = sinks.flake (ST.sub.flat "nixosConfigurations");
      darwin-configs = sinks.flake (ST.sub.flat "darwinConfigurations");
    in
    {
      test-flake-hostconfig-values-propagate = {
        expr = {
          nixos = (lib.head (nixos-configs.toList)).igloo.config.networking.hostName;
          darwin = (lib.head (darwin-configs.toList)).venus.config.networking.hostName;
        };
        expected = {
          nixos = "igloo";
          darwin = "venus";
        };
      };
    };
}
