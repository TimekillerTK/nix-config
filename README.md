# My Nix Configs <!-- omit in toc -->

- [How to use this project](#how-to-use-this-project)
- [Deploying config on a new host](#deploying-config-on-a-new-host)
  - [From NixOS Installer (disko)](#from-nixos-installer-disko)
  - [With `deploy-rs`](#with-deploy-rs)
  - [With `nixos-anywhere` / `disko`](#with-nixos-anywhere--disko)
  - [Manual Deployment](#manual-deployment)
- [Updating](#updating)
- [Rollbacks](#rollbacks)
  - [Querying Current or Boot Generations](#querying-current-or-boot-generations)
  - [System Rollback](#system-rollback)
  - [Home-Manager Rollback](#home-manager-rollback)

Run the following to apply a configuration:

- For a target System (flakes):
  - `sudo nixos-rebuild switch --flake .#<host>`
- For a target User (home-manager)
  - `home-manager switch --flake .#<username>@<host>`

## How to use this project

TBD...

## Deploying config on a new host

### From NixOS Installer (disko)

0. (optional) If git is missing, run a nix-shell with `git`.
   - `nix-shell -p git`
1. Configure your Git username and email.
   - `git config --global user.name "<username>"`
   - `git config --global user.email "<email>"`
2. Git clone this repository and `cd` into it:
   - `git clone https://github.com/TimekillerTK/nix-config && cd nix-config`
3. Wipe the disk where you want to install NixOS with `wipefs`:
   - `wipefs --all /dev/disk/by-id/<diskId>`
4. Apply disko config to your disks (add `--dry-run` to test config first):
   - `sudo nix run github:nix-community/disko --extra-experimental-features "nix-command flakes" -- --mode disko ./hosts/<host>/disko.nix`
5. Copy the repository to `/mnt` and `cd` into it:
   - `cp -r ../nix-config /mnt/nix-config && cd /mnt/nix-config`
6. Generate a `hardware-configuration.nix` and copy it to the `<host>` directory (where `disko.nix` is):
   - `nixos-generate-config --no-filesystems --root /mnt`
   - `cp /mnt/etc/nixos/hardware-configuration.nix ./hosts/<host>/.`
7. Ensure that `./hosts/<host>/default.nix` is importing the generated `hardware-configuration.nix` in the `imports` section (!).
8. Stage the `hardware-configuration.nix` file, so it's visible during the install:
   - `git add .`
9. Install the NixOS config for this host:
   - `nixos-install --no-root-password --flake .#<host>`
10. Commit the `hardware-configuration.nix` file and push it to the repo:
    - `git checkout -b "install-<host>"`
    - `git commit -m "hardware-configuration.nix for <host>"`
    - `git push`
    - `git push --set-upstream origin "install-<host>"`

### With `deploy-rs`

1. Ensure your **target host** `deployme.cyn.internal` has NixOS installed, and has the following additional options defined in its `configuration.nix`:

   ```nix
   {
      # ...

      # OpenSSH Configuration - will allow SSH access to this machine and allow password auth (temporary!)
      services.openssh = {
         enable = true;
         settings = {
            PermitRootLogin = "no";
            PasswordAuthentication = true;
         };
      };

      # Enable passwordless sudo for the user you're going to be deploying with
      security.sudo.extraRules = [
         {
            users = ["tk"];
            commands = [
               {
                  command = "ALL";
                  options = ["NOPASSWD"];
               }
            ];
         }
      ];

      # Required for deploy-rs if you want to deploy with normal user part of wheel instead of root
      # NOTE: This assumes that the user tk is already part of this group in users.users.tk via extraGroups
      nix.settings.trusted-users = [ "@wheel" ];

      # ...
   }
   ```

2. Run `sudo nixos-rebuild switch` to ensure this configuration is applied.
3. On the machine you want to run `deploy-rs` from, run `ssh-copy-id tk@deployme.cyn.internal` to copy your SSH public key to the target machine.
4. Run `nix run github:serokell/deploy-rs .#deployme` to deploy both the system and home configuration to the target host.

### With `nixos-anywhere` / `disko`

1. Ensure target host has **any** linux distribution installed and:
   - has a static IP Address / Hostname
   - OpenSSH is started
   - `PermitRootLogin` is set to `yes`
2. To pass `sops` secrets, create a temporary directory and insert the secret in the same path which is expected in target host (for example: `/home/tk/.config/sops/age/keys.txt`)
   - Create Temp: `temp=$(mktemp -d)`
   - Create Dir: `install -d -m755 "$temp/home/tk/.secrets/sops/age"`
   - Copy to Temp: `cat ~/.config/sops/age/keys.txt > $temp/home/tk/.secrets/sops/age/keys.txt`
   - Set perms: `chmod 600 "$temp/home/tk/.secrets/sops/age/keys.txt"`
3. Run command to deploy:
   - (without secrets) `nix run github:nix-community/nixos-anywhere -- --flake .#default root@<TARGET HOST IP ADDRESS>`
   - (with secrets) `nix run github:nix-community/nixos-anywhere -- --extra-files "$temp" --flake .#default root@<TARGET HOST IP ADDRESS>`
4. Install `home-manager` with either:
   - Using Flakes:
     - `nix run home-manager/release-23.11 -- init --switch`
   - Regular Method:
     - `nix-channel --add https://github.com/nix-community/home-manager/archive/release-23.11.tar.gz home-manager`
     - `nix-channel --update`
     - `nix-shell '<home-manager>' -A install`
       - If this errors out, log out and log back in
5. Apply a home-manager configuration:
   - `home-manager switch --flake .#tk-linux`
6. Clean up temporary secrets:
   - `rm -rf "$temp"`

> NOTE: If deploying from a Mac, add `--build-on-remote`.

### Manual Deployment

1. Install NixOS
2. Enable Flakes and enter a shell with `git` installed:
   - `export NIX_CONFIG="experimental-features = nix-command flakes"`
   - `nix shell nixpkgs#git`
3. Clone this repository and `cd` into it:
   - `git clone https://github.com/TimekillerTK/nix-config.git && cd nix-config`
4. Overwrite hardware configuration:
   - `sudo cp /etc/nixos/hardware-configuration.nix ./nixos/hardware-configuration.nix`
5. ???
6. Apply a NixOS configuration:
   - `sudo nixos-rebuild switch --flake .#default`
7. Install `home-manager`:
   - `nix-channel --add https://github.com/nix-community/home-manager/archive/release-23.11.tar.gz home-manager`
   - `nix-channel --update`
   - `nix-shell '<home-manager>' -A install`
     - If this errors out, log out and log back in
8. Apply a home-manager configuration:
   - `home-manager switch --flake .#tk-linux`

## Updating

To update a system:

- `nix flake update` - update the flake lockfile
- `sudo nixos-rebuild switch --flake .#` - apply system update
- `home-manager switch --flake .#<username>@<host>` - apply home-manager update ( needs to be applied for every user )

To check the diffs (or what has been updated) in a particular update, use the `nvd` tool:

- `ls /nix/var/nix/profiles/` - list profiles
- `nvd diff /nix/var/nix/profiles/system-{9,10}-link` - show diff between profiles 9 and 10

## Rollbacks

### Querying Current or Boot Generations

To check the current (and/or booted) generation, get the symlink for both `/var/run/booted-system` and `/var/run/current-system`:

- `ls /var/run/*system -ld`

   ```sh
   lrwxrwxrwx - root root  2 apr 06:51  /var/run/booted-system -> /nix/store/v46k3xfjixmv2vmrvz1xmh8494w251cx-nixos-system-anya-24.11.20250307.20755fa/
   lrwxrwxrwx - root root  2 apr 06:51  /var/run/current-system -> /nix/store/v46k3xfjixmv2vmrvz1xmh8494w251cx-nixos-system-anya-24.11.20250307.20755fa/
   ```

Now use the hash in the result (example result is `v46k3xfjixmv2vmrvz1xmh8494w251cx`) to query nix profiles on your system:

- `/nix/var/nix/profiles/system-* -ld | grep v46k3xfjixmv2vmrvz1xmh8494w251cx`

   ```sh
   ls /nix/var/nix/profiles/system-* -ld | grep v46k3xfjixmv2vmrvz1xmh8494w251cx
   lrwxrwxrwx - root root 31 mrt 19:33 /nix/var/nix/profiles/system-117-link -> /nix/store/v46k3xfjixmv2vmrvz1xmh8494w251cx-nixos-system-anya-24.11.20250307.20755fa
   ```

Therefore this example's current system is **generation 117**.

### System Rollback

An older generation can be selected via the boot menu by selecting the previous generation. It is temporary - on reboot the newest generation will be selected again.

To make this temporary change permanent, boot into a selected previous generation and then run:

- `sudo /run/current-system/bin/switch-to-configuration boot`

---

Alternatively, to roll back to a previous NixOS system configuration:

- `nixos-rebuild list-generations` - list available generations

   ```sh
   Generation  Build-date           NixOS version           Kernel  Configuration Revision  Specialisation
   23 current  2024-05-22 06:58:51  23.11.20240520.a8695cb  6.8.10                          *
   22          2024-05-18 23:36:35  23.11.20240328.219951b  6.7.10                          *
   ...
   ```

- `sudo nixos-rebuild switch --rollback` - rollback to the previous generation
- `sudo nix-env --switch-generation xx --profile /nix/var/nix/profiles/system` - rollback to a specific (`xx`) generation

   ```sh
   switching profile from version 117 to 116
   ```

### Home-Manager Rollback

To roll back to a previous home-manager configuration:

- `home-manager generations` - list the generations to get the hash

   ```sh
   2023-12-19 10:27 : id 35 -> /nix/store/2n2qwzd4nv96awfxhiq559b8qd1fy64i-home-manager-generation
   2023-12-19 10:21 : id 34 -> /nix/store/36bl4f7144mc51gjfnn0fh91rhxcclmm-home-manager-generation
   2023-12-19 10:09 : id 33 -> /nix/store/7jfwsq7whhcz3bwcbd0shn84k2b9hm4p-home-manager-generation
   2023-12-19 09:52 : id 32 -> /nix/store/kabsk7zj24jzgx759qzsbrfpgzaam2jn-home-manager-generation
   ...
   ```

- `/nix/store/xxxxxxxxxx-home-manager-generation/activate` - activate a previous generation

