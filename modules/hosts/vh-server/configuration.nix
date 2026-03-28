{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "vh-server";

  flake.modules.nixos.vh-server = {pkgs, ...}: {
    imports = [
      # Filesystems on this host are defined with disko
      inputs.disko.nixosModules.default
      ./_disko.nix

      inputs.self.modules.nixos.system-minimal

      inputs.self.modules.nixos.home-manager
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

    systemd.services.valheim = let
      valheimDir = "/var/lib/steam-app-valheim";
    in {
      description = "Valheim dedicated server (update + run)";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        Type = "simple";
        User = "valheim";
        WorkingDirectory = valheimDir;
        Restart = "always";
        PrivateTmp = true;
        ExecStart = ''
          # 1) Ensure server files are up-to-date
          ${pkgs.steamcmd}/bin/steamcmd \
            +@sSteamCmdForcePlatformType linux \
            +force_install_dir ${valheimDir} \
            +login anonymous \
            +app_update 896660 validate \
            +quit

          # 2) Run the server under steam-run
          exec ${pkgs.steam-run}/bin/steam-run \
            ${valheimDir}/valheim_server.x86_64 \
            -nographics \
            -batchmode \
            -savedir /var/lib/valheim/save \
            -name "CynNeko" \
            -port 2456 \
            -world "Dedicated" \
            -password "testpassword" \
            -public 0 \
            -backups 0
        '';
      };

      environment = {
        # NOTE: This is the valheim game app ID,
        # 896660 is the dedicated server app
        SteamAppId = "892970";
      };
    };
  };
}
