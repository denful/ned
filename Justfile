help:
  just -l

fmt:
  treefmt

ci:
  just test

test suite="":
  nix-unit --flake .#tests.{{suite}}
