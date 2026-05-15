{
  config,
  ned,
  inputs,
  ...
}:
let
  inherit (ned) st run;
  inherit (config.fleet-demo)
    host-c
    user-c
    user-hm-c
    user-maid-c
    class-imports-c
    infra-d
    registry-d
    access-c
    nixos-system-d
    ;

  base-modules = [
    {
      boot.loader.grub.enable = false;
      fileSystems."/".device = "/dev/null";
      fileSystems."/".fsType = "tmpfs";
    }
  ];

  # pipe-backends :: [host] -> host -> [{addr, port}]
  # Computes HAProxy backends for lb hosts from env-peers.
  pipe-backends =
    env-hosts: host:
    if host.role == "lb" then
      map (h: {
        addr = h.addr;
        port = h.httpPort;
      }) (builtins.filter (h: h.role == "web") env-hosts)
    else
      [ ];

  # pipe-addrs :: [host] -> [{hostname, addr}]
  # Collects all env-peer hostname→addr pairs for /etc/hosts.
  pipe-addrs =
    env-hosts:
    map (h: {
      hostname = h.name;
      addr = h.addr;
    }) env-hosts;

  # Class forwarder: user → nixos.
  # user entry becomes nixos option users.users.${userName}.
  forward-user =
    {
      hostName,
      userName,
      module,
    }:
    {
      inherit hostName;
      module = {
        users.users.${userName} = module;
      };
    };

  # Class forwarder: homeManager → nixos.
  forward-hm =
    {
      hostName,
      userName,
      module,
    }:
    {
      inherit hostName;
      module = {
        home-manager.users.${userName} = module;
      };
    };

  # Class forwarder: maid → nixos.
  # maid entry becomes nixos option users.users.${userName}.maid.
  forward-maid =
    {
      hostName,
      userName,
      module,
    }:
    {
      inherit hostName;
      module = {
        users.users.${userName}.maid = module;
      };
    };

  # main-c :: sources -> sinks
  # Wires all fleet-demo components. Only file that knows all component names.
  # Sink name = class name. nixos sink carries all {hostName, module} pairs.
  main-c =
    sources:
    let
      granted = access-c sources.infra sources.registry;
      host-nixos = host-c (
        sources.infra (
          st.withPeers (h: h.environment) (
            env-hosts: host:
            st {
              inherit host;
              http-backends = pipe-backends env-hosts host;
              host-addrs = pipe-addrs env-hosts;
            }
          )
        )
      );
      user-stream = user-c granted;
      hm-stream = user-hm-c granted;
      maid-stream = user-maid-c granted;
      user-as-nixos = user-stream (st.map forward-user);
      hm-as-nixos = hm-stream (st.map forward-hm);
      maid-as-nixos = maid-stream (st.map forward-maid);
      # class-imports-c: when-c-based conditional injection per host with class emissions.
      hm-imports = class-imports-c {
        imports = [ inputs.home-manager.nixosModules.home-manager ];
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      } hm-stream sources.infra;
      maid-imports = class-imports-c {
        imports = [ inputs.nix-maid.nixosModules.default ];
      } maid-stream sources.infra;
    in
    {
      infra = st null;
      registry = st null;

      # class sinks: raw {hostName, userName, module} before forwarding.
      user = user-stream;
      homeManager = hm-stream;
      maid = maid-stream;

      # nixos class sink: forwarded class modules + conditional nixos module imports.
      nixos =
        host-nixos (st.concat user-as-nixos) (st.concat hm-as-nixos) (st.concat hm-imports)
          (st.concat maid-as-nixos)
          (st.concat maid-imports);
    };

  result = run {
    infra = infra-d;
    registry = registry-d;
  } main-c;
in
{
  fleet-demo.nixos = result.nixos;
  fleet-demo.user = result.user;
  fleet-demo.homeManager = result.homeManager;
  fleet-demo.maid = result.maid;
  fleet-demo.systems = nixos-system-d base-modules result.nixos;
}
