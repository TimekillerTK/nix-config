# AGENTS.md — nix-config

Personal multi-host NixOS configuration using the **dendritic pattern** with `flake-parts` and `import-tree`.

## Orientation

- `flake.nix` contains almost no logic. Its entire `outputs` is one line:
  ```nix
  outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);
  ```
- `import-tree` recursively imports **every `.nix` file under `modules/`**. There is no central import list. Adding a file is enough — nothing else needs updating.
- All NixOS, home-manager, and package configs are expressed as `flake-parts` options: `flake.modules.nixos.<name>`, `flake.modules.homeManager.<name>`, `flake.modules.generic.<name>`.
- Hosts are registered in `flake.nixosConfigurations` via the helper in `modules/features/lib.nix`:
  ```nix
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "<hostname>";
  ```
- Stable nixpkgs is the current stable channel. Unstable: pkgs.unstable.*. Local packages: pkgs.local.*.

## Developer commands

```sh
# Enter the dev shell (provides git, sops, ssh-to-age, age, nvd, check-all, disko, install-os)
./run-shell

# Validate all nixosConfigurations (eval only — catches type errors, not build failures)
check-all

# Build a host config without applying it (requires NIXPKGS_ALLOW_UNFREE=1 for unfree packages)
NIXPKGS_ALLOW_UNFREE=1 nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --impure

# Apply config on the target host
sudo nixos-rebuild switch --flake .#<hostname>

# Update all flake inputs
nix flake update

# If rebuild fails due to post-build-hook or secret-key-files errors
sudo nixos-rebuild switch --flake .# --option post-build-hook "" --option secret-key-files ""
```

## Adding a new host

1. Create `modules/hosts/<hostname>/configuration.nix`:
   ```nix
   {inputs, ...}: {
     flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "<hostname>";
     flake.modules.nixos.<hostname> = {pkgs, ...}: {
       imports = [ inputs.self.modules.nixos.system-cli ];
       networking.hostName = "<hostname>";
     };
   }
   ```
2. Create `modules/hosts/<hostname>/hardware-configuration.nix` (wrap the generated config in `flake.modules.nixos.<hostname> = {...}: { ... };`).
   Generate on a running system: `sudo nixos-generate-config --show-hardware-config`
3. If using Disko, add `modules/hosts/<hostname>/_disko.nix`.
4. If using ZFS, generate a unique `networking.hostId`: `head -c4 /dev/urandom | od -A none -t x4`
5. Bootstrap the host's SSH key pair and wire it into SOPS — this is the most involved step:

   a. Generate a new ed25519 key pair (no passphrase):
      ```sh
      ssh-keygen -t ed25519 -N "" -f /tmp/ssh_host_ed25519_key
      ```
   b. Derive the age pubkey from the SSH public key:
      ```sh
      ssh-to-age -i /tmp/ssh_host_ed25519_key.pub
      ```
   c. Add the age pubkey to `.sops.yaml` as a named anchor alongside the existing hosts:
      ```yaml
      - &<hostname> age1...
      ```
   d. Add a `path_regex` rule for the new host key file — **master key only** (the host key
      doesn't exist yet at install time, so the host cannot be a recipient of its own key file):
      ```yaml
      - path_regex: secrets/host_keys/<hostname>.ya?ml$
        key_groups:
          - age:
              - *master
      ```
   e. Grant the host access to whichever other secret files it needs by adding `*<hostname>`
      to those `path_regex` entries in `.sops.yaml`, then re-encrypt each affected file:
      ```sh
      sops updatekeys secrets/<file>.yml
      ```
   f. Create the encrypted host key file (SOPS will use `.sops.yaml` to determine recipients):
      ```sh
      sops secrets/host_keys/<hostname>.yml
      ```
      The file must contain exactly two fields:
      ```yaml
      id_ed25519: |
          <contents of /tmp/ssh_host_ed25519_key>
      id_ed25519_pub: <contents of /tmp/ssh_host_ed25519_key.pub>
      ```
   g. Delete the plaintext key files from `/tmp`.

6. `flake.nix` does **not** need to change. `import-tree` picks up the new files automatically.

## Gotchas

### `systems.nix` imports are load-bearing — do not remove them

`modules/features/systems.nix` contains:
```nix
imports = [
  inputs.flake-parts.flakeModules.modules
  inputs.home-manager.flakeModules.home-manager
  inputs.pkgs-by-name-for-flake-parts.flakeModule
];
```

These look like optional boilerplate but are **required**. Here is why:

`systems.nix` accesses `inputs.self.nixosConfigurations` at eval time (to bake the hostname list into the `check-all` script). Building `nixosConfigurations` requires `flake-parts` to merge all `flake.modules.nixos.*` contributions across every file. For `flake-parts` to know the type of the `flake.modules.*` option — and therefore be able to merge them — `flake-parts.flakeModules.modules` must have been imported. Same for `home-manager.flakeModules.home-manager` (`flake.modules.homeManager.*`) and `pkgs-by-name-for-flake-parts.flakeModule` (local packages).

If the imports are missing, Nix recurses trying to resolve the option type while simultaneously trying to evaluate the values that depend on it:

```
error: infinite recursion encountered
       at /nix/store/…/lib/modules.nix:1256:41
```

The error does **not** mention `systems.nix` — it points at `lib/modules.nix`, which is misleading. The root cause is always one of these three imports being absent.

No other file in `modules/` re-declares these imports. If you move or split `systems.nix`, ensure the three `imports` entries land somewhere in the `modules/` tree.

### Packages: use the right overlay prefix

| Source | Access pattern | Defined in |
|---|---|---|
| Stable nixpkgs | `pkgs.<name>` | default |
| Unstable nixpkgs | `pkgs.unstable.<name>` | `modules/features/nixpkgs-unstable.nix` |
| Local (`local-pkgs/`) | `pkgs.local.<name>` | `modules/features/local-pkgs.nix` |
| Caddy 2.8.4 (pinned) | `pkgs.caddy_v284.caddy` | `modules/features/caddy.nix` |

Caddy is pinned to 2.8.4 due to 2.10 incompatibility. Using `pkgs.caddy` on affected hosts will silently give the wrong version.

### `system.stateVersion` is frozen at `"23.11"` — never change it

Both `system.stateVersion` and `home-manager.stateVersion` are hardcoded to `"23.11"` in `modules/system-types/system-base.nix`. This is intentional. Per NixOS convention, `stateVersion` reflects the release at first install and must not be bumped.

### ZFS hosts require a unique `networking.hostId`

Every host using ZFS must declare a unique 8-character hex `networking.hostId`. A missing or duplicate value causes ZFS pool import failures at boot.

```sh
head -c4 /dev/urandom | od -A none -t x4
```

### SOPS secrets use age keys derived from SSH host keys

The host's SSH ed25519 key at `/etc/ssh/ssh_host_ed25519_key` is converted to an age key at boot — not persisted separately. To get the age pubkey for `.sops.yaml`:

```sh
ssh-keyscan -t ed25519 <hostname> | ssh-to-age
```

Edit encrypted files with: `sops secrets/<file>.yml`

### Shell aliases override standard commands on all CLI hosts

On any host using `system-cli` (or `system-desktop`), these aliases are active:

- `cat` → `bat -pp`
- `ls` → `eza`
- `top` / `htop` → `btm`
- `cd` → `z` (zoxide)
- `code` → `hx` (helix); `EDITOR=hx`

Avoid relying on `cat` or `ls` output format in scripts targeting these hosts.

### `check-all` is eval-only

`check-all` (built in the devShell from `scripts/check-all.sh`) runs `nix eval` against each host, not `nix build`. It catches attribute errors and type mismatches but will not surface build failures or missing derivation inputs. Use `nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --impure` for a full build check.
