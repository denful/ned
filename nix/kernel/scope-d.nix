{
  lib,
  fx,
  config,
  ...
}:
let
  inherit (config.ned) wrap;

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
in
{
  ned = { inherit scope-d ctx-d; };
}
