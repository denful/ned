{
  lib,
  ned,
  inputs,
  ...
}:
{
  config.flake.tests.run =
    let
      inherit (ned) st ST;
    in
    {
      test-no-driver = {
        expr =
          let
            sinks = ned.run { } (_: st { hello = "world"; });
          in
          sinks.toList;
        expected = [ { hello = "world"; } ];
      };

      test-scope-driver-wiring = {
        expr =
          let
            cycle-c = sources: {
              nixos = sources.ctx;
              ctx = st ({ host }: host.name);
            };
            sinks = ned.run {
              ctx = ned.drive.ctx {
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
