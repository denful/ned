{
  lib,
  ned,
  inputs,
  ...
}:
{
  config.flake.tests.fwd =
    let
      inherit (ned) st ST;
    in
    {
      test-osConfigFor-host-and-osConfiguration = {
        expr =
          let
            topo-s = st {
              hosts.x86_64-linux.igloo = { };
              hosts.aarch64-linux.snow = { };
            };
            comp-s = st ({ host }: host.name);
            items = lib.sort (a: b: a.host.name < b.host.name) (ned.fwd.os-config-for topo-s comp-s).toList;
          in
          map (item: {
            name = item.host.name;
            os = item.os-configuration;
          }) items;
        expected = [
          {
            name = "igloo";
            os = "igloo";
          }
          {
            name = "snow";
            os = "snow";
          }
        ];
      };

      test-hostUserFor-per-user-modules = {
        expr =
          let
            topo-s = st { hosts.x86_64-linux.igloo.users.tux = { }; };
            comp-s = st (
              { host, user }:
              {
                description = "${host.name}/${user.name}";
              }
            );
          in
          (ned.fwd.host-user-for topo-s comp-s).toList;
        expected = [
          { nixos.users.users.tux.description = "igloo/tux"; }
        ];
      };
    };
}
