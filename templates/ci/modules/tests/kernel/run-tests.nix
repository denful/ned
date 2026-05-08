{
  lib,
  ned,
  ...
}:
{
  flake.tests.kernel.run = {
    test-no-driver = {
      expr =
        let
          sinks = ned.run { } (_: ned.st { hello = "world"; });
        in
        sinks.toList;
      expected = [ { hello = "world"; } ];
    };

    test-scope-driver-wiring = {
      expr =
        let
          cycle-c = sources: {
            nixos = sources.ctx;
            ctx = ned.st ({ host }: host.name);
          };
          sinks = ned.run {
            ctx = ned.ctx-d {
              host = {
                name = "igloo";
              };
            };
          } cycle-c;
        in
        sinks.nixos.toList;
      expected = [ "igloo" ];
    };
  };
}
