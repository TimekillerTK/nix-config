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