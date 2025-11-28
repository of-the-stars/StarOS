{
  description = "The StarOS system flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs"; # Ensure Home Manager uses the same Nixpkgs as the system
    };
    home-manager-unstable.url = "github:nix-community/home-manager";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      home-manager-unstable,
    }@inputs:
    let
      username = "placeholder_username";
      hostname = "placeholder_hostname";
    in
    {
      nixosConfigurations.${hostname} = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit
            inputs
            username
            hostname
            ;
        };
        modules = [
          /etc/nixos/hardware-configuration.nix
          ./configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = {
              home.username = "${username}";
              home.homeDirectory = "/home/${username}";
              imports = [
                ./home.nix
              ];
            };
          }

          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ];
      };
    };
}
