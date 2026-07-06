{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "pw-server";

  flake.modules.nixos.pw-server = {
    pkgs,
    config,
    ...
  }: {
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
    networking.firewall.allowedUDPPorts = [8211]; # Palworld Game Server
    networking.firewall.allowedTCPPorts = [8212]; # Palworld REST API

    # User for running palworld
    users.users.palworld = {
      isSystemUser = true;
      group = "palworld";
      home = "/var/lib/palworld";
      createHome = true;
    };
    users.groups.palworld = {};

    # Decrypt the admin password secret at boot
    sops.secrets.palworld_admin_password = {
      sopsFile = ../../../secrets/pw-server.yml;
      owner = "palworld";
    };

    # Render PalWorldSettings.ini with the decrypted admin password
    sops.templates."PalWorldSettings.ini" = {
      owner = "palworld";
      content = ''
        [/Script/Pal.PalGameWorldSettings]
        OptionSettings=(ServerName="CynNeko",ServerDescription="",AdminPassword="${config.sops.placeholder.palworld_admin_password}",ServerPassword="",PublicPort=8211,PublicIP="",RCONEnabled=False,RCONPort=25575,RESTAPIEnabled=True,RESTAPIPort=8212,bUseAuth=True,bShowPlayerList=False)
      '';
    };

    # Declaratively symlink the rendered settings file into the expected location
    systemd.tmpfiles.rules = let
      steamApp = "2394010";
      settingsFile = "/var/lib/steam-app-${steamApp}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini";
    in [
      "L+ ${settingsFile} - - - - ${config.sops.templates."PalWorldSettings.ini".path}"
    ];

    systemd.services.palworld = let
      steamApp = "2394010";
      palworldDir = "/var/lib/steam-app-${steamApp}";
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
