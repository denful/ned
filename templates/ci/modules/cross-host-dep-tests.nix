{
  lib,
  ned,
  inputs,
  ...
}:
{
  config.flake.tests."cross-host-dep" =
    let
      inherit (ned) st ST;

      topo-s = st {
        hosts.x86_64-linux.igloo.keyConsumer = true;
        hosts.x86_64-linux.iceberg = { };
      };

      # Reusable: NixOS module stream for a host
      nixos-modules-s =
        { host, keys }:
        let
          base-s = st { networking.hostName = host.name; };
        in
        if host.keyConsumer or false then
          base-s { users.users.root.openssh.authorizedKeys.keys = keys; }
        else
          base-s;

      main-c = sources: {
        os = st (
          { host }:
          let
            all-keys =
              lib.sort lib.lessThan
                (sources.os.map (item: "key-${item.os-configuration.config.networking.hostName}")).toList;
          in
          inputs.nixpkgs.lib.nixosSystem {
            inherit (host) system;
            modules =
              (nixos-modules-s {
                inherit host;
                keys = all-keys;
              }).toList;
          }
        );
        osItems = sources.os;
      };

      sinks = ned.run { os = ned.fwd.os-config-for topo-s; } main-c;
      igloo = lib.head (ned.topo.select-host "igloo" sinks.osItems).toList;
    in
    {
      test-ssh-authorized-keys = {
        expr = igloo.os-configuration.config.users.users.root.openssh.authorizedKeys.keys;
        expected = [
          "key-iceberg"
          "key-igloo"
        ];
      };
    };
}
