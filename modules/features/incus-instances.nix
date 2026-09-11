{
  # Declarative Incus app instances (OCI images).
  #
  # nixpkgs' `virtualisation.incus` has no option for defining instances —
  # `virtualisation.incus.preseed` only supports server-level entities
  # (config, networks, storage_pools, profiles, projects), never containers/VMs.
  #
  # This module fills that gap with the same bootstrapping idiom used by
  # `incus.nix` for networks/trust: a single oneshot systemd unit that
  # idempotently creates each instance (from its committed YAML config) and
  # sets `boot.autostart`. Incus itself owns the runtime lifecycle.
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
        referenced YAML file. The YAML file is the full instance configuration
        (see `incus config show <name> --expanded` for the syntax).

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
        createVolume = lib.optionalString (inst.dataVolume != null) ''
          incus storage volume show ${inst.dataVolume.pool} ${inst.dataVolume.name} >/dev/null 2>&1 || \
            incus storage volume create ${inst.dataVolume.pool} ${inst.dataVolume.name} size=${inst.dataVolume.size}
        '';
      in ''
        ${createVolume}
        if ! incus info ${name} >/dev/null 2>&1; then
          incus init --no-profiles ${inst.image} ${name} < /etc/incus/instances/${name}.yaml
        fi
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
