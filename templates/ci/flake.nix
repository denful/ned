{
  outputs = inputs: import ./outputs.nix inputs;

  inputs = {
    with-inputs.url = "github:denful/with-inputs";
    with-inputs.flake = false;

    ned.url = "github:denful/ned";

    import-tree.url = "github:denful/import-tree";

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-effects.url = "github:denful/nix-effects/push-pyplsuktytks";
    nix-effects.flake = false;

    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-maid.url = "github:viperML/nix-maid";
  };
}
