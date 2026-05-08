let
  locked = import ./templates/ci/with-inputs.nix { };
in
{
  inputs ? locked,
  lib ? (inputs.nixpkgs or locked.nixpkgs).lib,
  fx ? import (inputs.nix-effects or locked.nix-effects) { inherit lib; },
  ...
}:
import ./kernel.nix { inherit lib fx; }
