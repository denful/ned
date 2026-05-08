{
  lib,
  fx,
  ...
}:
let
  # ---------------------------------------------------------------------------
  # run :: drivers -> cycle-c -> sinks
  #
  # Cycle.js fixed-point: each source is its driver applied to the matching
  # sink. Nix laziness makes the mutual recursion safe.
  # ---------------------------------------------------------------------------
  run =
    drivers: cycle-c:
    let
      sources = builtins.mapAttrs (name: drv-d: drv-d sinks.${name}) drivers;
      sinks = cycle-c sources;
    in
    sinks;

  # ---------------------------------------------------------------------------
  # ctx-s :: contextual-fn -> st
  #
  # Executes fn after effect-requests for each of its named arguments.
  # Produces a pure computation from fn result. See fx.bind.fn and fx.rotate.
  # ---------------------------------------------------------------------------
  ctx-s = f: fx.stream.fromList [ (fx.bind.fn { } f) ];

  # ---------------------------------------------------------------------------
  # ctx-d :: bindings -> comp-s -> comp-s
  #
  # Provides constant context values to a stream of contextual computations.
  # Each computation in comp-s is run with bindings as named effects.
  # ---------------------------------------------------------------------------
  ctx-d = bindings: scope-d (fx.effects.scope.handlersFromAttrs bindings);

  # ---------------------------------------------------------------------------
  # scopeD :: handlers -> compS -> compS
  #
  # Provides constant context values to a stream of contextual computations.
  # Each computation in compS is run with bindings as named effects.
  # ---------------------------------------------------------------------------
  scope-d =
    handlers: comp-s:
    let
      rot = fx.rotate {
        inherit handlers;
        return = value: _state: value;
      };
      walk-rot =
        stream:
        fx.bind (rot stream) (
          step:
          if step._tag == "Done" then
            fx.stream.done step.value
          else
            fx.stream.more step.head (walk-rot step.tail)
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
              fx.stream.concat (walk-rot inner) (go step.tail)
            )
        );
    in
    wrap (go comp-s.__stream);

  # Empty ST — identity for concat, curried ST.* functions
  st = {
    __stream = fx.stream.done null;
    __functor = (wrap st.__stream).__functor;
    wrap = wrap;
    map = f: self: self.map f;
    filter = f: self: self.filter f;
    flatMap = f: self: self.flatMap f;
    concat = s: self: self.concat s;
    sub = {
      value = name: self: self.sub.value name;
      apply =
        name: value: self:
        self.sub.apply name value;
      __functor =
        _: name: self:
        self.sub name;
    };
  };

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
    raw-stream:
    if raw-stream ? __stream then
      raw-stream
    else
      let
        self = {
          __stream = raw-stream;

          __functor =
            _: v:
            if v ? __stream then
              wrap (fx.stream.concat raw-stream v.__stream)
            else if builtins.isFunction v then
              (if lib.functionArgs v == { } then v self else wrap (fx.stream.concat raw-stream (ctx-s v)))
            else
              wrap (fx.stream.concat raw-stream (fx.stream.fromList [ v ]));

          map = f: wrap (fx.stream.map f raw-stream);
          filter = p: wrap (fx.stream.filter p raw-stream);
          concat = other-s: wrap (fx.stream.concat raw-stream other-s.__stream);

          flatMap =
            f:
            wrap (
              fx.stream.flatMap (
                x:
                let
                  r = f x;
                in
                if r ? __stream then r.__stream else r
              ) raw-stream
            );

          sub = {
            value = name: wrap (fx.stream.map (x: x.${name}) (fx.stream.filter (x: x ? ${name}) raw-stream));
            apply =
              name: value:
              wrap (fx.stream.map (x: x.${name} value) (fx.stream.filter (x: x ? ${name}) raw-stream));
            __functor =
              _: name:
              wrap (
                fx.stream.flatMap (
                  attrs:
                  let
                    raw-or-wrapped = attrs.${name} or st;
                  in
                  if raw-or-wrapped ? __stream then raw-or-wrapped.__stream else fx.stream.fromList [ raw-or-wrapped ]
                ) raw-stream
              );
          };

          toList = (fx.handle { handlers = { }; } (fx.stream.toList raw-stream)).value;
        };
      in
      self;
in
{
  inherit
    run
    st
    ctx-s
    ctx-d
    scope-d
    ;
}
