{
  outputs = _: {
    lib = import ./.;
    flakeModule =
      { lib, inputs, ... }:
      {
        _module.args.ned = import ./. { inherit lib inputs; };
      };
  };
}
