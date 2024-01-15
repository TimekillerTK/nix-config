# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ modulesPath, inputs, outputs, config, pkgs, ... }:

{
  imports =
    [
      inputs.vscode-server.nixosModules.default
      inputs.sops-nix.nixosModules.sops
      (modulesPath + "/profiles/qemu-guest.nix") # Required for QEMU Virtio VMs
      ./disk-config.nix
    ];

  # Overlays from ../overlays
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.other-packages
    ];
    # Allow unfree packages (Host)
    config.allowUnfree = true;
  };

  # Nix automatic Garbage Collect
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Path to secrets file & format
  sops.defaultSopsFile = ../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  # Path to Age Private Key
  sops.age.keyFile = "/home/tk/.secrets/sops/age/keys.txt";

  # The actual keys
  sops.secrets.tailscale = { };

  # Enabling Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enabling use of binary cache (Cachix)
  # NOTE: Adding this prevents warning:
  # warning: ignoring untrusted substituter 'https://devenv.cachix.org', you are not a trusted user.
  nix.settings = {
    substituters = [
      "https://devenv.cachix.org"
    ];
    trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

  # Enabling Flatpaks
  services.flatpak.enable = true;

  # NOTE: After enabling, needs manual step to add flathub:
  # > flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  # VS Code Server Module
  services.vscode-server.enable = true;

  # Bootloader.
  # boot.loader.grub.device = "/dev/sda"; # Conflicts with Disko
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking.hostName = "nixos-test"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nl_NL.UTF-8";
    LC_IDENTIFICATION = "nl_NL.UTF-8";
    LC_MEASUREMENT = "nl_NL.UTF-8";
    LC_MONETARY = "nl_NL.UTF-8";
    LC_NAME = "nl_NL.UTF-8";
    LC_NUMERIC = "nl_NL.UTF-8";
    LC_PAPER = "nl_NL.UTF-8";
    LC_TELEPHONE = "nl_NL.UTF-8";
    LC_TIME = "nl_NL.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable tailscale
  services.tailscale.enable = true;
  services.tailscale.authKeyFile = config.sops.secrets."tailscale".path;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tk = {
    isNormalUser = true;
    description = "tk";
    initialPassword = "Hello123!"; # Temp PW
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.bash;
    packages = with pkgs; [];

    # Add SSH Key to TK User
    openssh.authorizedKeys.keys = [
      (builtins.readFile ./mbp.pub)
      (builtins.readFile ./anya.pub)
    ];
  };

  # Passwordless Sudo
  security.sudo.extraRules = [
    {
      users = ["tk"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  # Add same SSH Key to Root User
  users.users.root = {
    initialPassword = "Hello123!"; # Temp PW
    openssh.authorizedKeys.keys = [
      (builtins.readFile ./mbp.pub)
      (builtins.readFile ./anya.pub)
    ];
  };

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    openssh
    tailscale # Mesh VPN using Wireguard Protocol
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
