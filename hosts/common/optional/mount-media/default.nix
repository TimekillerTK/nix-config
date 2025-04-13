# Mounts important to /mnt/media
{ config, lib, ... }:
{
  options.mediaShare = {
    mediaSharePath = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/mediasnek";
      description = "Path where media share will be mounted on the client filesystem";
    };
  };
  config = {
    # Mounting fileshare
    fileSystems.${config.mediaShare.mediaSharePath} = {
      device = "//freenas.cyn.internal/mediasnek3";
      fsType = "cifs";
      # noauto + x-systemd.automount - disables mounting this FS with mount -a & lazily mounts (when first accessed)
      # Remember to run `sudo umount /mnt/mediasnek` before adding/removing "noauto" + "x-systemd.automount"
      options = [
        "credentials=/run/secrets/smbcred"
        "noserverino"
        "rw"
        "_netdev"
        "uid=1000"
        "gid=100"
        "file_mode=0770"   # File permissions to rwx for user and group
        "dir_mode=0770"    # Directory permissions to rwx for user and group
      ] ++ [
        "noauto"                      # prevent from being automatically mounted on BOOT
        "x-systemd.automount"         # create an automount unit, mount on ACCESS
        "x-systemd.idle-timeout=60"   # after not accessed for 60 seconds, systemd will attempt unmount
        "x-systemd.device-timeout=5s" # if device doesn't appear in 5 secs, fail the mount
        "x-systemd.mount-timeout=5s"  # if mount command doesn't succeed in 5 secs, fail the mount
      ];
      # NOTE: to query:
      #   systemctl list-units --type=automount
    };
  };
}
