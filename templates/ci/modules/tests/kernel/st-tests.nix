{
  lib,
  ned,
  ...
}:
{
  config.flake.tests.kernel.st =
    let
      inherit (ned) st;
    in
    {
      test-plain-value = {
        expr = (st { a = 1; }).toList;
        expected = [ { a = 1; } ];
      };

      test-chain-two-values = {
        expr = (st { a = 1; } { b = 2; }).toList;
        expected = [
          { a = 1; }
          { b = 2; }
        ];
      };

      test-concat-st = {
        expr =
          let
            s1-s = st { x = 10; };
            s2-s = st { y = 20; };
          in
          (s1-s s2-s).toList;
        expected = [
          { x = 10; }
          { y = 20; }
        ];
      };

      test-stream-combinator = {
        expr =
          let
            doubled-s = st 1 2 (st.map (n: n * 2));
          in
          doubled-s.toList;
        expected = [
          2
          4
        ];
      };

      test-sel-single-attr = {
        expr =
          let
            multi-s = st {
              nixos = "config1";
              home = "cfg1";
            };
          in
          (multi-s (st.sub.value "nixos")).toList;
        expected = [ "config1" ];
      };

      test-sel-from-stream = {
        expr =
          let
            multi-s =
              st
                {
                  a = 10;
                  b = 20;
                }
                {
                  a = 30;
                  b = 40;
                };
          in
          (multi-s (st.sub.value "a")).toList;
        expected = [
          10
          30
        ];
      };

      test-sel-curried-combinator = {
        expr =
          let
            multi-s =
              st
                {
                  x = "foo";
                  y = "bar";
                }
                {
                  x = "baz";
                  y = "qux";
                };
          in
          (multi-s (st.sub.value "x")).toList;
        expected = [
          "foo"
          "baz"
        ];
      };

      test-sel-substream = {
        expr =
          let
            multi-s = st {
              x = st { a = 1; } { a = 2; };
            };
          in
          (multi-s (st.sub "x")).toList;
        expected = [
          { a = 1; }
          { a = 2; }
        ];
      };

      test-sel-apply = {
        expr =
          let
            multi-s = st {
              f = n: n * 2;
              v = 5;
            };
          in
          (multi-s (st.sub.apply "f" 5)).toList;
        expected = [ 10 ];
      };
    };
}
