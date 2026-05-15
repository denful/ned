{
  lib,
  ned,
  ...
}:
{
  config.flake.tests.kernel.st =
    let
      inherit (ned) st when-c;

      # Lens combinators for testing
      focus = getF: setF: {
        get = v: { right = getF v; };
        set = s: v: { right = setF s v; };
      };

      prism = buildF: matchF: {
        get = v: matchF v;
        set = s: v: matchF v;
      };

      # Lenses for field access patterns
      field-lens = name: {
        get =
          obj: if obj ? ${name} then { right = obj.${name}; } else { left = "field '${name}' not found"; };
        set = obj: v: {
          right = obj // {
            ${name} = v;
          };
        };
      };

      # Lens for function application
      apply-fn-lens = fnName: arg: {
        get =
          obj:
          if obj ? ${fnName} then
            { right = obj.${fnName} arg; }
          else
            { left = "function '${fnName}' not found"; };
        set =
          obj: _v:
          if obj ? ${fnName} then
            { right = obj.${fnName} arg; }
          else
            { left = "function '${fnName}' not found"; };
      };

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

      test-get-single-attr = {
        expr =
          let
            multi-s = st {
              nixos = "config1";
              home = "cfg1";
            };
          in
          (multi-s (st.get (field-lens "nixos"))).right.toList;
        expected = [ { right = "config1"; } ];
      };

      test-get-from-stream = {
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
          (multi-s (st.get (field-lens "a"))).right.toList;
        expected = [
          { right = 10; }
          { right = 30; }
        ];
      };

      test-get-curried-combinator = {
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
          (multi-s (st.get (field-lens "x"))).right.toList;
        expected = [
          { right = "foo"; }
          { right = "baz"; }
        ];
      };

      test-get-substream = {
        expr =
          let
            multi-s = st {
              x = st { a = 1; } { a = 2; };
            };
          in
          ((multi-s (st.get (field-lens "x"))).right.flatMap (x: x.right)).toList;
        expected = [
          { a = 1; }
          { a = 2; }
        ];
      };

      test-get-apply = {
        expr =
          let
            multi-s = st {
              f = n: n * 2;
              v = 5;
            };
          in
          (multi-s (st.get (apply-fn-lens "f" 5))).right.toList;
        expected = [ { right = 10; } ];
      };

      test-bend-lens-detection = {
        # lens applied via functor: maps lens.get over stream elements
        expr =
          let
            wrap-either-lens = focus (v: v) (_: v: v);
            result-s = st { value = 42; } (wrap-either-lens);
          in
          result-s.toList;
        expected = [
          {
            right = {
              value = 42;
            };
          }
        ];
      };

      test-lens-right-extractor = {
        expr =
          let
            # Lens that returns Either results
            either-lens = focus (v: v * 2) (_: v: v);
            result-s = st 10 20 30 (either-lens);
          in
          result-s.right.toList;
        expected = [
          { right = 20; }
          { right = 40; }
          { right = 60; }
        ];
      };

      test-lens-left-extractor = {
        expr =
          let
            # Lens that may return errors (left values)
            validate-lens = prism (v: v) (v: if v > 10 then { right = v; } else { left = "too small"; });
            result-s = st 5 15 3 20 (validate-lens);
          in
          result-s.left.toList;
        expected = [
          { left = "too small"; }
          { left = "too small"; }
        ];
      };

      test-non-lens-still-works = {
        # attrset without .set is NOT a lens — emitted as plain value
        expr =
          let
            not-a-lens = {
              get = 42;
            };
            result-s = st 5 (not-a-lens);
          in
          result-s.toList;
        expected = [
          5
          { get = 42; }
        ];
      };

      test-concat-with-lens = {
        # st (lens) on empty stream = empty; concat with s1 = s1's elements
        expr =
          let
            s1 = st { a = 1; };
            wrap-lens = focus (v: { wrapped = v; }) (_: v: v);
            s2 = st (wrap-lens);
          in
          (s1 s2).toList;
        expected = [
          { a = 1; }
        ];
      };

      test-get-composition = {
        expr =
          let
            double = focus (v: v * 2) (_: v: v);
            square = focus (v: v * v) (_: v: v);
            result-s = st 3 4 5 (double) (st.map (x: if x ? right then (square).get x.right else x));
          in
          result-s.right.toList;
        expected = [
          { right = 36; }
          { right = 64; }
          { right = 100; }
        ];
      };

      # when-c: Den policy.when equivalent
      test-when-c-filters-and-maps = {
        expr =
          let
            stream = st.fromList [
              1
              2
              3
              4
              5
            ];
          in
          (when-c (x: x > 3) stream (x: x * 10)).toList;
        expected = [
          40
          50
        ];
      };

      test-when-c-none-match = {
        expr =
          let
            stream = st.fromList [
              1
              2
              3
            ];
          in
          (when-c (x: x > 10) stream (x: x * 10)).toList;
        expected = [ ];
      };

      test-when-c-all-match = {
        expr =
          let
            stream = st.fromList [
              {
                name = "lb";
                role = "lb";
              }
              {
                name = "web";
                role = "web";
              }
            ];
          in
          (when-c (h: h.role == "lb") stream (h: h.name)).toList;
        expected = [ "lb" ];
      };

      # when-c pred runs at construction time — pred may use data from a
      # *different* stream (external check), not the filtered stream itself.
      # Intentional: Ned uses explicit ordering in main-c, not fixpoint iteration.
      test-when-c-external-pred = {
        expr =
          let
            roles = st.fromList [
              "lb"
              "web"
              "web"
            ];
            has-lb = builtins.elem "lb" roles.toList;
            hosts = st.fromList [
              {
                name = "lb-prod";
                role = "lb";
              }
              {
                name = "web-1";
                role = "web";
              }
            ];
          in
          (when-c (h: has-lb && h.role == "web") hosts (h: h.name)).toList;
        expected = [ "web-1" ];
      };

      # when-c composes: chain two when-c calls, each with independent pred.
      test-when-c-composed = {
        expr =
          let
            hosts = st.fromList [
              {
                name = "lb";
                env = "prod";
                role = "lb";
              }
              {
                name = "w1";
                env = "prod";
                role = "web";
              }
              {
                name = "w2";
                env = "staging";
                role = "web";
              }
            ];
            prod-webs = when-c (h: h.env == "prod" && h.role == "web") hosts (h: h.name);
          in
          prod-webs.toList;
        expected = [ "w1" ];
      };

      # st.dedup: drop items with duplicate keys, keep first occurrence
      test-dedup-by-identity = {
        expr = (st.fromList [ 1 2 1 3 2 ] (st.dedup (x: x))).toList;
        expected = [
          1
          2
          3
        ];
      };

      test-dedup-by-key = {
        expr =
          let
            items = [
              {
                name = "a";
                v = 1;
              }
              {
                name = "b";
                v = 2;
              }
              {
                name = "a";
                v = 99;
              }
            ];
          in
          (st.fromList items (st.dedup (x: x.name))).toList;
        expected = [
          {
            name = "a";
            v = 1;
          }
          {
            name = "b";
            v = 2;
          }
        ];
      };

      test-dedup-empty = {
        expr = (st (st.dedup (x: x))).toList;
        expected = [ ];
      };

      test-dedup-all-unique = {
        expr = (st.fromList [ 1 2 3 ] (st.dedup (x: x))).toList;
        expected = [
          1
          2
          3
        ];
      };

      test-dedup-all-same = {
        expr = (st.fromList [ 5 5 5 ] (st.dedup (x: x))).toList;
        expected = [ 5 ];
      };

      # st.flatten: merge stream-of-streams into one stream
      test-flatten-two-streams = {
        expr =
          let
            outer = st.fromList [
              (st.fromList [
                1
                2
              ])
              (st.fromList [
                3
                4
              ])
            ];
          in
          (st.flatten outer).toList;
        expected = [
          1
          2
          3
          4
        ];
      };

      test-flatten-empty-outer = {
        expr = (st.flatten st).toList;
        expected = [ ];
      };

      test-flatten-some-empty-inner = {
        expr =
          let
            outer = st.fromList [
              (st.fromList [ 1 ])
              st
              (st.fromList [
                2
                3
              ])
            ];
          in
          (st.flatten outer).toList;
        expected = [
          1
          2
          3
        ];
      };
    };
}
