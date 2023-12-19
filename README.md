# My Nix Configs

Run the following to apply a configuration:

* For a target System (flakes):
    * `sudo nixos-rebuild switch --flake .#default`
* For a taget User (home-manager)
    * `home-manager switch --flake .#tk`

To update the system:

* `nix flake update`
* `sudo nixos-rebuild switch --flake .#default`
* `home-manager switch --flake .#tk`
