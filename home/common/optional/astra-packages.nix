
{ pkgs, ... }:
{
  # Custom packages for this user
  home.packages = with pkgs; [
    # Desktop Applications
    onedrivegui # OneDrive GUI client
    spotify # Music Streaming
    discord # Chat
    microsoft-edge # Backup Browser
    gimp # Photoshop Alternative
  ];
}