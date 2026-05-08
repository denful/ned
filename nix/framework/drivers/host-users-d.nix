{ config, ... }:
let
  inherit (config.ned) host-user-d hosts-t users-t;
in
{
  # host-users-d :: topo-s -> ST comp -> ST
  # Driver factory: fans out hosts then users from topo-s, maps output per user.
  ned.host-users-d = topo-s: comp-s: hosts-t topo-s (users-t (host-user-d comp-s));
}
