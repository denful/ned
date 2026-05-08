# Shows effect-rotation (fx.rotate) by using nested effect handlers.
{
  lib,
  ned,
  ci,
  ...
}:
let
  inherit (ned) run st ctx-d;

  host-d = ctx-d { host = "igloo"; };
  user-d = ctx-d { user = "tux"; };

  # both host and user are effect requests
  comp-s = st ({ host, user }: "${user}@${host}");

  # runs computation wrapped in user wrapped in host contexts.
  main = comp-s user-d host-d;

  expr = main.toList;
  expected = [ "tux@igloo" ];
in
{
  flake.tests.readme.test-effect-rotation = { inherit expr expected; };
}
