# My Nix Configs <!-- omit in toc -->

- [How to use this project](#how-to-use-this-project)
- [Deploying config on a new host](#deploying-config-on-a-new-host)
  - [With `deploy-rs`:](#with-deploy-rs)
  - [With `nixos-anywhere` / `disko`:](#with-nixos-anywhere--disko)
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


### With `deploy-rs`:

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


### With `nixos-anywhere` / `disko`:

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

To update the system:

- `nix flake update`
- `sudo nixos-rebuild switch --flake .#default`
- `home-manager switch --flake .#tk-linux`

## Rollback

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
