{ lib, fx, ... }:
let
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

  # ---------------------------------------------------------------------------
  # wrap :: fx.stream -> ST
  #
  # Wraps a raw fx.stream as an ST with a fluent functor API.
  # Calling the result as a functor chains additional values:
  #
  #   st other-ST          → concat
  #   st (s: ...)          → stream combinator  (lib.functionArgs = {}, s = self)
  #   st ({ host }: ...)   → contextual fn      (lib.functionArgs non-empty)
  #   st plain-value       → emit as single element
  #
  # flatMap accepts f returning either a raw fx.stream or an ST —
  # callers never need to touch .__stream.
  # ---------------------------------------------------------------------------
  wrap =
    rawStream:
    let
      self = {
        __stream = rawStream;

        __functor =
          _: v:
          if v ? __stream then
            wrap (fx.stream.concat rawStream v.__stream)
          else if builtins.isFunction v then
            (
              if lib.functionArgs v == { } then
                v self
              else
                wrap (fx.stream.concat rawStream (fx.stream.fromList [ (fx.bind.fn { } v) ]))
            )
          else
            wrap (fx.stream.concat rawStream (fx.stream.fromList [ v ]));

        map = f: wrap (fx.stream.map f rawStream);
        filter = p: wrap (fx.stream.filter p rawStream);
        concat = otherS: wrap (fx.stream.concat rawStream otherS.__stream);

        flatMap =
          f:
          wrap (
            fx.stream.flatMap (
              x:
              let
                r = f x;
              in
              if r ? __stream then r.__stream else r
            ) rawStream
          );

        sub = {
          __functor = _: name: wrap (fx.stream.map (attrs: attrs.${name}) rawStream);
          apply = name: arg: wrap (fx.stream.map (attrs: attrs.${name} arg) rawStream);
          flat =
            name:
            wrap (
              fx.stream.flatMap (
                attrs:
                let
                  rawOrWrapped = attrs.${name} or st;
                in
                if rawOrWrapped ? __stream then rawOrWrapped.__stream else fx.stream.fromList [ rawOrWrapped ]
              ) rawStream
            );
        };

        toList = (fx.handle { handlers = { }; } (fx.stream.toList rawStream)).value;
      };
    in
    self;

  # Empty ST — identity for concat, base for chaining: ned.st val1 val2 ...
  st = wrap (fx.stream.done null);

  # ---------------------------------------------------------------------------
  # ST :: namespace of curried stream combinators (stream as last param)
  #
  # Enables point-free composition: (ST.apply "fn" arg) as a stream fn
  # ---------------------------------------------------------------------------
  ST = {
    __functor = _: st;
    map = f: stream: stream.map f;
    filter = p: stream: stream.filter p;
    concat = otherS: stream: stream.concat otherS;
    flatMap = f: stream: stream.flatMap f;
    sub = {
      __functor =
        _: name: stream:
        stream.sub name;
      apply =
        name: value: stream:
        stream.sub.apply name value;
      flat = name: stream: stream.sub.flat name;
    };
  };

  # ---------------------------------------------------------------------------
  # ctxD :: bindings -> ST comp -> ST result
  #
  # Provides constant context values to a stream of contextual computations.
  # Each computation in compS is run with bindings as named effects.
  # ---------------------------------------------------------------------------
  ctxD = bindings: scopeD (fx.effects.scope.handlersFromAttrs bindings);
  scopeD =
    handlers: compS:
    let
      rot = fx.rotate {
        inherit handlers;
        return = value: _state: value;
      };
      walkRot =
        stream:
        fx.bind (rot stream) (
          step:
          if step._tag == "Done" then
            fx.stream.done step.value
          else
            fx.stream.more step.head (walkRot step.tail)
        );
      go =
        stream:
        fx.bind (rot stream) (
          step:
          if step._tag == "Done" then
            fx.stream.done step.value
          else
            let
              comp = if fx.isComp step.head then step.head else fx.pure step.head;
            in
            fx.bind (rot comp) (
              val:
              let
                inner = if val ? __stream then val.__stream else fx.stream.fromList [ val ];
              in
              fx.stream.concat (walkRot inner) (go step.tail)
            )
        );
    in
    wrap (go compS.__stream);

  # ---------------------------------------------------------------------------
  # run :: drivers -> cycleC -> sinks
  #
  # Cycle.js fixed-point: each source is its driver applied to the matching
  # sink. Nix laziness makes the mutual recursion safe.
  # ---------------------------------------------------------------------------
  run =
    drivers: cycleC:
    let
      sources = builtins.mapAttrs (name: driverD: driverD sinks.${name}) drivers;
      sinks = cycleC sources;
    in
    sinks;

  # ---------------------------------------------------------------------------
  # topo.hosts :: ST topology -> ST comp -> ST result
  #
  # Fan-out driver over topology hosts.
  # Topology shape: { hosts.${system}.${name} = { ...hostAttrs... }; }
  #
  # Builds host objects: { name, system } // hostAttrs
  # Merges host attrs across topologies by (system, name)
  # Scopes compS with { host = hostObj; } via ctxD per host.
  # Concatenates all per-host result streams — never materialises to list.
  # ---------------------------------------------------------------------------
  hostsT =
    topoS: compS:
    let
      topologies = topoS.toList;
      hostsByKey = lib.foldl' (
        acc: topo:
        lib.foldlAttrs (
          acc2: sys: sysAttrs:
          lib.foldlAttrs (
            acc3: name: hostAttrs:
            let
              key = "${sys}/${name}";
            in
            acc3
            // {
              ${key} = if acc3 ? ${key} then lib.recursiveUpdate acc3.${key} hostAttrs else hostAttrs;
            }
          ) acc2 sysAttrs
        ) acc (topo.hosts or { })
      ) { } topologies;

      hosts = builtins.map (
        key:
        let
          parts = lib.splitString "/" key;
          system = builtins.elemAt parts 0;
          hostAttrs = hostsByKey.${key};
        in
        {
          name = builtins.elemAt parts 1;
          inherit system;
          class = hostAttrs.class or (if lib.hasSuffix "darwin" system then "darwin" else "nixos");
        }
        // hostAttrs
      ) (builtins.attrNames hostsByKey);
    in
    (wrap (fx.stream.fromList hosts)).flatMap (host: ctxD { inherit host; } compS);

  # ---------------------------------------------------------------------------
  # topo.users :: compS -> compS
  #
  # Contextual fan-out driver over a host's users.
  # Must be used inside a host scope (hostsT), which provides `host`.
  #
  # Wraps compS as a single contextual computation that:
  #   1. reads `host` from the active scope (sent by hostsT's ctxD)
  #   2. iterates host.users, building user objects: { name } // userAttrs
  #   3. scopes compS with { user } for each user via ctxD
  #   4. returns the concatenated per-user ST
  #
  # Inner ctxD provides both host AND user together because of fx.rotate
  # ---------------------------------------------------------------------------
  usersT =
    compS:
    st (
      { host }:
      let
        users = lib.mapAttrsToList (name: attrs: { inherit name; } // attrs) (host.users or { });
      in
      builtins.foldl' (accS: user: accS (ctxD { inherit user; } compS)) st users
    );

  # hostUserD :: ST comp -> ST comp
  #
  # Driver: reads active host+user scope, maps each config item to
  # { <host.class>.users.users.<user.name> = attrs }. Class-agnostic —
  # works for nixos, darwin, or any host class without modification.
  hostUserD =
    compS:
    st (
      { host, user }:
      (ctxD { inherit host user; } compS).map (attrs: {
        ${host.class} = {
          users.users.${user.name} = attrs;
        };
      })
    );

  # osConfigD :: ST comp -> ST comp
  #
  # Contextual driver: reads active host scope, applies component to build
  # osConfiguration (via nixpkgs.lib.nixosSystem or nix-darwin.lib.darwinSystem).
  # Maps result to { host, osConfiguration } for downstream grouping.
  osConfigD =
    compS:
    st (
      { host }:
      (ctxD { inherit host; } compS).map (osConfiguration: {
        inherit host osConfiguration;
      })
    );

  # selectHostS :: name -> ST -> ST
  # Filter stream of { host, … } items to those where host.name == name.
  selectHostS = name: streamS: streamS.filter (item: item.host.name == name);

  # osConfigForD :: topoS -> ST comp -> ST
  # Driver factory: fans out hosts from topoS, wraps results as { host, osConfiguration }.
  osConfigForD = topoS: compS: hostsT topoS (osConfigD compS);

  # hostUserForD :: topoS -> ST comp -> ST
  # Driver factory: fans out hosts then users from topoS, maps output per user.
  hostUserForD = topoS: compS: hostsT topoS (usersT (hostUserD compS));

  ned = {
    inherit ST st run;
    drive.ctx = ctxD;
    drive.scope = scopeD;
    topo.hosts = hostsT;
    topo.users = usersT;
    topo.selectHost = selectHostS;
    fwd.hostUser = hostUserD;
    fwd.osConfig = osConfigD;
    fwd.osConfigFor = osConfigForD;
    fwd.hostUserFor = hostUserForD;
  };

in
{
  options.ned = lib.mkOption { type = lib.types.lazyAttrsOf lib.types.unspecified; };
  config.ned = ned;
}
