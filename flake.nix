{
  description = "of-the-stars's system flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";

    nixpkgs-unstable.url = "github:nixos/nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs"; # Ensure Home Manager uses the same Nixpkgs as the system
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      userPath = ./users;
      hostPath = ./hosts;

      users = lib.mapAttrs' (name: value: lib.nameValuePair name (import (userPath + ("/" + name)))) (
        lib.filterAttrs (name: type: type == "directory") (builtins.readDir userPath)
      );

      nixosConfigurations = lib.mapAttrs' (
        name: value:
        lib.nameValuePair name (
          lib.nixosSystem (import (hostPath + ("/" + name)) { inherit inputs users nixpkgs; })
        )
      ) (lib.filterAttrs (name: type: type == "directory") (builtins.readDir hostPath));
    in
    {
      inherit nixosConfigurations;
    };
}
