{pkgs, ...}: {
  # For remapping HIDs
  # TODO: Needs to be started with sudo permissions automatically on login (?)
  services.input-remapper = {
    enable = true;
    package = pkgs.unstable.input-remapper;
  };
}
