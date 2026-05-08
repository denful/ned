{
  lib,
  inputs,
  config,
  ...
}:
{
  imports = [ inputs.ned.flakeModule ];

  config._module.args.ci = config.ci;

  options.flake.tests = lib.mkOption {
    description = "nix-unit tests";
    default = { };
    type = lib.types.submodule {
      freeformType = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.unspecified);
    };
  };

  options.ci = lib.mkOption {
    description = "CI lib";
    default = { };
    type = lib.types.submodule {
      freeformType = lib.types.lazyAttrsOf lib.types.unspecified;
    };
  };
}
