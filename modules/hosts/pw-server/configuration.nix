{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "pw-server";

  flake.modules.nixos.pw-server = {pkgs, ...}: {
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
    networking.hostName = "pw-server";

    # Required open ports
    networking.firewall.allowedUDPPorts = [8211];

    # User for running palworld
    users.users.palworld = {
      isSystemUser = true;
      group = "palworld";
      home = "/var/lib/palworld";
      createHome = true;
    };
    users.groups.palworld = {};

    systemd.services.palworld = let
      steamApp = "2394010";
      palworldDir = "/var/lib/steam-app-${steamApp}";
      settingsDir = "/var/lib/palworld/Pal/Saved/Config/LinuxServer";
      settingsFile = "${settingsDir}/PalWorldSettings.ini";
    in {
      description = "Palworld dedicated server (update & run)";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = "palworld";
        Group = "palworld";
        WorkingDirectory = palworldDir;
        StateDirectory = "steam-app-${steamApp}";
        Restart = "on-failure";

        # Palworld needs a clean shutdown to flush world saves
        KillSignal = "SIGINT";
        TimeoutStopSec = 60;
      };

      script = ''
        set -e

        # Ensure server files are up-to-date
        ${pkgs.steamcmd}/bin/steamcmd \
          +@sSteamCmdForcePlatformType linux \
          +force_install_dir ${palworldDir} \
          +login anonymous \
          +app_update ${steamApp} validate \
          +quit

        # Write default settings file with server name if it doesn't exist yet
        if [ ! -f ${settingsFile} ]; then
          mkdir -p ${settingsDir}
          cat > ${settingsFile} <<'EOF'
[/Script/Pal.PalGameWorldSettings]
OptionSettings=(ServerName="CynNeko",ServerDescription="",AdminPassword="",ServerPassword="",PublicPort=8211,PublicIP="",RCONEnabled=False,RCONPort=25575,bUseAuth=True,bShowPlayerList=False)
EOF
        fi

        # Run the server under steam-run
        exec ${pkgs.steam-run}/bin/steam-run \
          ${palworldDir}/PalServer.sh \
          -useperfthreads \
          -NoAsyncLoadingThread \
          -UseMultithreadForDS
      '';

      environment = {
        # Palworld game client app ID (required for Steam runtime)
        SteamAppId = "1623730";
      };
    };
  };

  # Adding this host to the prometheus targets for the grafana host
  flake.modules.nixos.grafana = {
    prometheusTargets = {
      nix_auto_update = [
        "http://pw-server.cyn.internal:9001/statefile.json"
      ];
      node_systemd = [
        "pw-server.cyn.internal:9000"
      ];
    };
  };
}
