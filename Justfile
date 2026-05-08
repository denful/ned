help:
  just -l

fmt *args:
  treefmt {{args}}

ci:
  just fmt --ci --no-cache
  just test

noflake attr="nixosConfigurations.igloo.config.system.build.toplevel" *args:
  cd templates/noflake && nix-build --no-out-link --arg ned 'import ../ci/ned.nix' ./default.nix -A {{attr}} {{args}}

test suite="all" *args:
  nix-unit --expr 'let x = import ./templates/ci/tests.nix; in if "{{suite}}" == "all" then x else x.{{suite}}' {{args}}
