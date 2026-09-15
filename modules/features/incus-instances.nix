{
  # Declarative Incus app instances (OCI images). Requires `modules.nixos.incus`.
  flake.modules.nixos.incus-instances = {
    config,
    lib,
    ...
  }: {
    options.incusInstances = lib.mkOption {
      description = "Declarative Incus instances, created and reconciled by the `incus-instances` unit from each entry's YAML. Instances use `--no-profiles`, so the YAML must be fully self-contained.";
      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
          image = lib.mkOption {
            type = lib.types.str;
            description = "OCI image reference (e.g. `ghcr:mealie-recipes/mealie:v3.9.2`).";
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
      #   desiredHash = builtins.hashString "sha256" "${inst.image}\n${builtins.readFile inst.configYaml}";
      # }) x'
      #
      mkInstanceEntry = name: let
        inst = config.incusInstances.${name};
        desiredHash = builtins.hashString "sha256" "${inst.image}\n${builtins.readFile inst.configYaml}";
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
      in ''
        ${createVolume}
        ${configureVolume}
        if ! incus info ${name} >/dev/null 2>&1; then
          echo "Creating Incus instance ${name}"
          incus init --no-profiles ${inst.image} ${name} < /etc/incus/instances/${name}.yaml
          ${lib.optionalString inst.autostart "incus start ${name}"}
        elif [ "$(incus config get ${name} user.nix-config-hash)" != "${desiredHash}" ]; then
          echo "Definition of Incus instance ${name} changed; recreating"
          if [ "$(incus config get ${name} volatile.last_state.power)" = "RUNNING" ]; then
            was_running=1
          else
            was_running=0
          fi
          incus delete --force ${name}
          incus init --no-profiles ${inst.image} ${name} < /etc/incus/instances/${name}.yaml
          if [ "$was_running" = "1" ]; then
            incus start ${name}
          fi
        fi
        incus config set ${name} user.nix-config-hash ${desiredHash}
        incus config set ${name} boot.autostart ${lib.boolToString inst.autostart}
      '';
    in {
      # Expose each instance's YAML at a stable path for the unit below.
      environment.etc = lib.mkMerge (lib.mapAttrsToList
        (name: inst: {"incus/instances/${name}.yaml".source = inst.configYaml;})
        config.incusInstances);

      systemd.services.incus-instances = {
        description = "Declaratively create Incus app instances";
        after = ["incus.service" "incus-networks.service" "incus-remotes.service"];
        wants = ["incus.service" "incus-networks.service" "incus-remotes.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig.Type = "oneshot";
        serviceConfig.RemainAfterExit = true;
        path = [config.virtualisation.incus.package];
        script = ''
          ${lib.concatMapStringsSep "\n" mkInstanceEntry (lib.attrNames config.incusInstances)}
        '';
      };
    };
  };
}
