{
  lib,
  ned,
  inputs,
  ...
}:
{
  config.flake.tests.drive.ctx =
    let
      inherit (ned) st ST;
    in
    {
      test-provides-single-binding = {
        expr =
          let
            req-s = st ({ host }: host.name);
            res-s = req-s (
              ned.drive.ctx {
                host = {
                  name = "igloo";
                };
              }
            );
          in
          res-s.toList;
        expected = [ "igloo" ];
      };

      test-provides-multiple-bindings = {
        expr =
          let
            req-s = st ({ host, user }: "${host.name}/${user.name}");
            res-s = req-s (
              ned.drive.ctx {
                host = {
                  name = "igloo";
                };
                user = {
                  name = "tux";
                };
              }
            );
          in
          res-s.toList;
        expected = [ "igloo/tux" ];
      };

      test-nested-ctx-rotates-unknown = {
        expr =
          let
            comp-s = st ({ host, user }: "${host.name}/${user.name}");
            res-s =
              comp-s
                (ned.drive.ctx {
                  host = {
                    name = "igloo";
                  };
                })
                (
                  ned.drive.ctx {
                    user = {
                      name = "tux";
                    };
                  }
                );
          in
          res-s.toList;
        expected = [ "igloo/tux" ];
      };
    };
}
