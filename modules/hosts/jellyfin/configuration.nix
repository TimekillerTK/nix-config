{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "jellyfin";

  flake.modules.nixos.jellyfin = {pkgs, ...}: let
    user = "tk";
    shareLocalPath = "mediasnek";
  in {
    imports = [
      inputs.self.modules.nixos.system-cli
      inputs.self.modules.nixos.prometheus-node-server
      (inputs.self.factory.nix-auto-update {})

      (inputs.self.factory.mount-cifs {
        shareName = "mediasnek3";
        inherit shareLocalPath;
        shareUsers = [user "jellyfin"];
        shareSecret = user;
      })

      inputs.self.modules.nixos.home-manager
      inputs.self.modules.nixos.tk
    ];

    # To activate the home manager modules for this user
    # for this host
    home-manager.users.tk = {
      imports = [
        inputs.self.modules.homeManager.system-cli
      ];
    };

    # Required for our user
    users.users.tk.extraGroups = [
      "video" # needed for vainfo
      "render" # needed for vainfo
      "jellyfin" # for easily browsing jellyfin owned directories
    ];

    # Hostname & Network Manager
    networking.hostName = "jellyfin";

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
    boot.kernelParams = ["i915.enable_guc=2"];

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
    ];

    # Files/directories managed by systemd-tmpfiles - these files will be ensured
    # to be present each boot or nix config activation.
    systemd.tmpfiles.rules = [
      # Symlink to Media folder
      "L /media - - - - /mnt/${shareLocalPath}/Media"

      # Since jellyfin installation was migrated, there are still existing paths
      # in the database and other locations which point to old locations.
      #
      # This will require database modification to update, so for now,
      # just symlinks.
      "d /config 770 jellyfin jellyfin -"
      "L /config/data - - - - /var/lib/jellyfin"
      "L /config/users - - - - /var/lib/jellyfin/config/users"
    ];

    # Jellyfin config
    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };
  };

  # Adding this host to the prometheus targets for the grafana host
  flake.modules.nixos.grafana = {
    prometheusTargets = {
      nix_auto_update = [
        "http://host.jellyfin.cyn.internal:9001/statefile.json"
      ];
      node_systemd = [
        "host.jellyfin.cyn.internal:9000"
      ];
    };
  };
}
