# My Nix Configs <!-- omit in toc -->

- [How to use this project](#how-to-use-this-project)
- [Deploying config on a new host](#deploying-config-on-a-new-host)
  - [From NixOS Installer (disko)](#from-nixos-installer-disko)
  - [With `deploy-rs`](#with-deploy-rs)
  - [With `nixos-anywhere` / `disko`](#with-nixos-anywhere--disko)
  - [Manual Deployment](#manual-deployment)
- [Updating](#updating)
- [Rollback](#rollback)

Run the following to apply a configuration:

- For a target System (flakes):
  - `sudo nixos-rebuild switch --flake .#default`
- For a target User (home-manager)
  - `home-manager switch --flake .#tk-linux`

## How to use this project

TBD...

## Deploying config on a new host

### From NixOS Installer (disko)

1. Git clone this repository and `cd` into it:
   - `git clone https://github.com/TimekillerTK/nix-test && cd nix-test`
2. Wipe disks with `wipefs`:
   - `wipefs --all /dev/disk/by-id/....`
3. Apply disko config to your disks (add `--dry-run` to test config first):
   - `sudo nix run github:nix-community/disko --extra-experimental-features "nix-command flakes" -- --mode disko ./hosts/<host>/disko.nix`
4. Copy the repository to `/mnt` and `cd` into it:
   - `cp -r ../nix-test /mnt/nix-test && cd /mnt/nix-test`
5. Generate a `hardware-configuration.nix` and copy it to the `<host>` directory (where `disko.nix` is):
   - `nixos-generate-config --no-filesystems --root /mnt`
   - `cp /mnt/etc/nixos/hardware-configuration.nix ./hosts/<host>/.`
6. Ensure that `./hosts/<host>/default.nix` is importing the generated `hardware-configuration.nix` in the `imports` section (!).
7. Stage the `hardware-configuration.nix` file, so it's visible during the install:
   - `git add .`  
8. Install the NixOS config for this host:
   - `nixos-install --no-root-password --flake .#<host>`

### With `deploy-rs`

1. Ensure your **target host** `deployme.cyn.local` has NixOS installed, and has the following additional options defined in its `configuration.nix`:

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
3. On the machine you want to run `deploy-rs` from, run `ssh-copy-id tk@deployme.cyn.local` to copy your SSH public key to the target machine.
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
   - `git clone https://github.com/TimekillerTK/nix-test.git && cd nix-test`
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
- `home-manager switch --flake .#user@host` - apply home-manager update ( needs to be applied for every user )

To check the diffs (or what has been updated) in a particular update, use the `nvd` tool:

- `ls /nix/var/nix/profiles/` - list profiles
- `nvd diff /nix/var/nix/profiles/system-{9,10}-link` - show diff between profiles 9 and 10

## Rollback

### System

To roll back to a previous nixos configuration:

- `nixos-rebuild list-generations` - list available generations

   ```sh
   Generation  Build-date           NixOS version           Kernel  Configuration Revision  Specialisation
   23 current  2024-05-22 06:58:51  23.11.20240520.a8695cb  6.8.10                          *
   22          2024-05-18 23:36:35  23.11.20240328.219951b  6.7.10                          *
   ...
   ```

   - `sudo nix-env --list-generations --profile /nix/var/nix/profiles/system` - this also works
- `sudo nixos-rebuild swtich --rollback` - rollback to the previous generation
- `sudo nix-env --switch-generation xx --profile /nix/var/nix/profiles/system` - rollback to a specific generation

### Home-Manager

To roll back to a previous home-manager configuration:

- `home-manager generations` - list the generations

   ```sh
   2023-12-19 10:27 : id 35 -> /nix/store/2n2qwzd4nv96awfxhiq559b8qd1fy64i-home-manager-generation
   2023-12-19 10:21 : id 34 -> /nix/store/36bl4f7144mc51gjfnn0fh91rhxcclmm-home-manager-generation
   2023-12-19 10:09 : id 33 -> /nix/store/7jfwsq7whhcz3bwcbd0shn84k2b9hm4p-home-manager-generation
   2023-12-19 09:52 : id 32 -> /nix/store/kabsk7zj24jzgx759qzsbrfpgzaam2jn-home-manager-generation
   ...
   ```

- `/nix/store/xxxxxxxxxx-home-manager-generation/activate` - activate a previous generation
