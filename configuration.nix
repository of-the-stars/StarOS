# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  inputs,
  lib,
  hostname,
  username,
  ...
}:
let
  pkgsUnstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    inherit (config.nixpkgs) config;
  };
in
{
  imports = [
    ./nixos-modules
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enables auto upgrades
  system.autoUpgrade = {
    enable = true;
    flake = "path:./../flake.nix";
    dates = "weekly";
    allowReboot = true;
    rebootWindow = {
      lower = "01:00";
      upper = "05:00";
    };
  };

  # Cleans up old unused files in the nix store automatically, since they can take up a lot of disk space if left untouched
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.settings.auto-optimise-store = true;

  hardware = {
    # OpenGL
    graphics.enable = true;
    # Most wayland compositors need this
    nvidia.modesetting.enable = true;
  };

  networking.hostName = "${hostname}"; # Define your hostname.
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" ];
  };

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable system power management
  powerManagement.enable = true;

  # Enable tlp for laptop power management
  # services.tlp = {
  #   enable = true;
  #   settings = {
  #     #   CPU_SCALING_GOVERNOR_ON_AC = "performance";
  #     #   CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
  #     #
  #     #   CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
  #     #   CPU_ENERGY_PERF_POLICY_ON_BAT = "powersave";
  #     #
  #     #   CPU_MIN_PERF_ON_AC = 0;
  #     #   CPU_MAX_PERF_ON_AC = 100;
  #     #   CPU_MIN_PERF_ON_BAT = 0;
  #     #   CPU_MAX_PERF_ON_BAT = 20;
  #     #
  #     #   #Optional helps save long term battery health
  #     START_CHARGE_THRESH_BAT0 = 80; # and below it starts to charge
  #     STOP_CHARGE_THRESH_BAT0 = 90; # and above it stops charging
  #   };
  # };

  # Allow unsupported systems
  nixpkgs.config.allowUnsupportedSystem = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.roboto-mono
  ];

  environment.localBinInPath = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # File system management
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [ ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
