{
  # Declarative Incus app instances (OCI images).
  #
  # nixpkgs' `virtualisation.incus` has no option for defining instances —
  # `virtualisation.incus.preseed` only supports server-level entities
  # (config, networks, storage_pools, profiles, projects), never containers/VMs.
  #
  # This module fills that gap with the same bootstrapping idiom used by
  # `incus.nix` for networks/trust: a single oneshot systemd unit that
  # idempotently creates each instance (from its committed YAML config),
  # recreates it whenever its definition changes, and sets `boot.autostart`.
  # Incus itself owns the runtime lifecycle.
  #
  # Convergence works by baking a hash of the instance's `image` + YAML into
  # the unit script. When either changes, the unit file changes and NixOS
  # re-runs it on `switch`; the hash is compared against the instance's
  # `user.nix-config-hash` marker and a mismatch triggers a delete + recreate.
  # A custom `dataVolume` survives recreation (it is a separate volume), so
  # app data persists across image/config upgrades.
  #
  # Instances are created with `--no-profiles`, so no profile (including
  # `default`) is applied. Each instance's YAML must therefore be fully
  # self-contained: root disk, NICs, proxy devices, and any instance-level
  # config (e.g. `security.secureboot=false` for VMs) must all be listed.
  #
  # NOTE: Import this together with `inputs.self.modules.nixos.incus` (it
  # relies on `virtualisation.incus` being enabled).
  flake.modules.nixos.incus-instances = {
    config,
    lib,
    ...
  }: {
    options.incusInstances = lib.mkOption {
      description = ''
        Declarative Incus app instances. Each entry is created (if missing)
        by the `incus-instances` systemd unit, with its config applied from the
        referenced YAML file. If the instance's `image` or YAML changes, the
        instance is deleted and recreated on the next unit run, so the running
        instance always matches the declaration. The YAML file is the full
        instance configuration (see `incus config show <name> --expanded` for
        the syntax).

        Instances are created with `--no-profiles`, so no profile is applied
        and the YAML must be fully self-contained (root disk, NICs, devices,
        and instance-level config).
      '';
      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
          image = lib.mkOption {
            type = lib.types.str;
            description = ''
              OCI image reference, e.g. `ghcr:mealie-recipes/mealie:v3.9.2`.
              The registry must be added as an OCI remote (the `ghcr`/`docker`
              remotes are created by the `incus-remotes` unit in `incus.nix`).
            '';
          };
          configYaml = lib.mkOption {
            type = lib.types.path;
            description = "Path to the instance's YAML configuration.";
          };
          autostart = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Whether the instance should auto-start on boot (maps to the
              instance's `boot.autostart` config). Set to false for on-demand
              start via `incus start <name>`.
            '';
          };
          dataVolume = lib.mkOption {
            type = lib.types.nullOr (lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Name of the custom storage volume to create (and reference from the instance's YAML `source`).";
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
                  description = ''
                    Cron expression or schedule alias for automatic snapshots
                    (e.g. `@daily`, `0 6 * * *`). Null disables automatic
                    snapshots.
                  '';
                };
                snapshotExpiry = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = ''
                    Auto-expiry applied to newly created snapshots, e.g. `1m`
                    (calendar month; note `M` = minute). Null keeps snapshots forever.
                  '';
                };
                snapshotPattern = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = ''
                    Pongo2 template for snapshot names (e.g. `mealie-%d`).
                    Null uses Incus' default (`snap%d`).
                  '';
                };
              };
            });
            default = null;
            description = ''
              Optional custom storage volume, created (if missing) before the
              instance itself so it can be referenced from the instance's
              YAML as a `disk` device `source`. Unlike the instance's root
              volume, this volume is not deleted when the instance is
              deleted, so data survives instance recreation (e.g. image
              upgrades).
            '';
          };
        };
      }));
      default = {};
    };

    config = let
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
      # Expose each instance's YAML config at a stable runtime path for the
      # systemd unit below.
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
