help:
  just -l

fmt *args:
  treefmt {{args}}

ci:
  just test
  just fmt --ci

test suite="all" *args:
  nix-unit --expr 'let x = import ./templates/ci/tests.nix; in if "{{suite}}" == "all" then x else x.{{suite}}' {{args}}
