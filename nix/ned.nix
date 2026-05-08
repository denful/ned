{
  lib,
  fx,
  config,
  ...
}:
let
  inherit (config.ned)
    run
    st
    wrap
    ST
    scope-d
    ctx-d
    hosts-t
    users-t
    host-user-d
    host-users-d
    select-host-d
    os-config-d
    host-os-d
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
    drive.ctx = ctx-d;
    drive.scope = scope-d;
    topo.hosts = hosts-t;
    topo.users = users-t;
    topo.selectHost = select-host-d;
    fwd.hostUser = host-user-d;
    fwd.osConfig = os-config-d;
    fwd.osConfigFor = host-os-d;
    fwd.hostUserFor = host-users-d;
  };

in
{
  options.ned = lib.mkOption {
    type = lib.types.submodule {
      freeformType = lib.types.lazyAttrsOf lib.types.unspecified;
    };
  };

  options.API = lib.mkOption { };
  config.API = API;
}
