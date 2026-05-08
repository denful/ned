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
in
{
  ned = { inherit wrap st; };
}
