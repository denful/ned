# Shows cycle composition: outer cycle delegates to inner cycle.
# Inner sink propagates through outer and is received by the driver.
{
  lib,
  ned,
  ci,
  ...
}:
let
  inherit (ned) run st;

  # seed driver: ignores sink, provides fixed source data [1, 2, 3]
  seed-d = _: st 1 2 3;

  # inner cycle: doubles each element
  inner-c =
    { x, ... }:
    {
      x = x.map (i: i * 2);
    };

  # outer cycle: scales by 100, delegates to inner, then scales by 3 on sink
  outer-c =
    { x, ... }:
    let
      inner = inner-c { x = x.map (i: i + 100); };
    in
    {
      x = inner.x.map (i: i * 3);
    };

  drivers = {
    x = seed-d;
  };
  done = run drivers outer-c;

  expr = {
    x = done.x.toList;
  };
  expected = {
    x = [
      606
      612
      618
    ];
  };
in
{
  flake.tests.readme.test-nested-cycles = { inherit expr expected; };
}
