{
  lib,
  ned,
  inputs,
  ...
}:
{
  config.flake.tests.system =
    let
      inherit (ned) st ST;

      topo-s = st {
        hosts.x86_64-linux.igloo.users.tux = { };
        hosts.aarch64-darwin.venus.users.tux = { };
      };

      main-c = sources: {
        user = st (
          { host, user }:
          {
            description = "${host.name}/${user.name}";
          }
        );
        nixos = sources.user (ST.sub.flat "nixos");
        darwin = sources.user (ST.sub.flat "darwin");
      };

      sinks = ned.run { user = ned.fwd.host-user-for topo-s; } main-c;
    in
    {
      test-nixos-users-description = {
        expr =
          let
            cfg = inputs.nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = sinks.nixos.toList;
            };
          in
          cfg.config.users.users.tux.description;
        expected = "igloo/tux";
      };

      test-darwin-users-description = {
        expr =
          let
            cfg = inputs.nix-darwin.lib.darwinSystem {
              system = "aarch64-darwin";
              modules = sinks.darwin.toList;
            };
          in
          cfg.config.users.users.tux.description;
        expected = "venus/tux";
      };
    };
}
