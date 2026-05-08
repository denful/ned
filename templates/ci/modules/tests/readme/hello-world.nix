# Simple hello-world example showcases a single computation running
# on different evironments (effect context).
{
  lib,
  ned,
  ci,
  ...
}:
let
  inherit (ned) run st ctx-d;

  # language contextual drivers
  en-d = ctx-d {
    hello = "hello";
    world = "world";
  };
  sp-d = ctx-d {
    hello = "hola";
    world = "mundo";
  };

  # stream of contextual computations
  comp-s = middle: st ({ hello }: hello) middle ({ world }: world) ({ hello }: hello);

  english = comp-s st en-d;
  spanglish = comp-s en-d sp-d;

  expr = {
    english = lib.concatStringsSep " " english.toList;
    spanglish = lib.concatStringsSep " " spanglish.toList;
  };
  expected = {
    english = "hello world hello";
    spanglish = "hello mundo hola";
  };
in
{
  flake.tests.readme.test-hello-world = { inherit expr expected; };
}
