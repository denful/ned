{
  lib,
  fx,
  config,
  ...
}:
let
  inherit (config.priv)
    run
    st
    wrap
    ST
    scopeD
    ctxD
    hostsT
    usersT
    hostUserD
    hostUsersD
    selectHostD
    osConfigD
    hostOsD
    ;

  # ===========================================================================
  # CONVENTIONS — enforced throughout this file and all ned modules
  #
  #   nameS  — variable holds an ST (wrapped fx stream)
  #   nameD  — variable holds a driver  (ST -> ST)
  #   nameC  — variable holds a cycle   (sources -> sinks)
  #   nameH  — variable holds fx handlers attrset
  #   nameT  - variable holds a Topology Transformation (most likely a Driver)
  #
  # Never call fx.stream.* directly on .__stream at a call site.
  # Use the ST fluent API (s.map, s.flatMap, s.filter, s.concat) instead.
  # .__stream is only accessed INSIDE wrap to build the ST API itself.
  #
  # Never call .toList in library code — .toList is for end users only.
  # ===========================================================================

  API = {
    inherit ST st run;
    drive.ctx = ctxD;
    drive.scope = scopeD;
    topo.hosts = hostsT;
    topo.users = usersT;
    topo.selectHost = selectHostD;
    fwd.hostUser = hostUserD;
    fwd.osConfig = osConfigD;
    fwd.osConfigFor = hostOsD;
    fwd.hostUserFor = hostUsersD;
  };

in
{
  options.priv = lib.mkOption {
    type = lib.types.submodule {
      freeformType = lib.types.lazyAttrsOf lib.types.unspecified;
    };
  };

  options.API = lib.mkOption { };
  config.API = API;
}
