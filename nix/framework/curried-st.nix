{ config, ... }:
let
  inherit (config.ned) st;
in
{
  # ---------------------------------------------------------------------------
  # ST :: namespace of curried stream combinators (stream as last param)
  #
  # Enables point-free composition: (ST.apply "fn" arg) as a stream fn
  # ---------------------------------------------------------------------------
  ned.ST = {
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
}
