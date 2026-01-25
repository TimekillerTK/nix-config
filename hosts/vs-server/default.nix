{
  inputs,
  outputs,
  pkgs,
  lib,
  config,
  users,
  ...
}: {
  imports = [
    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Repo Modules
    ../common/global
    ../common/users/tk
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

  # boot stuff (required)
  boot.kernelPackages = pkgs.linuxPackages_6_18;

  # Hostname & Network Manager
  networking.hostName = "vs-server";
  networking.networkmanager.enable = true;

  # use default bash
  users.users.tk.shell = lib.mkForce pkgs.bash;
  users.users.tk.extraGroups = lib.mkForce ["networkmanager" "wheel" "vintagestory"];

  # User/group for VintageStory user
  users.users.vintagestory = {
    isSystemUser = true;
    group = "vintagestory";
  };
  users.groups.vintagestory = {};

  # VintageStory firewall ports open
  networking.firewall.allowedTCPPorts = [42420];
  networking.firewall.allowedUDPPorts = [42420];

  # This exists so that we can send server commands to the
  # systemd service via /run/vintagestory.cmd
  #
  # For example, to get help run the command:
  # > echo "/help" | sudo -u vintagestory tee /run/vintagestory.cmd
  #
  # To see the command response, monitor the journal for the
  # systemd service in another window/tab/pane
  # > journalctl -fu vintagestory.service
  #
  systemd.sockets.vintagestory = {
    description = "Command FIFO for Vintage Story server";
    wantedBy = ["sockets.target"];

    socketConfig = {
      ListenFIFO = "/run/vintagestory.cmd";
      SocketUser = "vintagestory";
      SocketMode = "0660";
      RemoveOnStop = true;
    };
  };

  systemd.services.vintagestory = {
    description = "Vintage Story server";
    after = [
      "network.target"
      "vintagestory.socket"
    ];
    wants = ["vintagestory.socket"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "simple";
      User = "vintagestory";
      Group = "vintagestory";
      StateDirectory = "vintagestory";
      Restart = "on-failure";

      # stdin comes from the FIFO/socket
      StandardInput = "socket";

      # stdout to journal so we can follow the logs
      StandardOutput = "journal";
      StandardError = "journal";

      ExecStart = ''
        "${pkgs.unstable.vintagestory}/bin/vintagestory-server" \
        --dataPath /var/lib/vintagestory
      '';
    };
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
