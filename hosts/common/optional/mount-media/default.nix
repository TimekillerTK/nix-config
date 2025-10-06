# Mounts important to /mnt/mediasnek
{
  config,
  lib,
  users,
  ...
}: {
  # NOTE: Running this will fail initially with the error below, but rerunning will
  # resolve this.
  #
  #   Error: Failed to open unit file /nix/store/hash-nixos-system-host-25.05.20250606.xxxxxxx/etc/systemd/system/mnt-mediasnek.mount

  # Caused by:
  #     No such file or directory (os error 2)
  # warning: error(s) occurred while switching to the new configuration

  options.mediaShare = {
    mediaSharePath = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/mediasnek";
      description = "Path where media share will be mounted on the client filesystem";
    };
    groupName = lib.mkOption {
      type = lib.types.str;
      default = "sharedsmb";
      description = "Name of group of users who will have access to the share";
    };
  };
  config = {
    # Group for shared access
    users.groups.${config.mediaShare.groupName} = {
      name = "${config.mediaShare.groupName}";
      members = users;
    };

    # Mounting fileshare
    fileSystems.${config.mediaShare.mediaSharePath} = {
      device = "//truenas.cyn.internal/mediasnek3";
      fsType = "cifs";
      # noauto + x-systemd.automount - disables mounting this FS with mount -a & lazily mounts (when first accessed)
      # Remember to run `sudo umount /mnt/mediasnek` before adding/removing "noauto" + "x-systemd.automount"
      options =
        [
          "credentials=/run/secrets/smbcred"
          "noserverino"
          "rw"
          "_netdev"
          "uid=1000"
          "gid=${config.mediaShare.groupName}"
          "file_mode=0770" # File permissions to rwx for user and group
          "dir_mode=0770" # Directory permissions to rwx for user and group
        ]
        ++ [
          "noauto" # prevent from being automatically mounted on BOOT
          "x-systemd.automount" # create an automount unit, mount on ACCESS
          "x-systemd.idle-timeout=300" # after not accessed for 5 minutes, systemd will attempt unmount
          "x-systemd.device-timeout=5s" # if device doesn't appear in 5 secs, fail the mount
          "x-systemd.mount-timeout=5s" # if mount command doesn't succeed in 5 secs, fail the mount
        ];
      # NOTE: to query:
      #   systemctl list-units --type=automount
    };
  };
}
