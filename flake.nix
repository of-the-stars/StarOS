# # An intro to Nix flakes
#
# Flakes are an "experimental" feature of Nix that have been widely
# adopted due to how conveniently they solve several problems that
# the old way of using Nix didn't really work well for. Some examples
# are:
#
#   - Pinning packages and/or systems to certain revisions
#   - Allowing program repos to package themselves for Nix
#
# Flakes are useful tools to know exactly where you're getting
# everything from when building things with Nix. Since they return
# Nix objects, they can return derivations which includes packages,
# development shells, and as we're going to see below, NixOS
# configurations.
#
# Flakes are just any directory with a `flake.nix` file
#
# Flakes are just attribute sets with 3 main components:
#
#   - A description
#   - An attribute set with all its inputs
#   - An output function which takes in the inputs as the
#     argument, and then returns an attribute set

{
  # A description is usually a short string. Save anything longer for the README
  description = "StarOS system template flake";

  # Inputs are usually other flakes by default, although they don't have to be
  # All the starting inputs here are URIs which pull from github based on
  # the repo's owner and name, plus some optional tag information.
  # They match the pattern "github:(owner)/(repo)(/tag)?"
  inputs = {
    # This is Nixpkgs tied to the 26.05 release
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    # This is Nixpkgs tied to the `main` branch
    nixpkgs-unstable.url = "github:nixos/nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      # Ensures that Home Manager uses the same Nixpkgs input as the system
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    # The `@name` syntax lets us bind the otherwise attribute set to a
    # specific name
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    # A `let ... in` binding lets us declare objects and their values to use in
    # the scope following `in`
    let
      # Inherits the function library from nixpkgs to expose
      # some important functions to be used in a bit
      inherit (nixpkgs) lib;

      # Relative paths that are going to be read later
      userPath = ./users;
      hostPath = ./hosts;

      users =
        # Maps an attribute set into another set via a function that returns a nameValuePair
        lib.mapAttrs'
          # Function that maps the user directories set
          (
            name: value:
            # Keeps the name but changes the value to import the `default.nix` file
            # sitting in the user's directory
            lib.nameValuePair name
              # `import` here basically replaces its callsite with whatever
              # Nix expression is stored at the path its given. If the path
              # is a plain directory, then it looks for a `default.nix` file
              # within that directory and grabs that.
              (import (userPath + ("/" + name)))
          )

          # Attribute set containing all the user directories
          (
            # Filters attribute set so that only directories are included
            lib.filterAttrs (name: type: type == "directory")
              # Returns an attribute set with file names as the name of the attributes
              # and the types of the files as their value
              (builtins.readDir userPath)
          );

      nixosConfigurations =
        # Maps an attribute set into another set via a function that returns a
        # nameValuePair
        lib.mapAttrs'
          # Function that maps the host directories set
          (
            name: value:
            # Keeps the name but changes the value to import the `default.nix` file
            # sitting in the host's directory, passing along an attribute set as
            # an argument as well
            lib.nameValuePair name (
              # `lib.nixosSystem` is the function that creates NixOS system
              # configurations from an attribute set. We're getting that
              # attribute set from the `default.nix` file within the host's
              # directory
              lib.nixosSystem
                # `import` here basically replaces its callsite with whatever
                # Nix expression is stored at the path its given. If the path
                # is a plain directory, then it looks for a `default.nix` file
                # within that directory and grabs that.
                (
                  import (hostPath + ("/" + name))
                    # `import` can also pass along arguments if the Nix expression it's
                    # pulling is a function. Here, we're passing along a single attribute
                    # set as the argument. The `inherit` keyword here passes along the
                    # value with the same name from the surrounding scope into the
                    # attribute set
                    { inherit inputs users nixpkgs; }
                )
            )
          )

          # Attribute set containing all the user directories
          (
            # Filters attribute set so that only directories are included
            lib.filterAttrs (name: type: type == "directory")
              # Returns an attribute set with file names as the name of the attributes
              # and the types of the files as their value
              (builtins.readDir hostPath)
          );

      systems = lib.intersectLists lib.systems.flakeExposed lib.platforms.linux;
      forAllSystems = lib.genAttrs systems;
    in
    {
      # Uses the `inherit` keyword to pull in nixosConfigurations and its value into
      # the attribute set
      inherit nixosConfigurations;

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
