{
  outputs = _: {
    flakeModule =
      { lib, inputs, ... }:
      {
        _module.args.ned = import ./. { inherit lib inputs; };
      };
  };
}
