{
  pkgs ? import (import ./templates/ci/with-inputs.nix { }).nixpkgs { },
  ...
}:
pkgs.mkShell {
  buildInputs = [
    pkgs.nix-unit
    pkgs.treefmt
    pkgs.nixfmt
    pkgs.just
    pkgs.nodejs
  ];
}
