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
  # NAMING — enforced throughout this file and all ned modules
  #
  #   All identifiers use kebab-case with type suffixes:
  #   - name-s  — variable holds an ST (wrapped fx stream)
  #   - name-d  — variable holds a driver  (ST -> ST)
  #   - name-c  — variable holds a cycle   (sources -> sinks)
  #   - name-h  — variable holds fx handlers attrset
  #   - name-t  — variable holds a Topology Transformation
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
    topo.select-host = select-host-d;
    fwd.host-user = host-user-d;
    fwd.os-config = os-config-d;
    fwd.os-config-for = host-os-d;
    fwd.host-user-for = host-users-d;
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
