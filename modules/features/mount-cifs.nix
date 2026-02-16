{
  config.flake.factory.mount-cifs = {
    shareName ? "mediasnek3",
    shareLocalPath ? "mediasnek",
    shareGroup ? "smbusers",
    shareUsers,
  }: {
    users.groups.${shareGroup} = {
      name = "${shareGroup}";
      members = shareUsers;
    };
    # Mounting fileshare
    fileSystems.${shareLocalPath} = {
      device = "//truenas.cyn.internal/${shareName}";
      fsType = "cifs";
      options =
        [
          "credentials=/run/secrets/smbcred"
          "noserverino"
          "rw"
          "iocharset=utf8"
          "_netdev"
          "uid=1000"
          "gid=${shareGroup}"
          "file_mode=0770" # File permissions to rwx for user and group
          "dir_mode=0770" # Directory permissions to rwx for user and group
        ]
        # noauto + x-systemd.automount - disables mounting this FS with mount -a & lazily mounts (when first accessed)
        # Remember to run `sudo umount /mnt/mediasnek` before adding/removing "noauto" + "x-systemd.automount"
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
