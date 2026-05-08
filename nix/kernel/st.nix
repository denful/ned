{ fx, lib, ... }:
let
  # Empty ST — identity for concat, base for chaining: ned.st val1 val2 ...
  st = wrap (fx.stream.done null);

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
    let
      self = {
        __stream = raw-stream;

        __functor =
          _: v:
          if v ? __stream then
            wrap (fx.stream.concat raw-stream v.__stream)
          else if builtins.isFunction v then
            (
              if lib.functionArgs v == { } then
                v self
              else
                wrap (fx.stream.concat raw-stream (fx.stream.fromList [ (fx.bind.fn { } v) ]))
            )
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
          __functor = _: name: wrap (fx.stream.map (attrs: attrs.${name}) raw-stream);
          apply = name: arg: wrap (fx.stream.map (attrs: attrs.${name} arg) raw-stream);
          flat =
            name:
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
  ned = { inherit wrap st; };
}
