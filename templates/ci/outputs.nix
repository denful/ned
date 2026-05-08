inputs:
(inputs.nixpkgs.lib.evalModules {
  modules = [ (inputs.import-tree ./modules) ];
  specialArgs.inputs = inputs;
}).config.flake
