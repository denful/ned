{
  lib,
  fx,
  config,
  ...
}:
let
  inherit (config.priv) wrap;

  # ---------------------------------------------------------------------------
  # ctxD :: bindings -> compS -> compS
  #
  # Provides constant context values to a stream of contextual computations.
  # Each computation in compS is run with bindings as named effects.
  # ---------------------------------------------------------------------------
  ctxD = bindings: scopeD (fx.effects.scope.handlersFromAttrs bindings);

  # ---------------------------------------------------------------------------
  # scopeD :: handlers -> compS -> compS
  #
  # Provides constant context values to a stream of contextual computations.
  # Each computation in compS is run with bindings as named effects.
  # ---------------------------------------------------------------------------
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
in
{
  priv = { inherit scopeD ctxD; };
}
