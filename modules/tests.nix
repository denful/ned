{
  lib,
  ned,
  inputs,
  ...
}:
{
  options.flake.tests = lib.mkOption { };

  # Tests runnable via `just test <suite>`
  # Each test leaf must start with "test-*"
  #
  # Naming conventions (mirrors ned.nix):
  #   nameS — stream variable
  #   nameD — driver variable
  #   nameC — cycle variable
  #   nameH — handlers variable
  #   nameT - topology variable
  config.flake.tests =
    let
      inherit (ned) st ST;
    in
    {

      # -- st ----------------------------------------------------------

      st = {
        test-plain-value = {
          expr = (st { a = 1; }).toList;
          expected = [ { a = 1; } ];
        };

        test-chain-two-values = {
          expr = (st { a = 1; } { b = 2; }).toList;
          expected = [
            { a = 1; }
            { b = 2; }
          ];
        };

        test-concat-st = {
          expr =
            let
              s1S = st { x = 10; };
              s2S = st { y = 20; };
            in
            (s1S s2S).toList;
          expected = [
            { x = 10; }
            { y = 20; }
          ];
        };

        test-stream-combinator = {
          expr =
            let
              doubledS = st 1 2 (s: s.map (n: n * 2));
            in
            doubledS.toList;
          expected = [
            2
            4
          ];
        };

        test-sel-single-attr = {
          expr =
            let
              multiS = st {
                nixos = "config1";
                home = "cfg1";
              };
            in
            (multiS (s: s.sel "nixos")).toList;
          expected = [ "config1" ];
        };

        test-sel-from-stream = {
          expr =
            let
              multiS =
                st
                  {
                    a = 10;
                    b = 20;
                  }
                  {
                    a = 30;
                    b = 40;
                  };
            in
            (multiS (s: s.sel "a")).toList;
          expected = [
            10
            30
          ];
        };

        test-sel-curried-combinator = {
          expr =
            let
              multiS =
                st
                  {
                    x = "foo";
                    y = "bar";
                  }
                  {
                    x = "baz";
                    y = "qux";
                  };
            in
            (multiS (ST.sel "x")).toList;
          expected = [
            "foo"
            "baz"
          ];
        };

        test-sel-apply = {
          expr =
            let
              multiS = st { f = x: x * 2; } { f = x: x + 10; };
            in
            (multiS (s: s.sel.apply "f" 5)).toList;
          expected = [
            10
            15
          ];
        };

        test-sel-flat = {
          expr =
            let
              multiS = st { a = (st "x" "y"); } { b = "skip"; } { a = (st "z"); };
            in
            (multiS (ST.sel.flat "a")).toList;
          expected = [
            "x"
            "y"
            "z"
          ];
        };
      };

      # -- ned.drive.ctx -------------------------------------------------

      drive.ctx = {
        test-provides-single-binding = {
          expr =
            let
              reqS = st ({ host }: host.name);
              resS = reqS (
                ned.drive.ctx {
                  host = {
                    name = "igloo";
                  };
                }
              );
            in
            resS.toList;
          expected = [ "igloo" ];
        };

        test-provides-multiple-bindings = {
          expr =
            let
              reqS = st ({ host, user }: "${host.name}/${user.name}");
              resS = reqS (
                ned.drive.ctx {
                  host = {
                    name = "igloo";
                  };
                  user = {
                    name = "tux";
                  };
                }
              );
            in
            resS.toList;
          expected = [ "igloo/tux" ];
        };

        test-nested-ctx-rotates-unknown = {
          expr =
            let
              compS = st ({ host, user }: "${host.name}/${user.name}");
              resS =
                compS
                  (ned.drive.ctx {
                    host = {
                      name = "igloo";
                    };
                  })
                  (
                    ned.drive.ctx {
                      user = {
                        name = "tux";
                      };
                    }
                  );
            in
            resS.toList;
          expected = [ "igloo/tux" ];
        };
      };

      # -- ned.run ---------------------------------------------------------

      run = {
        test-no-driver = {
          expr =
            let
              sinks = ned.run { } (_: st { hello = "world"; });
            in
            sinks.toList;
          expected = [ { hello = "world"; } ];
        };

        test-scope-driver-wiring = {
          expr =
            let
              cycleC = sources: {
                nixos = sources.ctx;
                ctx = st ({ host }: host.name);
              };
              sinks = ned.run {
                ctx = ned.drive.ctx {
                  host = {
                    name = "igloo";
                  };
                };
              } cycleC;
            in
            sinks.nixos.toList;
          expected = [ "igloo" ];
        };
      };

      # -- ned.topo.hosts --------------------------------------------------

      topo = {
        host.test-host-name = {
          expr =
            let
              topoS = st { hosts.x86_64-linux.igloo.users.tux = { }; };
            in
            (st ({ host }: host.name) (ned.topo.hosts topoS)).toList;
          expected = [ "igloo" ];
        };

        host.test-host-system = {
          expr =
            let
              topoS = st { hosts.x86_64-linux.igloo.users.tux = { }; };
            in
            (st ({ host }: host.system) (ned.topo.hosts topoS)).toList;
          expected = [ "x86_64-linux" ];
        };

        host.test-host-users = {
          expr =
            let
              topoS = st { hosts.x86_64-linux.igloo.users.tux = { }; };
            in
            (st ({ host }: builtins.attrNames host.users) (ned.topo.hosts topoS)).toList;
          expected = [ [ "tux" ] ];
        };

        host.test-host-object-complete = {
          expr =
            let
              topoS = st { hosts.x86_64-linux.igloo.users.tux = { }; };
            in
            (st (
              { host }:
              {
                inherit (host) name system users;
              }
            ) (ned.topo.hosts topoS)).toList;
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
              topoS = st {
                hosts.x86_64-linux.igloo = {
                  users.tux = { };
                  tags = [ "server" ];
                };
              };
            in
            (st ({ host }: host.tags) (ned.topo.hosts topoS)).toList;
          expected = [ [ "server" ] ];
        };

        host.test-multi-host-fanout = {
          expr =
            let
              topoS = st {
                hosts.x86_64-linux.igloo = { };
                hosts.aarch64-linux.snow = { };
              };
            in
            lib.sort builtins.lessThan (st ({ host }: host.name) (ned.topo.hosts topoS)).toList;
          expected = [
            "igloo"
            "snow"
          ];
        };

        host.test-stream-merges-same-host = {
          expr =
            let
              topoS = st { hosts.x86_64-linux.igloo.foo = 1; } { hosts.x86_64-linux.igloo.bar = 2; };
              compS = st (
                { host }:
                {
                  inherit (host) foo bar;
                }
              );
            in
            (compS (ned.topo.hosts topoS)).toList;
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
              topoS = st { hosts.x86_64-linux.igloo.role = "server"; } {
                hosts.aarch64-linux.igloo.role = "client";
              };
              compS = st (
                { host }:
                {
                  inherit (host) name system role;
                }
              );
            in
            lib.sort (a: b: a.system < b.system) (compS (ned.topo.hosts topoS)).toList;
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
              topoS = st { hosts.x86_64-linux.igloo.users.tux = { }; };
            in
            (st ({ host }: host.class) (ned.topo.hosts topoS)).toList;
          expected = [ "nixos" ];
        };

        host.test-class-from-darwin-system = {
          expr =
            let
              topoS = st { hosts.aarch64-darwin.venus.users.tux = { }; };
            in
            (st ({ host }: host.class) (ned.topo.hosts topoS)).toList;
          expected = [ "darwin" ];
        };

        host.test-class-explicit-override = {
          expr =
            let
              topoS = st {
                hosts.x86_64-linux.igloo = {
                  class = "custom";
                  users.tux = { };
                };
              };
            in
            (st ({ host }: host.class) (ned.topo.hosts topoS)).toList;
          expected = [ "custom" ];
        };

        # -- ned.topo.users ------------------------------------------------

        users.test-users-single = {
          expr =
            let
              topoS = st { hosts.x86_64-linux.igloo.users.tux = { }; };
              compS = st ({ user }: user.name);
            in
            (compS (ned.topo.users) (ned.topo.hosts topoS)).toList;
          expected = [ "tux" ];
        };

        users.test-users-name = {
          expr =
            let
              topoS = st { hosts.x86_64-linux.igloo.users.tux = { }; };
              compS = st ({ user }: user.name);
            in
            (compS (ned.topo.users) (ned.topo.hosts topoS)).toList;
          expected = [ "tux" ];
        };

        users.test-users-see-host = {
          expr =
            let
              topoS = st { hosts.x86_64-linux.igloo.users.tux = { }; };
              compS = st ({ host, user }: "${host.name}/${user.name}");
            in
            (compS (ned.topo.users) (ned.topo.hosts topoS)).toList;
          expected = [ "igloo/tux" ];
        };

        users.test-users-extra-attrs = {
          expr =
            let
              topoS = st {
                hosts.x86_64-linux.igloo.users.tux = {
                  uid = 1000;
                };
              };
              compS = st ({ user }: user.uid);
            in
            (compS (ned.topo.users) (ned.topo.hosts topoS)).toList;
          expected = [ 1000 ];
        };

        users.test-users-two-hosts-two-users = {
          expr =
            let
              topoS = st {
                hosts.x86_64-linux.igloo.users = {
                  tux = { };
                  alice = { };
                };
                hosts.aarch64-linux.snow.users = {
                  bob = { };
                  carol = { };
                };
              };
              compS = st ({ host, user }: "${host.name}/${user.name}");
            in
            lib.sort builtins.lessThan (compS (ned.topo.users) (ned.topo.hosts topoS)).toList;
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
              topoS = st {
                hosts.x86_64-linux.igloo.users = {
                  tux = { };
                  alice = { };
                };
                hosts.aarch64-linux.snow.users = {
                  bob = { };
                  carol = { };
                };
              };

              mainC = sources: {
                user = st { isNormalUser = true; };
                nixos = sources.user (ST.sel "nixos");
              };

              userD = compS: compS (ned.fwd.hostUser) ned.topo.users (ned.topo.hosts topoS);
              nixosModules = (ned.run { user = userD; } mainC).nixos.toList;
            in
            lib.sort (
              a: b:
              let
                aKey = builtins.head (builtins.attrNames a.users.users);
                bKey = builtins.head (builtins.attrNames b.users.users);
              in
              aKey < bKey
            ) nixosModules;
          expected = [
            { users.users.alice.isNormalUser = true; }
            { users.users.bob.isNormalUser = true; }
            { users.users.carol.isNormalUser = true; }
            { users.users.tux.isNormalUser = true; }
          ];
        };
      };

      # -- system integration ----------------------------------------------

      system =
        let
          topoS = st {
            hosts.x86_64-linux.igloo.users.tux = { };
            hosts.aarch64-darwin.venus.users.tux = { };
          };

          mainC = sources: {
            user = st (
              { host, user }:
              {
                description = "${host.name}/${user.name}";
              }
            );
            nixos = sources.user (ST.sel.flat "nixos");
            darwin = sources.user (ST.sel.flat "darwin");
          };

          userD = compS: compS ned.fwd.hostUser ned.topo.users (ned.topo.hosts topoS);
          sinks = ned.run { user = userD; } mainC;
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

    };
}
