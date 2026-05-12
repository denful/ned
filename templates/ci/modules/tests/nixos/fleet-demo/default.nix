{ config, lib, ... }: {
  config._module.args.fleet-demo = config.fleet-demo;
  options.fleet-demo = lib.mkOption {
    description = "Fleet-demo components";
    default = { };
    type = lib.types.submodule {
      freeformType = lib.types.lazyAttrsOf lib.types.unspecified;
    };
  };
}
