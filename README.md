# My Nix Configs

Run the following to apply a the configuration:

* For a target System (flakes):
    * `sudo nixos-rebuild switch --flake .#default`
* For a target User (home-manager)
    * `home-manager switch --flake .#tk`


## Deploying a config on a new host

For a `NixOS` config:

1. Install NixOS
2. Enable Flakes and enter a shell with `git` installed:
   * `export NIX_CONFIG="experimental-features = nix-command flakes"`
   * `nix shell nixpkgs#git`
3. Clone this repository and `cd` into it:
   * `git clone https://github.com/TimekillerTK/nix-test.git && cd nix-test`
4. Overwrite hardware configuration:
   * `sudo cp /etc/nixos/hardware-configuration.nix ./nixos/hardware-configuration.nix`
5. ???
6. Apply a NixOS configuration:
   * `sudo nixos-rebuild switch --flake .#default`
7. Install `home-manager`:
   * `nix-channel --add https://github.com/nix-community/home-manager/archive/release-23.11.tar.gz home-manager` 
   * `nix-channel --update`
   * `nix-shell '<home-manager>' -A install`
     * If this errors out, log out and log back in
8. Apply a home-manager configuration:
   * `home-manager switch --flake .#tk`


## Updating

To update the system:

* `nix flake update`
* `sudo nixos-rebuild switch --flake .#default`
* `home-manager switch --flake .#tk`

## Rollback

To roll back to a previous home-manager configuration:

* `home-manager generations` - list the generations

    ```
    2023-12-19 10:27 : id 35 -> /nix/store/2n2qwzd4nv96awfxhiq559b8qd1fy64i-home-manager-generation
    2023-12-19 10:21 : id 34 -> /nix/store/36bl4f7144mc51gjfnn0fh91rhxcclmm-home-manager-generation
    2023-12-19 10:09 : id 33 -> /nix/store/7jfwsq7whhcz3bwcbd0shn84k2b9hm4p-home-manager-generation
    2023-12-19 09:52 : id 32 -> /nix/store/kabsk7zj24jzgx759qzsbrfpgzaam2jn-home-manager-generation
    ...
    ```

* `/nix/store/xxxxxxxxxx-home-manager-generation/activate` - activate a previous generation
