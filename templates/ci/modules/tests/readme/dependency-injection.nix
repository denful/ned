# Shows dependency-injection (via effect-rotation) by using nested effect handlers.
{
  lib,
  ned,
  ...
}:
let
  inherit (ned) run st ctx-d;

  # ctx-d is for constant handlers, use scope-d for advanced effect handling.
  host-d = ctx-d { host = "igloo"; };
  user-d = ctx-d { user = "tux"; };

  # an stream of effectful computations.
  # here params are effect-requests solved by handlers
  comp-s = st ({ host, user }: "${user}@${host}");

  # runs computation wrapped in `user` wrapped in `host` effect handlers.
  main = comp-s user-d host-d;

  expr = main.toList;
  expected = [ "tux@igloo" ];
in
{
  flake.tests.readme.test-effect-rotation = { inherit expr expected; };
}
