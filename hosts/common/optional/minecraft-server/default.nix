{pkgs, ...}: {
  # Minecraft Server
  services.minecraft-server = {
    enable = true;
    eula = true;

    openFirewall = true; # Opens the default port 25565
    declarative = true;

    serverProperties = {
      gamemode = "creative";
      difficulty = "easy";

      # mcrcon access to Minecraft Server
      enable-rcon = true;
      "rcon.password" = "Hello123!";
      "rcon.port" = 25575;
    };
  };

  # Minecraft CLI client to interact with the server
  # To connect:
  # mcrcon -H localhost -P 25575 -p 'passwordhere' -t
  environment.systemPackages = with pkgs; [
    mcrcon
  ];

  # This ensures systemd service is NOT started by default
  systemd.services.minecraft-server = {
    wantedBy = pkgs.lib.mkForce [];
  };
}
