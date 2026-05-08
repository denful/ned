{ config, ... }:
let
  inherit (config.priv) osConfigD hostsT;
in
{
  # hostOsD :: topoS -> ST comp -> ST
  # Driver factory: fans out hosts from topoS, wraps results as { host, osConfiguration }.
  priv.hostOsD = topoS: compS: hostsT topoS (osConfigD compS);
}
