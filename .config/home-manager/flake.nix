{
  description = "Home Manager configuration of phatblat";

  nixConfig = {
    extra-substituters = [ "https://phatblat.cachix.org" ];
  };

  inputs = {
    # Pinned to last working revision for xcodes on aarch64-darwin (2025-12-31).
    # Swift 5.10.1 build crashes during bootstrapping on nixos-unstable due to
    # upstream compiler segfault. See: https://github.com/NixOS/nixpkgs/issues/353261
    nixpkgs.url = "github:nixos/nixpkgs/ee889ba3c108edae7bb38a33a0fa33f318aa09e9";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      homeConfigurations."phatblat" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [ ./home.nix ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      };
    };
}
