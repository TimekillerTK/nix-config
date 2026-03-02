{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "hummingbird";

  flake.modules.nixos.humminbird = {pkgs, ...}: {
    imports = [
      # Filesystems on this host are defined with disko
      inputs.disko.nixosModules.default
      ./_disko.nix

      # inputs.self.modules.nixos.system-desktop

      # inputs.self.modules.nixos.tailscale-client
      # inputs.self.modules.nixos.nix-auto-update
      (inputs.self.factory.home-assistant-remote {
        bunny_user = "astra";
      })
      (inputs.self.factory.mount-cifs {
        shareName = "mediasnek3";
        shareLocalPath = "mediasnek";
        shareUsers = ["astra"];
        shareSecret = "astra";
      })
      (inputs.self.factory.mount-cifs {
        shareName = "important";
        shareLocalPath = "important";
        shareUsers = ["astra"];
        shareSecret = "astra";
      })

      inputs.self.modules.nixos.home-manager

      inputs.self.modules.nixos.astra
    ];

    home-manager.users.astra = {
      imports = [
        inputs.self.modules.homeManager.plasma-manager
      ];
      # Normal home-manager config stuff goes here
      # Custom packages for this user
      home.packages = with pkgs; [
        # Custom
        local.renamer
      ];

      home.file = {
        # VS Code Settings files as symlinks
        ".config/Code/User/keybindings.json".source = ../../../dotfiles/vscode/keybindings.json;
        ".config/Code/User/settings.json".source = ../../../dotfiles/vscode/settings.json;
      };
    };

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot";

    # Hostname
    networking.hostName = "hummingbird";

    # System Packages
    environment.systemPackages = with pkgs; [
      openrgb-with-all-plugins # RGB Control
    ];

    # OpenRGB (needs to run as root)
    services.hardware.openrgb.enable = true;

    # Generated with head -c4 /dev/urandom | od -A none -t x4
    networking.hostId = "16cc46d0"; # required for ZFS!
  };

  # # --- Collector Aspect ---
  # flake.modules.homeManager.shell = {
  #   # Added to the end of ~/.zshenv after initContent
  #   programs.zsh.envExtra = ''
  #     # Needed for Granted: https://docs.commonfate.io/granted/internals/shell-alias
  #     alias assume="source /home/tk/.nix-profile/bin/assume"
  #   '';
  # };

  # # --- Collector Aspect ---
  # flake.modules.homeManager.git = {
  #   programs.git.settings = {
  #     user.name = "TimekillerTK";
  #     user.email = "38417175+TimekillerTK@users.noreply.github.com";
  #     core.excludesfile = "/home/tk/.config/git/ignore";
  #     safe.directory = ["/home/tk/spaghetti"];
  #   };
  # };

  # # --- Collector Aspect ---
  # flake.modules.homeManager.helix = {
  #   programs.zsh.shellAliases = {
  #     # VS Code CAN be absent or present, so we do not use a nix store path
  #     # but we still want to ensure we can still run it with `vscode`.
  #     vscode = "/home/tk/.nix-profile/bin/code";
  #   };
  # };
}
