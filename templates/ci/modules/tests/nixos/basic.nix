# Configures a single host with a user using contextual streams.
# For fleet example with cycle components and cross-host config see nixos/fleet.nix
{
  lib,
  ned,
  inputs,
  ...
}:
let
  inherit (ned) run st ctx-d;

  infra = {
    igloo = {
      name = "igloo";
      domain = "antartic.org";
      system = "x86_64-linux";
      users = [
        { name = "tux"; }
      ];
    };
  };

  # host and user context drivers
  host-d = host: ctx-d { inherit host; };
  user-d = user: ctx-d { inherit user; };

  # contextual driver, fanouts computation stream per each host user.
  fanout-host-to-user-d =
    comp-s: { host }: (st.fromList host.users).flatMap (user: (user-d user) comp-s);

  module-s = st defaults-s (host-d infra.igloo host-module-s);

  defaults-s = st {
    boot.loader.grub.enable = false;
    fileSystems."/".device = "/dev/null";
    fileSystems."/".fsType = "tmpfs";
  };

  host-module-s = st (
    { host }:
    {
      nixpkgs.hostPlatform = host.system;
      networking.hostName = host.name;
      networking.hosts = {
        "127.0.0.1" = [ "${host.name}.${host.domain}" ];
      };
    }
  ) (fanout-host-to-user-d user-module-s);

  user-module-s = st (
    { host, user }:
    {
      users.users.${user.name} = {
        isNormalUser = true;
        description = "${user.name}@${host.name}";
      };
    }
  );

  igloo = (inputs.nixpkgs.lib.nixosSystem { modules = module-s.toList; }).config;

  expr = {
    igloo = igloo.networking.hosts."127.0.0.1";
    tux = igloo.users.users.tux.description;
  };

  expected = {
    igloo = [ "igloo.antartic.org" ];
    tux = "tux@igloo";
  };

in
{
  flake.tests.nixos.test-basic = { inherit expr expected; };
}
