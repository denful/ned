{
  inputs ? import ./templates/ci/with-inputs.nix { },
  lib ? inputs.nixpkgs.lib,
  fx ? import inputs.nix-effects { inherit lib; },
  import-tree ? inputs.import-tree,
  ...
}:
let
  modules = [ (import-tree ./nix) ];
  specialArgs.fx = fx;
  ned = (lib.evalModules { inherit modules specialArgs; }).config.ned;
in
ned
