let
  lock-inputs = import ./templates/ci/with-inputs.nix { };
in
{
  inputs ? lock-inputs,
  lib ? (inputs.nixpkgs or lock-inputs.nixpkgs).lib,
  fx ? import (inputs.nix-effects or lock-inputs.nix-effects) { inherit lib; },
  import-tree ? inputs.import-tree or lock-inputs.import-tree,
  ...
}:
let
  modules = [ (import-tree ./nix) ];
  specialArgs.fx = fx;
  ned = (lib.evalModules { inherit modules specialArgs; }).config.ned;
in
ned
