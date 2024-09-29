{ pkgs, ... }:
{
  # Minecraft Server
  services.minecraft-server = {
    enable = true;
    eula = true;

    openFirewall = true; # Opens the default port 25565
    declarative = true;

    serverProperties = {
      gamemode = "creative";
      difficulty = "easy";
    };
  };

  # This ensures systemd service is NOT started by default
  systemd.services.minecraft-server = {
    wantedBy = pkgs.lib.mkForce []; 
  };
}
