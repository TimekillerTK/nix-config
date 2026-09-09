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
  # NOTE: Import this together with `inputs.self.modules.nixos.incus` (it
  # relies on `virtualisation.incus` being enabled).
  flake.modules.nixos.incus-instances = {config, lib, ...}: {
    options.incusInstances = lib.mkOption {
      description = ''
        Declarative Incus app instances. Each entry is created (if missing)
        by the `incus-instances` systemd unit, with its config applied from the
        referenced YAML file. The YAML file is the full instance configuration
        (see `incus config show <name> --expanded` for the syntax).
      '';
      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
          image = lib.mkOption {
            type = lib.types.str;
            description = ''
              OCI image reference, e.g. `ghcr:mealie-recipes/mealie:v3.9.2`.
              The registry must be added as an OCI remote (see the
              `incus-instances` unit for the `ghcr`/`docker` remotes).
            '';
          };
          configYaml = lib.mkOption {
            type = lib.types.path;
            description = "Path to the instance's YAML configuration.";
          };
          autostart = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Whether the instance should auto-start on boot (maps to the
              instance's `boot.autostart` config). Set to false for on-demand
              start via `incus start <name>`.
            '';
          };
        };
      }));
      default = {};
    };

    config = let
      mkInstanceEntry = name: let
        inst = config.incusInstances.${name};
      in ''
        if ! incus info ${name} >/dev/null 2>&1; then
          incus init ${inst.image} ${name} < /etc/incus/instances/${name}.yaml
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
        after = ["incus.service" "incus-networks.service"];
        wants = ["incus.service" "incus-networks.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig.Type = "oneshot";
        serviceConfig.RemainAfterExit = true;
        path = [config.virtualisation.incus.package];
        script = ''
          # OCI image remotes (idempotent)
          incus remote show ghcr >/dev/null 2>&1 || \
            incus remote add ghcr https://ghcr.io --protocol=oci
          incus remote show docker >/dev/null 2>&1 || \
            incus remote add docker https://docker.io --protocol=oci

          ${lib.concatMapStringsSep "\n" mkInstanceEntry (lib.attrNames config.incusInstances)}
        '';
      };
    };
  };
}
