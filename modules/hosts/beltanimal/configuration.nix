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
        shareUsers = ["tk" "astra"];
      })
      (inputs.self.factory.mount-cifs {
        shareName = "important";
        shareLocalPath = "important";
        shareUsers = ["tk" "astra"];
      })

      inputs.self.modules.nixos.home-manager

      inputs.self.modules.nixos.tk
      inputs.self.modules.nixos.astra
      inputs.self.modules.nixos.bb
    ];

    home-manager.users.tk = {
      imports = [
        inputs.self.modules.homeManager.plasma-manager
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
      ];

      home.file = {
        # VS Code Settings files as symlinks
        ".config/Code/User/keybindings.json".source = ../../../dotfiles/vscode/keybindings.json;
        ".config/Code/User/settings.json".source = ../../../dotfiles/vscode/settings.json;
      };
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

    # Actual SOPS keys
    sops.secrets.smbcred = {
      sopsFile = ../../../secrets/default.yml;
    };

    # Hostname
    networking.hostName = "beltanimal";

    # System Packages
    environment.systemPackages = with pkgs; [
      kdePackages.kdialog # pops up dialogs
    ];

    # Generated with head -c4 /dev/urandom | od -A none -t x4
    networking.hostId = "75e25de8"; # required for ZFS!
  };

  # --- Collector Aspect ---
  # TODO: Once deployed, check if this is actually in the right place and
  # that it disappears when commented out
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
