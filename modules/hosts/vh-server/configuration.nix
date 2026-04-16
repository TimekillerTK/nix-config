{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "vh-server";

  flake.modules.nixos.vh-server = {pkgs, ...}: {
    imports = [
      # Filesystems on this host are defined with disko
      inputs.disko.nixosModules.default
      ./_disko.nix

      inputs.self.modules.nixos.system-minimal

      inputs.self.modules.nixos.home-manager
      inputs.self.modules.nixos.prometheus-node-server
      (inputs.self.factory.nix-auto-update {})
      inputs.self.modules.nixos.tk
    ];

    home-manager.users.tk = {
      imports = [
        inputs.self.modules.homeManager.system-minimal
      ];
      # Normal home-manager config stuff goes here
    };
    # Hostname
    networking.hostName = "vh-server";

    # Required open ports
    networking.firewall.allowedUDPPorts = [2456 2457 2458];

    # User for running valheim
    users.users.valheim = {
      isSystemUser = true;
      group = "valheim";
      home = "/var/lib/valheim";
      createHome = true;
    };
    users.groups.valheim = {};

    # This exists so that we can send server commands to the
    # systemd service via /run/valheim.cmd
    #
    # For example, to save the World State, run the command:
    # > echo "save" | sudo -u valheim tee /run/valheim.cmd
    #
    # To see the command response, monitor the journal for the
    # systemd service in another window/tab/pane
    # > journalctl -fu valheim.service
    #
    systemd.sockets.valheim = {
      description = "Command FIFO for Valheim server";
      wantedBy = ["sockets.target"];

      socketConfig = {
        ListenFIFO = "/run/valheim.cmd";
        SocketUser = "valheim";
        SocketMode = "0660";
        RemoveOnStop = true;
      };
    };

    systemd.services.valheim = let
      steamApp = "896660";
      valheimDir = "/var/lib/steam-app-${steamApp}";
    in {
      description = "Valheim dedicated server (update & run)";
      after = [
        "network.target"
        "valheim.socket"
      ];
      wants = ["valheim.socket"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = "valheim";
        Group = "valheim";
        WorkingDirectory = valheimDir;
        StateDirectory = "steam-app-${steamApp}";
        Restart = "on-failure";

        # stdin comes from the FIFO/socket
        StandardInput = "socket";

        # stdout to journal so we can follow the logs
        StandardOutput = "journal";
        StandardError = "journal";
      };

      script = ''
        set -e

        # Ensure server files are up-to-date
        ${pkgs.steamcmd}/bin/steamcmd \
          +@sSteamCmdForcePlatformType linux \
          +force_install_dir ${valheimDir} \
          +login anonymous \
          +app_update ${steamApp} validate \
          +quit

        # Run the server under steam-run
        exec ${pkgs.steam-run}/bin/steam-run \
          ${valheimDir}/valheim_server.x86_64 \
          -nographics \
          -batchmode \
          -savedir /var/lib/valheim/save \
          -name "CynNeko" \
          -port 2456 \
          -world "Dedicated" \
          -public 0 \
          -backups 0 \
          -modifier raids muchless \
          -modifier combat hard \

          # World Modifiers available:
          #
          # combat	veryeasy easy hard veryhard
          # Adjusts combat difficulty
          #
          # deathpenalty	casual veryeasy easy hard hardcore
          # Changes death penalty severity
          #
          # resources	muchless less more muchmore most
          # Modifies resource drop rates
          #
          # raids	none muchless less more muchmore
          # Controls raid frequency
          #
          # portals	casual hard veryhard
          # Adjusts portal restrictions

          # Don't need a password on LAN tbh,
          # only required when public=1
          # -password "testpassword" \
      '';

      environment = {
        # NOTE: This is the valheim game app ID,
        # 896660 is the dedicated server app
        SteamAppId = "892970";

        # Valheim needs linux64 in LD_LIBRARY_PATH
        LD_LIBRARY_PATH = "${valheimDir}/linux64:${pkgs.glibc}/lib";
      };
    };
  };

  # Adding this host to the prometheus targets for the grafana host
  flake.modules.nixos.grafana = {
    prometheusTargets = {
      nix_auto_update = [
        "http://vh-server.cyn.internal:9001/statefile.json"
      ];
      node_systemd = [
        "vh-server.cyn.internal:9000"
      ];
    };
  };
}
