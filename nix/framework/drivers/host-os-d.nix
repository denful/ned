{ config, ... }:
let
  inherit (config.ned) os-config-d hosts-t;
in
{
  # host-os-d :: topo-s -> ST comp -> ST
  # Driver factory: fans out hosts from topo-s, wraps results as { host, os-configuration }.
  ned.host-os-d = topo-s: comp-s: hosts-t topo-s (os-config-d comp-s);
}
