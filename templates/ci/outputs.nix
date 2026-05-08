inputs:
(inputs.nixpkgs.lib.evalModules {
  modules = [
    (inputs.import-tree ./modules)
    inputs.ned.flakeModule
  ];
  specialArgs.inputs = inputs;
}).config.flake
