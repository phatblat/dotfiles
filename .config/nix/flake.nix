# flake.nix
# https://davi.sh/til/nix/nix-macos-setup/

{
  description = "Darwin configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:lnl7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, ... }:
  let
    inherit (nix-darwin.lib) darwinSystem;

  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#DTO-A017
    # darwinConfigurations."DTO-A017" = nix-darwin.lib.darwinSystem {
    #   system = "aarch64-darwin";
    # };

    # darwinConfigurations."DTO-A017" = nix-darwin.lib.darwinSystem {
    #   modules = [ configuration ];
    # };

    # packages.aarch64-darwin.darwinConfigurations.DTO-A017 = {
    #   system = "aarch64-darwin";
    # };

    # darwinConfigurations = rec {
    #   j-one = darwinSystem {
    #     system = "aarch64-darwin";
    #     modules = attrValues self.darwinModules ++ [
    #       # Main `nix-darwin` config
    #       ./configuration.nix
    #       # `home-manager` module
    #       home-manager.darwinModules.home-manager
    #       {
    #         nixpkgs = nixpkgsConfig;
    #         # `home-manager` config
    #         home-manager.useGlobalPkgs = true;
    #         home-manager.useUserPackages = true;
    #         home-manager.users.jun = import ./home.nix;
    #       }
    #     ];
    #   };
    # };

    darwinConfigurations = {
    #   hostname = nix-darwin.lib.darwinSystem {
      DTO-A017 = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
        # modules = attrValues self.darwinModules ++ [
          # Main `nix-darwin` config
          ./configuration.nix

          # `home-manager` module
          home-manager.darwinModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.phatblat = import ./home.nix;

            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
        ];
      };
    };

    # packages = forAllSystems (system:
    #   import ./pkgs { pkgs = nixpkgs.legacyPackages.${system}; }
    # );
  };
}
