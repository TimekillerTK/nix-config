{
  # Push-based ZFS replication to a remote host (e.g. TrueNAS) via syncoid.
  #
  # The remote user is granted exactly the permissions it needs via `zfs allow`
  # delegation on the target (NOT sudo) -- the nixpkgs services.syncoid module
  # unconditionally appends `--no-privilege-elevation`, so syncoid always treats
  # the remote user as root-equivalent and never prefixes `sudo` to remote `zfs`
  # commands. Local (source) ZFS permission delegation is handled automatically
  # by services.syncoid itself.
  flake.modules.nixos.zfs-replication = {
    config,
    lib,
    ...
  }: let
    cfg = config.zfsReplication;
  in {
    options.zfsReplication = {
      enable = lib.mkEnableOption "ZFS replication to a remote host";
      targetHost = lib.mkOption {
        type = lib.types.str;
        description = "Remote host to push snapshots to (e.g. `truenas.cyn.internal`).";
      };
      targetUser = lib.mkOption {
        type = lib.types.str;
        description = "Dedicated SSH user on the target host.";
      };
      targetPool = lib.mkOption {
        type = lib.types.str;
        description = "Top-level dataset/pool on the target host (e.g. `zfs-backup`).";
      };
      sshKeyFile = lib.mkOption {
        type = lib.types.str;
        description = "Path to the SSH private key used to connect to the target host.";
      };
      interval = lib.mkOption {
        type = with lib.types; either str (listOf str);
        description = "systemd OnCalendar spec(s) for the replication timer.";
      };
      mirror = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Pass `--delete-target-snapshots` so the target mirrors the source (prunes snapshots deleted locally).";
      };
      datasets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Local datasets to replicate recursively.";
      };
    };

    config = lib.mkIf cfg.enable {
      services.syncoid = {
        enable = true;
        interval = cfg.interval;
        sshKey = cfg.sshKeyFile;
        commands = lib.listToAttrs (map (ds:
          lib.nameValuePair ds {
            source = ds;
            target = "${cfg.targetUser}@${cfg.targetHost}:${cfg.targetPool}/${config.networking.hostName}/${ds}";
            recursive = true;
            recvOptions = "u"; # disable auto-mount on zfs receive

            # also disable compression because target does not have lzop
            # TODO: Add `lzop` for compression later on?
            extraArgs = ["--compress=none"] ++ lib.optionals cfg.mirror ["--delete-target-snapshots"];
          })
        cfg.datasets);
      };
    };
  };
}
