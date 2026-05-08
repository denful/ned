{ config, ... }:
let
  inherit (config.ned) hostUserD hostsT usersT;
in
{
  # hostUsersD :: topoS -> ST comp -> ST
  # Driver factory: fans out hosts then users from topoS, maps output per user.
  ned.hostUsersD = topoS: compS: hostsT topoS (usersT (hostUserD compS));
}
