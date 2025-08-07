{
  inputs,
  outputs,
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Repo Modules
    ../common/global
    ../common/users/tk
    ../common/optional/sops
    ../common/optional/mount-media
  ];

  # Overlays
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.other-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  # SOPS Secrets
  sops.secrets.smbcred = { };

  boot.kernelPackages = pkgs.linuxPackages_6_15;

  # Required for our user
  users.users.tk.shell = lib.mkForce pkgs.bash;
  users.users.tk.extraGroups = lib.mkForce [
    "networkmanager"
    "wheel"
    "video" # needed for vainfo
    "render" # needed for vainfo
  ];

  # Hostname & Network Manager
  networking.hostName = "jellyfin";
  networking.networkmanager.enable = true;

  # Adding CA root cert
  security.pki.certificateFiles = [
    ../common/root-ca.pem
  ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # For Broadwell (2014) or newer processors. LIBVA_DRIVER_NAME=iHD
      libva-vdpau-driver # Previously vaapiVdpau
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      vpl-gpu-rt # QSV on 11th gen or newer
    ];
  };

  # Set the VA-API driver environment variable.
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";

  # Includes firmware blobs for the i915 driver
  hardware.enableRedistributableFirmware = true;

  # Correct kernel parameters for the i915 driver.
  # - i915.enable_guc=2 enables both the GuC (for scheduling) and HuC (for media
  #   decode/encode), which is required for hardware transcoding.
  boot.kernelParams = [ "i915.enable_guc=2" ];

  # Needed for Transcoding
  users.users.jellyfin.extraGroups = ["video" "render"];

  # TODO: Testing, remove later if not needed (intel_gpu_top)
  boot.kernel.sysctl = {
      "kernel.perf_event_paranoid" = 1;
  };

  environment.systemPackages = with pkgs; [
    # For media transcoding
    jellyfin-ffmpeg
    libva-utils # vainfo
    intel-gpu-tools # intel_gpu_top (for checking)

    # others
    bottom
  ];

  # Jellyfin config
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
