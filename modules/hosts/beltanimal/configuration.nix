{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "beltanimal";

  flake.modules.nixos.beltanimal = {pkgs, ...}: {
    imports = [
      # Filesystems on this host are defined with disko
      inputs.disko.nixosModules.default
      ./_disko.nix

      # NixOS Hardware
      inputs.nixos-hardware.nixosModules.framework-16-7040-amd

      inputs.self.modules.nixos.system-desktop
      # inputs.self.modules.nixos.tailscale-client
      # inputs.self.modules.nixos.nix-auto-update
      (inputs.self.factory.home-assistant-remote {
        bunny_user = "astra";
      })
      (inputs.self.factory.mount-cifs {
        shareName = "mediasnek3";
        shareLocalPath = "mediasnek";
        shareUsers = ["tk" "astra"];
        shareSecret = "tk";
      })
      (inputs.self.factory.mount-cifs {
        shareName = "important";
        shareLocalPath = "important";
        shareUsers = ["tk" "astra"];
        shareSecret = "tk";
      })

      inputs.self.modules.nixos.home-manager

      inputs.self.modules.nixos.tk
      inputs.self.modules.nixos.astra
      inputs.self.modules.nixos.bb
    ];

    home-manager.users = let
      home-file-all-users = {
        # VS Code Settings files as symlinks
        ".config/Code/User/keybindings.json".source = ../../../dotfiles/vscode/keybindings.json;
        ".config/Code/User/settings.json".source = ../../../dotfiles/vscode/settings.json;
      };
      home-imports-all-users = [
        inputs.self.modules.homeManager.plasma-manager
        inputs.self.modules.homeManager.system-desktop
      ];
    in {
      tk.imports = home-imports-all-users;
      tk.home.file = home-file-all-users;
      tk.home.packages = with pkgs; [
        syncthingtray
      ];

      # Syncthing (personal cloud)
      tk.services.syncthing.enable = true;

      astra.imports = home-imports-all-users;
      astra.home.file = home-file-all-users;
      astra.home.packages = with pkgs; [
      ];

      bb.imports = home-imports-all-users;
      bb.home.file = home-file-all-users;
      bb.home.packages = with pkgs; [
      ];
    };

    # Firmware Updates
    # https://wiki.nixos.org/wiki/Fwupd
    services.fwupd.enable = true;

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot";

    # Install Logseq
    services.flatpak.packages = [
      # Temporarily installed due to
      # https://github.com/logseq/logseq/issues/10851
      "com.logseq.Logseq"
    ];

    # Steam
    environment.sessionVariables = {
      # Fixes steam not picking up correct scaling on framework (?)
      STEAM_FORCE_DESKTOPUI_SCALING = "1.5";
    };

    # By default laptops with closed lids automatically suspend, which
    # cuts off network connectivity. These changes prevent that on
    # the login screen.
    services.logind = {
      settings = {
        Login.HandleLidSwitch = "lock";
        Login.HandleLidSwitchDocked = "lock";
        Login.HandleLidSwitchExternalPower = "lock";
      };
    };

    # Hostname
    networking.hostName = "beltanimal";

    # System Packages
    environment.systemPackages = with pkgs; [
      kdePackages.kdialog # pops up dialogs

      # Custom
      local.renamer

      # Games
      unstable.xivlauncher # FFXIV Launcher
      prismlauncher # FOSS Minecraft launcher
      unstable.openrct2 # RollerCoaster Tycoon 2
      openttd # Transport Tycoon Deluxe
      unstable.vintagestory # Vintage Story
      devilutionx # Diablo I & Hellfire (best version)
    ];

    # Generated with head -c4 /dev/urandom | od -A none -t x4
    networking.hostId = "75e25de8"; # required for ZFS!
  };

  # --- Collector Aspect ---
  flake.modules.homeManager.shell = {
    # Added to the end of ~/.zshenv after initContent
    programs.zsh.envExtra = ''
      # Needed for Granted: https://docs.commonfate.io/granted/internals/shell-alias
      alias assume="source /home/tk/.nix-profile/bin/assume"
    '';
  };

  # --- Collector Aspect ---
  flake.modules.homeManager.git = {
    programs.git.settings = {
      user.name = "TimekillerTK";
      user.email = "38417175+TimekillerTK@users.noreply.github.com";
      core.excludesfile = "/home/tk/.config/git/ignore";
      safe.directory = ["/home/tk/spaghetti"];
    };
  };

  # --- Collector Aspect ---
  flake.modules.homeManager.helix = {
    programs.zsh.shellAliases = {
      # VS Code CAN be absent or present, so we do not use a nix store path
      # but we still want to ensure we can still run it with `vscode`.
      vscode = "/home/tk/.nix-profile/bin/code";
    };
  };
}
