
{ pkgs, ... }:
{
  # Custom packages for this user
  home.packages = with pkgs; [
    # Desktop Applications
    onedrivegui # OneDrive GUI client
    unstable.spotify # Music Streaming
    microsoft-edge # Backup Browser
    gimp # Photoshop Alternative
  ];
}
