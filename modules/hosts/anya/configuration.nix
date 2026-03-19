{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "anya";

  flake.modules.nixos.anya = {pkgs, ...}: {
    imports = [
      # Filesystems on this host are defined with disko
      inputs.disko.nixosModules.default
      ./_disko.nix

      inputs.self.modules.nixos.system-desktop
      inputs.self.modules.nixos.minecraft-server

      # inputs.self.modules.nixos.nix-binary-cache
      # inputs.self.modules.nixos.tailscale-client
      inputs.self.modules.nixos.nix-auto-update
      (inputs.self.factory.home-assistant-remote {
        bunny_user = "tk";
      })
      (inputs.self.factory.mount-cifs {
        shareName = "mediasnek3";
        shareLocalPath = "mediasnek";
        shareUsers = ["tk"];
        shareSecret = "tk";
      })
      (inputs.self.factory.mount-cifs {
        shareName = "important";
        shareLocalPath = "important";
        shareUsers = ["tk"];
        shareSecret = "tk";
      })

      inputs.self.modules.nixos.home-manager

      inputs.self.modules.nixos.tk
      # inputs.self.modules.nixos.bb
    ];
    home-manager.users.tk = {
      imports = [
        inputs.self.modules.homeManager.plasma-manager
        inputs.self.modules.homeManager.system-desktop
      ];
      # Normal home-manager config stuff goes here
      # Custom packages for this user
      home.packages = with pkgs; [
        # Custom
        local.renamer

        # Desktop Applications
        unstable.element-desktop # Matrix client
        unstable.makemkv # DVD Ripper
        handbrake # Media Transcoder
        unstable.drawio # Diagram-creating software

        # Games
        unstable.xivlauncher # FFXIV Launcher
        prismlauncher # FOSS Minecraft launcher
        unstable.openrct2 # RollerCoaster Tycoon 2
        openttd # Transport Tycoon Deluxe
        unstable.vintagestory # Vintage Story
        devilutionx # Diablo I & Hellfire (best version)
        syncthingtray

        # Testing
        sl
      ];

      # Syncthing (personal cloud)
      services.syncthing = {
        enable = true;
      };

      # DirEnv configuration
      programs.direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };

      home.file = {
        # VS Code Settings files as symlinks
        ".config/Code/User/keybindings.json".source = ../../../dotfiles/vscode/keybindings.json;
        ".config/Code/User/settings.json".source = ../../../dotfiles/vscode/settings.json;
      };
    };

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot";

    # Install Logseq
    services.flatpak.packages = [
      # Temporarily installed due to
      # https://github.com/logseq/logseq/issues/10851
      "com.logseq.Logseq"
    ];

    # Hostname
    networking.hostName = "anya";

    # Enable QMK support (Keychron)
    hardware.keyboard.qmk.enable = true;
    hardware.keyboard.qmk.keychronSupport = true;

    # TODO: This is for GDM Login Screen settings, should probably be adapted to the KDE plasma
    # module (and Gnome module) as its very specific to those configs.
    systemd.tmpfiles.rules = let
      monitorsXmlContent = builtins.readFile ./anya-monitors.xml;
      monitorsConfig = pkgs.writeText "gdm_monitors.xml" monitorsXmlContent;
    in [
      "L+ /run/gdm/.config/monitors.xml - - - - ${monitorsConfig}"
    ];

    # System Packages
    environment.systemPackages = [
      pkgs.kdePackages.kdialog # pops up dialogs
    ];

    # Generated with head -c4 /dev/urandom | od -A none -t x4
    networking.hostId = "7d650d06"; # required for ZFS!
  };
}
