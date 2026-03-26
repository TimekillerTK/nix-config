{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "anya";

  flake.modules.nixos.anya = {
    pkgs,
    lib,
    ...
  }: {
    imports = [
      # Filesystems on this host are defined with disko
      inputs.disko.nixosModules.default
      ./_disko.nix

      inputs.self.modules.nixos.system-desktop
      inputs.self.modules.nixos.minecraft-server

      # inputs.self.modules.nixos.tailscale-client
      # inputs.self.modules.nixos.nix-auto-update
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

    # This is a build machine for all of our x86-64_linux builds, so here's a
    # post build hook for that purpose
    nix.settings.post-build-hook = lib.getExe (pkgs.writeShellApplication {
      name = "post-build-hook";
      runtimeInputs = with pkgs; [ts nix findutils iputils];
      text = ''
        set -u # use of unset variables = error
        set -f # disable globbing
        export IFS=' '
        export CACHE_HOST="host.nix-cache.cyn.internal"

        if ! ping -c 1 $CACHE_HOST > /dev/null 2>&1; then
          echo "Ping to $CACHE_HOST failed, skipping upload." >&2
          exit 0
        fi

        if [[ -n "''${OUT_PATHS:-}" ]]; then
          export TS_MAXFINISHED=1000
          export TS_SLOTS=10

          echo "Uploading $OUT_PATHS"
          printf "%s" "$OUT_PATHS" \
          | xargs ts nix copy --to "ssh://upload-build-to-nix-cache-server"
        fi
      '';
    });

    # Secret Key for signing, important since we'll be building
    # packages on this machine intended for the harmonia nix-cache
    # server
    sops.secrets.harmonia_key = {
      sopsFile = ../../../secrets/harmonia_key.yml;
    };
    nix.settings.secret-key-files = [
      "/run/secrets/harmonia_key"
    ];

    # NOTE: This is NOT for OpenSSH server, it's for the local
    # ssh config on this machine accessible by ALL users, but
    # still only usable by root :)
    #
    # SSH config used by nix daemon (which runs as root), to
    # upload nix packages to the nix-cache server
    programs.ssh.extraConfig = ''
      Host upload-build-to-nix-cache-server
        HostName host.nix-cache.cyn.internal
        User builder
        IdentityFile /root/.ssh/id_ed25519
        IdentitiesOnly yes
        Port 22
    '';

    # 'builder' user is for other machines to ssh into to
    # execute remote builds
    # nix.settings.allowed-users = ["builder"];
    # users.users.builder = {
    #   shell = pkgs.zsh;
    #   isNormalUser = true;
    #   openssh.authorizedKeys.keys = [
    #     (builtins.readFile ../../../pub_keys/builder_key.pub)
    #   ];
    # };
    # security.sudo.extraRules = [
    #   {
    #     users = ["builder"];
    #     commands = [
    #       {
    #         # for `sudo nix build`
    #         command = "${pkgs.nix}/bin/nix";
    #         options = ["NOPASSWD"];
    #       }
    #       {
    #         # for old `nix-build`
    #         command = "${pkgs.nix}/bin/nix-build";
    #         options = ["NOPASSWD"];
    #       }
    #     ];
    #   }
    # ];

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
      pkgs.pingme
    ];

    # Generated with head -c4 /dev/urandom | od -A none -t x4
    networking.hostId = "7d650d06"; # required for ZFS!
  };
}
