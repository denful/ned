{ config, ... }:
let
  inherit (config.ned) osConfigD hostsT;
in
{
  # hostOsD :: topoS -> ST comp -> ST
  # Driver factory: fans out hosts from topoS, wraps results as { host, osConfiguration }.
  ned.hostOsD = topoS: compS: hostsT topoS (osConfigD compS);
}
