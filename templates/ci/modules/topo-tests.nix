{
  lib,
  ned,
  inputs,
  ...
}:
{
  config.flake.tests.topo =
    let
      inherit (ned) st ST;
    in
    {
      # Host topology tests
      host.test-host-name = {
        expr =
          let
            topo-s = st { hosts.x86_64-linux.igloo.users.tux = { }; };
          in
          (st ({ host }: host.name) (ned.topo.hosts topo-s)).toList;
        expected = [ "igloo" ];
      };

      host.test-host-system = {
        expr =
          let
            topo-s = st { hosts.x86_64-linux.igloo.users.tux = { }; };
          in
          (st ({ host }: host.system) (ned.topo.hosts topo-s)).toList;
        expected = [ "x86_64-linux" ];
      };

      host.test-host-users = {
        expr =
          let
            topo-s = st { hosts.x86_64-linux.igloo.users.tux = { }; };
          in
          (st ({ host }: builtins.attrNames host.users) (ned.topo.hosts topo-s)).toList;
        expected = [ [ "tux" ] ];
      };

      host.test-host-object-complete = {
        expr =
          let
            topo-s = st { hosts.x86_64-linux.igloo.users.tux = { }; };
          in
          (st (
            { host }:
            {
              inherit (host) name system users;
            }
          ) (ned.topo.hosts topo-s)).toList;
        expected = [
          {
            name = "igloo";
            system = "x86_64-linux";
            users = {
              tux = { };
            };
          }
        ];
      };

      host.test-host-extra-attrs = {
        expr =
          let
            topo-s = st {
              hosts.x86_64-linux.igloo = {
                users.tux = { };
                tags = [ "server" ];
              };
            };
          in
          (st ({ host }: host.tags) (ned.topo.hosts topo-s)).toList;
        expected = [ [ "server" ] ];
      };

      host.test-multi-host-fanout = {
        expr =
          let
            topo-s = st {
              hosts.x86_64-linux.igloo = { };
              hosts.aarch64-linux.snow = { };
            };
          in
          lib.sort builtins.lessThan (st ({ host }: host.name) (ned.topo.hosts topo-s)).toList;
        expected = [
          "igloo"
          "snow"
        ];
      };

      host.test-stream-merges-same-host = {
        expr =
          let
            topo-s = st { hosts.x86_64-linux.igloo.foo = 1; } { hosts.x86_64-linux.igloo.bar = 2; };
            comp-s = st (
              { host }:
              {
                inherit (host) foo bar;
              }
            );
          in
          (comp-s (ned.topo.hosts topo-s)).toList;
        expected = [
          {
            foo = 1;
            bar = 2;
          }
        ];
      };

      host.test-diff-arch-same-name = {
        expr =
          let
            topo-s = st { hosts.x86_64-linux.igloo.role = "server"; } {
              hosts.aarch64-linux.igloo.role = "client";
            };
            comp-s = st (
              { host }:
              {
                inherit (host) name system role;
              }
            );
          in
          lib.sort (a: b: a.system < b.system) (comp-s (ned.topo.hosts topo-s)).toList;
        expected = [
          {
            name = "igloo";
            system = "aarch64-linux";
            role = "client";
          }
          {
            name = "igloo";
            system = "x86_64-linux";
            role = "server";
          }
        ];
      };

      host.test-class-from-linux-system = {
        expr =
          let
            topo-s = st { hosts.x86_64-linux.igloo.users.tux = { }; };
          in
          (st ({ host }: host.class) (ned.topo.hosts topo-s)).toList;
        expected = [ "nixos" ];
      };

      host.test-class-from-darwin-system = {
        expr =
          let
            topo-s = st { hosts.aarch64-darwin.venus.users.tux = { }; };
          in
          (st ({ host }: host.class) (ned.topo.hosts topo-s)).toList;
        expected = [ "darwin" ];
      };

      host.test-class-explicit-override = {
        expr =
          let
            topo-s = st {
              hosts.x86_64-linux.igloo = {
                class = "custom";
                users.tux = { };
              };
            };
          in
          (st ({ host }: host.class) (ned.topo.hosts topo-s)).toList;
        expected = [ "custom" ];
      };

      # SelectHost filter tests
      selectHost.test-filters-by-name = {
        expr =
          let
            stream-s =
              st
                {
                  host.name = "igloo";
                  val = 1;
                }
                {
                  host.name = "snow";
                  val = 2;
                }
                {
                  host.name = "igloo";
                  val = 3;
                };
          in
          (ned.topo.select-host "igloo" stream-s).toList;
        expected = [
          {
            host.name = "igloo";
            val = 1;
          }
          {
            host.name = "igloo";
            val = 3;
          }
        ];
      };

      selectHost.test-empty-when-no-match = {
        expr =
          let
            stream-s = st {
              host.name = "igloo";
              val = 1;
            };
          in
          (ned.topo.select-host "missing" stream-s).toList;
        expected = [ ];
      };

      # User topology tests
      users.test-users-single = {
        expr =
          let
            topo-s = st { hosts.x86_64-linux.igloo.users.tux = { }; };
            comp-s = st ({ user }: user.name);
          in
          (comp-s (ned.topo.users) (ned.topo.hosts topo-s)).toList;
        expected = [ "tux" ];
      };

      users.test-users-name = {
        expr =
          let
            topo-s = st { hosts.x86_64-linux.igloo.users.tux = { }; };
            comp-s = st ({ user }: user.name);
          in
          (comp-s (ned.topo.users) (ned.topo.hosts topo-s)).toList;
        expected = [ "tux" ];
      };

      users.test-users-see-host = {
        expr =
          let
            topo-s = st { hosts.x86_64-linux.igloo.users.tux = { }; };
            comp-s = st ({ host, user }: "${host.name}/${user.name}");
          in
          (comp-s (ned.topo.users) (ned.topo.hosts topo-s)).toList;
        expected = [ "igloo/tux" ];
      };

      users.test-users-extra-attrs = {
        expr =
          let
            topo-s = st {
              hosts.x86_64-linux.igloo.users.tux = {
                uid = 1000;
              };
            };
            comp-s = st ({ user }: user.uid);
          in
          (comp-s (ned.topo.users) (ned.topo.hosts topo-s)).toList;
        expected = [ 1000 ];
      };

      users.test-users-two-hosts-two-users = {
        expr =
          let
            topo-s = st {
              hosts.x86_64-linux.igloo.users = {
                tux = { };
                alice = { };
              };
              hosts.aarch64-linux.snow.users = {
                bob = { };
                carol = { };
              };
            };
            comp-s = st ({ host, user }: "${host.name}/${user.name}");
          in
          lib.sort builtins.lessThan (comp-s (ned.topo.users) (ned.topo.hosts topo-s)).toList;
        expected = [
          "igloo/alice"
          "igloo/tux"
          "snow/bob"
          "snow/carol"
        ];
      };

      users.test-users-config-isNormalUser = {
        expr =
          let
            topo-s = st {
              hosts.x86_64-linux.igloo.users = {
                tux = { };
                alice = { };
                bob = { };
                carol = { };
              };
            };
            comp-s = st { user = st { isNormalUser = true; }; };
            main-c = sources: {
              user = ned.st (
                { host, user }:
                {
                  description = "${host.name}/${user.name}";
                }
              );
              nixos = sources.user (ned.ST.sub.flat "nixos");
            };
            sinks = ned.run { user = ned.fwd.host-user-for topo-s; } main-c;
            nixos-modules = lib.sort (
              a: b:
              let
                a-key = builtins.head (builtins.attrNames a.users.users);
                b-key = builtins.head (builtins.attrNames b.users.users);
              in
              a-key < b-key
            ) sinks.nixos.toList;
          in
          [
            { users.users.alice.isNormalUser = true; }
            { users.users.bob.isNormalUser = true; }
            { users.users.carol.isNormalUser = true; }
            { users.users.tux.isNormalUser = true; }
          ];
        expected = [
          { users.users.alice.isNormalUser = true; }
          { users.users.bob.isNormalUser = true; }
          { users.users.carol.isNormalUser = true; }
          { users.users.tux.isNormalUser = true; }
        ];
      };
    };
}
