# Fleet-demo test assertions.
# Consumes nixos systems from main-c via config.fleet-demo.systems.
# No wiring, no component references, no hardcoded host lists.
{ config, lib, ... }:
let
  inherit (config.fleet-demo) systems;

  lb-prod = systems.lb-prod;
  web-prod-1 = systems.web-prod-1;
  web-prod-2 = systems.web-prod-2;
  web-staging = systems.web-staging;
  monitor = systems.monitor;

in
{
  flake.tests.nixos.fleet-demo.test-lb-prod-haproxy-backends = {
    expr =
      lib.hasInfix "10.0.0.2:8080" lb-prod.services.haproxy.config
      && lib.hasInfix "10.0.0.3:8080" lb-prod.services.haproxy.config;
    expected = true;
  };

  flake.tests.nixos.fleet-demo.test-lb-prod-no-staging-backend = {
    expr = lib.hasInfix "10.1.0.1" lb-prod.services.haproxy.config;
    expected = false;
  };

  flake.tests.nixos.fleet-demo.test-lb-prod-hosts-file = {
    expr =
      lib.hasInfix "10.0.0.1 lb-prod" lb-prod.networking.extraHosts
      && lib.hasInfix "10.0.0.2 web-prod-1" lb-prod.networking.extraHosts
      && lib.hasInfix "10.0.0.3 web-prod-2" lb-prod.networking.extraHosts;
    expected = true;
  };

  flake.tests.nixos.fleet-demo.test-lb-prod-no-staging-hosts = {
    expr = lib.hasInfix "10.1.0.1" lb-prod.networking.extraHosts;
    expected = false;
  };

  flake.tests.nixos.fleet-demo.test-web-prod-1-nginx = {
    expr = {
      nginx = web-prod-1.services.nginx.enable;
      haproxy = web-prod-1.services.haproxy.enable;
    };
    expected = {
      nginx = true;
      haproxy = false;
    };
  };

  flake.tests.nixos.fleet-demo.test-staging-env-isolation = {
    expr =
      lib.hasInfix "10.1.0.1 web-staging" web-staging.networking.extraHosts
      && !(lib.hasInfix "10.0.0" web-staging.networking.extraHosts);
    expected = true;
  };

  flake.tests.nixos.fleet-demo.test-alice-on-prod = {
    expr = lb-prod.users.users.alice.openssh.authorizedKeys.keys;
    expected = [ "ssh-ed25519 AAAlice" ];
  };

  flake.tests.nixos.fleet-demo.test-alice-on-staging = {
    expr = web-staging.users.users.alice.openssh.authorizedKeys.keys;
    expected = [ "ssh-ed25519 AAAlice" ];
  };

  flake.tests.nixos.fleet-demo.test-bob-on-staging = {
    expr = web-staging.users.users.bob.openssh.authorizedKeys.keys;
    expected = [ "ssh-ed25519 AAABob" ];
  };

  flake.tests.nixos.fleet-demo.test-bob-not-on-prod = {
    expr = lb-prod.users.users ? bob;
    expected = false;
  };

  # by-host: charlie (ops) granted lb-prod only, not env-wide
  flake.tests.nixos.fleet-demo.test-charlie-on-lb-prod = {
    expr = lb-prod.users.users.charlie.openssh.authorizedKeys.keys;
    expected = [ "ssh-ed25519 AAACharlie" ];
  };

  flake.tests.nixos.fleet-demo.test-charlie-not-on-web-prod-1 = {
    expr = web-prod-1.users.users ? charlie;
    expected = false;
  };

  flake.tests.nixos.fleet-demo.test-charlie-not-on-web-prod-2 = {
    expr = web-prod-2.users.users ? charlie;
    expected = false;
  };

  flake.tests.nixos.fleet-demo.test-charlie-not-on-staging = {
    expr = web-staging.users.users ? charlie;
    expected = false;
  };

  # SSH key isolation: each user has only their own key, no cross-contamination
  flake.tests.nixos.fleet-demo.test-alice-key-isolation-lb-prod = {
    expr = {
      has-alice-key = builtins.elem "ssh-ed25519 AAAlice" lb-prod.users.users.alice.openssh.authorizedKeys.keys;
      no-bob-key =
        !(builtins.elem "ssh-ed25519 AAABob" lb-prod.users.users.alice.openssh.authorizedKeys.keys);
      no-charlie-key =
        !(builtins.elem "ssh-ed25519 AAACharlie" lb-prod.users.users.alice.openssh.authorizedKeys.keys);
    };
    expected = {
      has-alice-key = true;
      no-bob-key = true;
      no-charlie-key = true;
    };
  };

  flake.tests.nixos.fleet-demo.test-charlie-key-isolation-lb-prod = {
    expr = {
      has-charlie-key = builtins.elem "ssh-ed25519 AAACharlie" lb-prod.users.users.charlie.openssh.authorizedKeys.keys;
      no-alice-key =
        !(builtins.elem "ssh-ed25519 AAAlice" lb-prod.users.users.charlie.openssh.authorizedKeys.keys);
      no-bob-key =
        !(builtins.elem "ssh-ed25519 AAABob" lb-prod.users.users.charlie.openssh.authorizedKeys.keys);
    };
    expected = {
      has-charlie-key = true;
      no-alice-key = true;
      no-bob-key = true;
    };
  };

  flake.tests.nixos.fleet-demo.test-bob-key-isolation-staging = {
    expr = {
      has-bob-key = builtins.elem "ssh-ed25519 AAABob" web-staging.users.users.bob.openssh.authorizedKeys.keys;
      no-alice-key =
        !(builtins.elem "ssh-ed25519 AAAlice" web-staging.users.users.bob.openssh.authorizedKeys.keys);
    };
    expected = {
      has-bob-key = true;
      no-alice-key = true;
    };
  };

  # homeManager class → nixos class forwarding assertions.
  # Verifies forward-hm correctly routes hm modules under home-manager.users.${userName}.

  flake.tests.nixos.fleet-demo.test-hm-alice-git-on-lb-prod = {
    expr = lb-prod.home-manager.users.alice.programs.git.enable;
    expected = true;
  };

  flake.tests.nixos.fleet-demo.test-hm-alice-git-on-staging = {
    expr = web-staging.home-manager.users.alice.programs.git.enable;
    expected = true;
  };

  flake.tests.nixos.fleet-demo.test-hm-bob-vim-on-staging = {
    expr = web-staging.home-manager.users.bob.programs.vim.enable;
    expected = true;
  };

  flake.tests.nixos.fleet-demo.test-hm-bob-not-on-prod = {
    # bob has no access to prod → no HM config on prod either
    expr = lb-prod.home-manager.users ? bob;
    expected = false;
  };

  flake.tests.nixos.fleet-demo.test-hm-charlie-not-configured = {
    # charlie has ssh access to lb-prod but no hm field → no homeManager entry
    expr = lb-prod.home-manager.users ? charlie;
    expected = false;
  };

  flake.tests.nixos.fleet-demo.test-hm-no-cross-contamination = {
    # alice's hm config does not bleed into bob's namespace and vice versa
    expr = {
      alice-has-git = lb-prod.home-manager.users.alice.programs.git.enable;
      alice-no-vim = !(lb-prod.home-manager.users.alice.programs.vim.enable);
    };
    expected = {
      alice-has-git = true;
      alice-no-vim = true;
    };
  };

  # maid class → nixos class forwarding assertions.
  # forward-maid routes maid modules to users.users.${userName}.maid on the host.

  flake.tests.nixos.fleet-demo.test-maid-charlie-greet-on-lb-prod = {
    # charlie has maid field → forwarded to users.users.charlie.maid on lb-prod
    expr = lb-prod.users.users.charlie.maid.file.home."greet".text;
    expected = "hello charlie";
  };

  flake.tests.nixos.fleet-demo.test-maid-alice-null-on-lb-prod = {
    # alice uses homeManager class, not maid → users.users.alice.maid is null
    expr = lb-prod.users.users.alice.maid;
    expected = null;
  };

  flake.tests.nixos.fleet-demo.test-maid-class-isolation = {
    # maid and homeManager are distinct classes — charlie's maid does not appear in HM
    expr = lb-prod.home-manager.users ? charlie;
    expected = false;
  };

  # class-imports-c: conditional nixos module inclusion based on class emissions.

  flake.tests.nixos.fleet-demo.test-hm-module-on-lb-prod = {
    # lb-prod has alice (hm) → homeManager class emits → HM nixos module imported
    expr = builtins.hasAttr "home-manager" lb-prod;
    expected = true;
  };

  flake.tests.nixos.fleet-demo.test-maid-module-on-lb-prod = {
    # lb-prod has charlie (maid) → maid class emits → nix-maid nixos module imported
    expr = builtins.hasAttr "maid" lb-prod;
    expected = true;
  };

  flake.tests.nixos.fleet-demo.test-maid-module-absent-on-web-prod-1 = {
    # web-prod-1 has only alice (hm, no maid) → maid class no emissions → no nix-maid module
    expr = builtins.hasAttr "maid" web-prod-1;
    expected = false;
  };

  flake.tests.nixos.fleet-demo.test-no-class-modules-on-monitor = {
    # monitor has no user access grants → no class emissions → no HM, no maid module
    expr = {
      has-hm = builtins.hasAttr "home-manager" monitor;
      has-maid = builtins.hasAttr "maid" monitor;
    };
    expected = {
      has-hm = false;
      has-maid = false;
    };
  };

  flake.tests.nixos.fleet-demo.test-monitor-has-no-users = {
    expr = {
      no-alice = !(monitor.users.users ? alice);
      no-charlie = !(monitor.users.users ? charlie);
    };
    expected = {
      no-alice = true;
      no-charlie = true;
    };
  };
}
