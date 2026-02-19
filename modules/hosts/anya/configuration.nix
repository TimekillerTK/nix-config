{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "anya";

  flake.modules.nixos.anya = {pkgs, ...}: {
    imports = [
      # Filesystems on this host are defined with disko
      inputs.disko.nixosModules.default
      ./_disko.nix

      inputs.self.modules.nixos.system-desktop

      inputs.self.modules.nixos.secrets
      inputs.self.modules.nixos.zfs
      inputs.self.modules.nixos.minecraft-server
      inputs.self.modules.nixos.prometheus-node-desktop
      # inputs.self.modules.nixos.tailscale-client
      # inputs.self.modules.nixos.nix-auto-update
      (inputs.self.factory.home-assistant-remote {
        bunny_user = "tk";
      })
      (inputs.self.factory.mount-cifs {
        shareUsers = ["tk"];
      })
      (inputs.self.factory.mount-cifs {
        shareName = "important";
        shareLocalPath = "important";
        shareUsers = ["tk"];
      })

      inputs.self.modules.nixos.home-manager

      inputs.self.modules.nixos.tk
      # inputs.self.modules.nixos.bb
    ];

    home-manager.users.tk = {
      # Normal home-manager config stuff goes here
      # Custom packages for this user
      home.packages = with pkgs; [
        sops # Mozilla SOPS
        awscli2 # AWS CLI

        # Python
        python313
        unstable.poetry
        ruff
        uv

        # pwsh
        powershell

        # Rust
        rustup
        unstable.lld # better linker by LLVM
        unstable.clang
        unstable.mold # even better linker

        # Desktop Applications
        unstable.element-desktop # Matrix client
        unstable.makemkv # DVD Ripper
        handbrake # Media Transcoder
        unstable.xivlauncher # FFXIV Launcher
        rustdesk-flutter # TeamViewer alternative
        unstable.drawio # Diagram-creating software
        syncthingtray # Tray for Syncthing with Dolphin/Plasma integration

        # Other
        unstable.devenv # Nix powered dev environments
        mono # for running .NET applications
        granted # Switching AWS Accounts
        brave # Chromium-based browser

        # Games
        unstable.openrct2 # RollerCoaster Tycoon 2
        openttd # Transport Tycoon Deluxe
        unstable.vintagestory # Vintage Story
      ];

      home.file = {
        # VS Code Settings files as symlinks
        ".config/Code/User/keybindings.json".source = ../../../dotfiles/vscode/keybindings.json;
        ".config/Code/User/settings.json".source = ../../../dotfiles/vscode/settings.json;
      };
    };

    # TODO: Don't forget to set ~/.config/nixpkgs/config.nix
    # TODO: pkgs manual import for printer

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot";

    # Install Logseq
    services.flatpak.packages = [
      # Temporarily installed due to
      # https://github.com/logseq/logseq/issues/10851
      "com.logseq.Logseq"
    ];

    # Actual SOPS keys
    sops.secrets.smbcred = {
      sopsFile = ../../../secrets/default.yml;
    };

    # Add printer autodiscovery
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # For game streaming
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true; # only needed for Wayland -- omit this when using with Xorg
      openFirewall = true;
    };

    # Steam
    programs.steam.enable = true;

    # Hostname & Network Manager
    networking.hostName = "anya";
    networking.networkmanager = {
      enable = true;
    };

    # Enable QMK support (Keychron)
    hardware.keyboard.qmk.enable = true;
    hardware.keyboard.qmk.keychronSupport = true;

    # # Docker for when needed
    # virtualisation.docker.enable = true;
    # users.users.tk.extraGroups = lib.mkForce [ "networkmanager" "wheel" "docker" ];

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
      pkgs.devilutionx # Diablo I & Hellfire (best version)
      pkgs.kdePackages.kdialog # pops up dialogs
    ];

    # Generated with head -c4 /dev/urandom | od -A none -t x4
    networking.hostId = "7d650d06"; # required for ZFS!
  };
}
