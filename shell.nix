{
  pkgs ? import <nixpkgs> { },
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
