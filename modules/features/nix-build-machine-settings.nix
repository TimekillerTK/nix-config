{...}: {
  # For defining one of our hosts as a build machine
  flake.modules.nixos.nix-build-machine-settings = {
    pkgs,
    lib,
    ...
  }: let
    cache_dns_name = "host.nix-cache.cyn.internal";
    ssh_host_alias = "upload-build-to-nix-cache-server";
  in {
    # --------------------------------------------------------------------------
    # NOTE: For debugging this build hook, run a test build command first:
    #   nix build --impure --expr '(import <nixpkgs> {}).writeText "example" (builtins.toString builtins.currentTime)' -v --print-out-paths --print-build-logs
    #
    # Once completed, inspect the ts logs by first running (sudo because it is run as root):
    #   sudo ts -l
    #
    # This will give a list of jobs. Simply find the relevant one, which has a path to the log
    # file.
    # --------------------------------------------------------------------------
    # This is a build machine for all of our x86-64_linux builds, so here's a
    # post build hook for that purpose
    nix.settings.post-build-hook = lib.getExe (pkgs.writeShellApplication {
      name = "post-build-hook";
      runtimeInputs = with pkgs; [ts nix findutils iputils];
      text = ''
        set -u # use of unset variables = error
        set -f # disable globbing
        export IFS=' '
        export CACHE_HOST="${cache_dns_name}"

        # If our host is down, we still want everything to work as
        # normal
        if ! ping -c 1 $CACHE_HOST > /dev/null 2>&1; then
          echo "Ping to $CACHE_HOST failed, skipping upload." >&2
          exit 0
        fi

        if [[ -n "''${OUT_PATHS:-}" ]]; then
          export TS_MAXFINISHED=1000
          export TS_SLOTS=10

          echo "Uploading $OUT_PATHS"
          printf "%s" "$OUT_PATHS" \
          | xargs ts nix copy --to "ssh://${ssh_host_alias}"
        fi
      '';
    });

    # NOTE: Must be the same as the cache.signKeyPaths for the harmonia
    # nix-cache server
    #
    # Secret Key for signing, important since we'll be building
    # packages on this machine intended for the harmonia nix-cache
    # server
    sops.secrets.harmonia_key = {
      sopsFile = ../../secrets/harmonia_key.yml;
    };
    nix.settings.secret-key-files = [
      "/run/secrets/harmonia_key"
    ];

    # NOTE: This is NOT for OpenSSH server, it's for the local
    # ssh config on this machine accessible by ALL users, but
    # still only usable by root
    #
    # SSH config used by nix daemon (which runs as root), to
    # upload nix packages to the nix-cache server
    programs.ssh.extraConfig = ''
      Host ${ssh_host_alias}
        HostName ${cache_dns_name}
        User builder
        IdentityFile /root/.ssh/id_ed25519
        IdentitiesOnly yes
        Port 22
    '';
  };
}
