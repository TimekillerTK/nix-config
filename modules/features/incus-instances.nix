{
  # Declarative Incus instances (containers and virtual machines). Requires `modules.nixos.incus`.
  flake.modules.nixos.incus-instances = {
    config,
    lib,
    ...
  }: {
    options.incusInstances = lib.mkOption {
      description = "Declarative Incus instances, reconciled from each entry's YAML (self-contained; uses `--no-profiles`).";
      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
          type = lib.mkOption {
            type = lib.types.enum ["container" "virtual-machine"];
            default = "container";
            description = "Instance type. VMs (`virtual-machine`) are never auto-recreated on config drift.";
          };
          image = lib.mkOption {
            type = lib.types.str;
            description = "Image reference passed to `incus init`, e.g. `ghcr:mealie-recipes/mealie:v3.9.2` (OCI), `docker:linuxserver/qbittorrent:latest` (OCI), or `images:debian/12` (LXC/VM base image).";
          };
          configYaml = lib.mkOption {
            type = lib.types.path;
            description = "Path to the instance's YAML configuration.";
          };
          autostart = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to auto-start on boot (maps to `boot.autostart`).";
          };
          dataVolume = lib.mkOption {
            type = lib.types.nullOr (lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Name of the custom volume to create (referenced from the instance YAML).";
                };
                pool = lib.mkOption {
                  type = lib.types.str;
                  default = "default";
                  description = "Storage pool in which to create the volume.";
                };
                size = lib.mkOption {
                  type = lib.types.str;
                  description = "Size/quota of the volume, e.g. `10GiB`.";
                };
                snapshotSchedule = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Cron/schedule alias for snapshots (e.g. `@daily`). Null disables them.";
                };
                snapshotExpiry = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Auto-expiry for new snapshots (e.g. `1m` = one month). Null keeps forever.";
                };
                snapshotPattern = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Pongo2 template for snapshot names. Null uses Incus' default.";
                };
              };
            });
            default = null;
            description = "Optional storage volume created before the instance for its data; survives instance recreation.";
          };
          startAfter = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Name of an instance to start before this one during reconciliation (not Incus's boot-time order).";
          };
          startDelaySeconds = lib.mkOption {
            type = lib.types.ints.unsigned;
            default = 0;
            description = "Seconds to sleep after (re)starting this instance during reconciliation.";
          };
        };
      }));
      default = {};
    };

    config = let
      # NOTE: To compute the desiredHash, run this command:
      #
      # nix eval --json '.#nixosConfigurations.flooficus.config.incusInstances' \
      # --apply 'x: builtins.mapAttrs (name: inst: {
      #   inherit inst;
      #   desiredHash = builtins.hashString "sha256" "${inst.type}\n${inst.image}\n${builtins.readFile inst.configYaml}";
      # }) x'
      # Deploy-time start order: respects each instance's `startAfter`, independent
      # of Incus's own boot-time `boot.autostart.priority`/`boot.autostart.delay`
      # (which only apply when incusd itself starts, e.g. on host reboot).
      orderedNames = let
        before = a: b: config.incusInstances.${b}.startAfter == a;
        sorted = lib.toposort before (lib.attrNames config.incusInstances);
      in
        sorted.result or (throw "incusInstances: cycle detected in `startAfter`: ${lib.generators.toPretty {} sorted.cycle}");

      mkInstanceEntry = name: let
        inst = config.incusInstances.${name};
        desiredHash = builtins.hashString "sha256" "${inst.type}\n${inst.image}\n${builtins.readFile inst.configYaml}";
        isVm = inst.type == "virtual-machine";
        vmFlag = lib.optionalString isVm "--vm";
        # Only pause here if this instance is actually (re)started below --
        # a no-op reconcile run (nothing changed) shouldn't pay the delay.
        sleepLine = lib.optionalString (inst.startDelaySeconds > 0) "sleep ${toString inst.startDelaySeconds}";
        createVolume = lib.optionalString (inst.dataVolume != null) ''
          incus storage volume show ${inst.dataVolume.pool} ${inst.dataVolume.name} >/dev/null 2>&1 || \
            incus storage volume create ${inst.dataVolume.pool} ${inst.dataVolume.name} size=${inst.dataVolume.size}
        '';
        configureVolume = lib.optionalString (inst.dataVolume != null) (
          lib.concatStringsSep "\n" (
            lib.optional (inst.dataVolume.snapshotSchedule != null)
            "incus storage volume set ${inst.dataVolume.pool} ${inst.dataVolume.name} snapshots.schedule=${lib.escapeShellArg inst.dataVolume.snapshotSchedule}"
            ++ lib.optional (inst.dataVolume.snapshotExpiry != null)
            "incus storage volume set ${inst.dataVolume.pool} ${inst.dataVolume.name} snapshots.expiry=${lib.escapeShellArg inst.dataVolume.snapshotExpiry}"
            ++ lib.optional (inst.dataVolume.snapshotPattern != null)
            "incus storage volume set ${inst.dataVolume.pool} ${inst.dataVolume.name} snapshots.pattern=${lib.escapeShellArg inst.dataVolume.snapshotPattern}"
          )
        );
        # Containers are stateless app instances (data lives in `dataVolume`,
        # not the instance's own root fs), so it's safe to delete and
        # re-init them whenever their definition changes.
        recreateScript = ''
          echo "Definition of Incus instance ${name} changed; recreating"
          if [ "$(incus config get ${name} volatile.last_state.power)" = "RUNNING" ]; then
            was_running=1
          else
            was_running=0
          fi
          incus delete --force ${name}
          incus init --no-profiles ${vmFlag} ${inst.image} ${name} < /etc/incus/instances/${name}.yaml
          incus config set ${name} user.nix-config-hash=${desiredHash}
          if [ "$was_running" = "1" ]; then
            incus start ${name}
            ${sleepLine}
          fi
        '';
        # Virtual machines host a full, stateful OS on their root disk, and
        # boot far slower than containers. Deleting/re-initing one to apply a
        # config change would destroy that disk and force a full cold boot,
        # so instead we only warn and leave `user.nix-config-hash` untouched
        # -- the warning will keep firing on every run until the drift is
        # resolved manually (e.g. `incus config set`/`incus config device
        # set` for in-place changes, or an intentional
        # `incus stop && incus delete` for changes that require a fresh
        # instance).
        vmDriftWarningScript = ''
          echo "WARNING: definition of Incus VM ${name} changed, but virtual machines are never auto-recreated (it would destroy the VM's disk and force a slow reboot). Skipping -- reconcile ${name} manually (e.g. 'incus config set'/'incus config device set', or an intentional 'incus stop ${name} && incus delete ${name}' to let this unit recreate it from scratch)."
        '';
      in ''
        ${createVolume}
        ${configureVolume}
        if ! incus info ${name} >/dev/null 2>&1; then
          echo "Creating Incus instance ${name}"
          incus init --no-profiles ${vmFlag} ${inst.image} ${name} < /etc/incus/instances/${name}.yaml
          incus config set ${name} user.nix-config-hash=${desiredHash}
          ${lib.optionalString inst.autostart "incus start ${name}\n${sleepLine}"}
        elif [ "$(incus config get ${name} user.nix-config-hash)" != "${desiredHash}" ]; then
          ${
          if isVm
          then vmDriftWarningScript
          else recreateScript
        }
        fi
        incus config set ${name} boot.autostart=${lib.boolToString inst.autostart}
      '';
    in {
      # Expose each instance's YAML at a stable path for the unit below.
      environment.etc = lib.mkMerge (lib.mapAttrsToList
        (name: inst: {"incus/instances/${name}.yaml".source = inst.configYaml;})
        config.incusInstances);

      systemd.services.incus-instances = {
        description = "Declaratively create Incus instances";
        after = ["incus.service" "incus-networks.service" "incus-remotes.service"];
        wants = ["incus.service" "incus-networks.service" "incus-remotes.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig.Type = "oneshot";
        serviceConfig.RemainAfterExit = true;
        path = [config.virtualisation.incus.package];
        script = ''
          ${lib.concatMapStringsSep "\n" mkInstanceEntry orderedNames}
        '';
      };
    };
  };
}
