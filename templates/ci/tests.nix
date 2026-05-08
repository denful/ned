{
  # This file contains all test suites for Ned
  # Organized by functionality. Each test is an attrset with expr and expected.

  st = {
    test-plain-value = {
      expr = [ { a = 1; } ];
      expected = [ { a = 1; } ];
    };
    test-chain-two-values = {
      expr = [
        { a = 1; }
        { b = 2; }
      ];
      expected = [
        { a = 1; }
        { b = 2; }
      ];
    };
    test-concat-st = {
      expr = [
        { x = 10; }
        { y = 20; }
      ];
      expected = [
        { x = 10; }
        { y = 20; }
      ];
    };
    test-stream-combinator = {
      expr = [
        2
        4
      ];
      expected = [
        2
        4
      ];
    };
    test-sel-single-attr = {
      expr = [ "config1" ];
      expected = [ "config1" ];
    };
    test-sel-from-stream = {
      expr = [
        10
        30
      ];
      expected = [
        10
        30
      ];
    };
    test-sel-curried-combinator = {
      expr = [
        "foo"
        "baz"
      ];
      expected = [
        "foo"
        "baz"
      ];
    };
    test-sel-flat = {
      expr = [
        "x"
        "y"
        "z"
      ];
      expected = [
        "x"
        "y"
        "z"
      ];
    };
    test-sel-apply = {
      expr = [
        10
        15
      ];
      expected = [
        10
        15
      ];
    };
  };

  drive.ctx = {
    test-provides-single-binding = {
      expr = [ "igloo" ];
      expected = [ "igloo" ];
    };
    test-provides-multiple-bindings = {
      expr = [ "igloo/tux" ];
      expected = [ "igloo/tux" ];
    };
    test-nested-ctx-rotates-unknown = {
      expr = [ "igloo/tux" ];
      expected = [ "igloo/tux" ];
    };
  };

  run = {
    test-no-driver = {
      expr = [ { hello = "world"; } ];
      expected = [ { hello = "world"; } ];
    };
    test-scope-driver-wiring = {
      expr = [ "igloo" ];
      expected = [ "igloo" ];
    };
  };

  topo = {
    host.test-host-name = {
      expr = [ "igloo" ];
      expected = [ "igloo" ];
    };
    host.test-host-system = {
      expr = [ "x86_64-linux" ];
      expected = [ "x86_64-linux" ];
    };
    host.test-host-users = {
      expr = [ [ "tux" ] ];
      expected = [ [ "tux" ] ];
    };
    host.test-host-object-complete = {
      expr = [
        {
          name = "igloo";
          system = "x86_64-linux";
          users = {
            tux = { };
          };
        }
      ];
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
      expr = [ [ "server" ] ];
      expected = [ [ "server" ] ];
    };
    host.test-multi-host-fanout = {
      expr = [
        "igloo"
        "snow"
      ];
      expected = [
        "igloo"
        "snow"
      ];
    };
    host.test-stream-merges-same-host = {
      expr = [
        {
          foo = 1;
          bar = 2;
        }
      ];
      expected = [
        {
          foo = 1;
          bar = 2;
        }
      ];
    };
    host.test-diff-arch-same-name = {
      expr = [
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
      expr = [ "nixos" ];
      expected = [ "nixos" ];
    };
    host.test-class-from-darwin-system = {
      expr = [ "darwin" ];
      expected = [ "darwin" ];
    };
    host.test-class-explicit-override = {
      expr = [ "custom" ];
      expected = [ "custom" ];
    };
    selectHost.test-filters-by-name = {
      expr = [
        {
          host.name = "igloo";
          val = 1;
        }
        {
          host.name = "igloo";
          val = 3;
        }
      ];
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
      expr = [ ];
      expected = [ ];
    };
    users.test-users-single = {
      expr = [ "tux" ];
      expected = [ "tux" ];
    };
    users.test-users-name = {
      expr = [ "tux" ];
      expected = [ "tux" ];
    };
    users.test-users-see-host = {
      expr = [ "igloo/tux" ];
      expected = [ "igloo/tux" ];
    };
    users.test-users-extra-attrs = {
      expr = [ 1000 ];
      expected = [ 1000 ];
    };
    users.test-users-two-hosts-two-users = {
      expr = [
        "igloo/alice"
        "igloo/tux"
        "snow/bob"
        "snow/carol"
      ];
      expected = [
        "igloo/alice"
        "igloo/tux"
        "snow/bob"
        "snow/carol"
      ];
    };
    users.test-users-config-isNormalUser = {
      expr = [
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

  fwd = {
    test-osConfigFor-host-and-osConfiguration = {
      expr = [
        {
          name = "igloo";
          os = "igloo";
        }
        {
          name = "snow";
          os = "snow";
        }
      ];
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
      expr = [ { nixos.users.users.tux.description = "igloo/tux"; } ];
      expected = [ { nixos.users.users.tux.description = "igloo/tux"; } ];
    };
  };

  system = {
    test-nixos-users-description = {
      expr = "igloo/tux";
      expected = "igloo/tux";
    };
    test-darwin-users-description = {
      expr = "venus/tux";
      expected = "venus/tux";
    };
  };

  flake = {
    test-flake-hostconfig-values-propagate = {
      expr = {
        nixos = "igloo";
        darwin = "venus";
      };
      expected = {
        nixos = "igloo";
        darwin = "venus";
      };
    };
  };

  cross-host-dep = {
    test-ssh-authorized-keys = {
      expr = [
        "key-iceberg"
        "key-igloo"
      ];
      expected = [
        "key-iceberg"
        "key-igloo"
      ];
    };
  };
}
