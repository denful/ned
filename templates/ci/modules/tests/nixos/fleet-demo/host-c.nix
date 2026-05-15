{ ned, lib, ... }:
let
  inherit (ned) st map-c;

  haproxy-config =
    backends:
    lib.concatStringsSep "\n" (
      [
        "frontend http-in"
        "  bind *:80"
        "  default_backend webservers"
        ""
        "backend webservers"
        "  balance roundrobin"
      ]
      ++ lib.imap1 (i: b: "  server backend${toString i} ${b.addr}:${toString b.port} check") backends
    );

  extra-hosts = host-addrs: lib.concatMapStringsSep "\n" (e: "${e.addr} ${e.hostname}") host-addrs;

  nixos-config =
    {
      host,
      http-backends,
      host-addrs,
    }:
    {
      hostName = host.name;
      module = {
        nixpkgs.hostPlatform = host.system;
        networking.hostName = host.name;
        networking.extraHosts = extra-hosts host-addrs;
      }
      // lib.optionalAttrs (host.role == "lb") {
        services.haproxy.enable = true;
        services.haproxy.config = haproxy-config http-backends;
      }
      // lib.optionalAttrs (host.role == "web") {
        services.nginx.enable = true;
      };
    };
in
{
  # host-c :: ST {host, http-backends, host-addrs} -> ST {hostName, module}
  fleet-demo.host-c = map-c nixos-config;
}
