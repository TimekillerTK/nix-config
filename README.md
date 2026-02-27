# Nix Config <!-- omit in toc -->

- [Description](#description)
- [Project layout](#project-layout)
- [How to Use](#how-to-use)
  - [Installing a nix configuration](#installing-a-nix-configuration)
  - [Applying a nix configuration](#applying-a-nix-configuration)
  - [Updating a NixOS system](#updating-a-nixos-system)
  - [Rolling back to a previous configuration](#rolling-back-to-a-previous-configuration)
  - [Testing a nix configuration](#testing-a-nix-configuration)

## Description

A reproducible, declarative way of managing my [NixOS](https://nixos.org/) Linux hosts with Nix.

This repository follows the [dendritic Nix configuration pattern](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/tree/main), which promotes a tree-like - or *dendritic* - structure of configuration parts.

This is a complete system configuration for multiple hosts, including servers, desktops, laptops, etc.. using a single [git](https://git-scm.com/) repository.



## Project layout

```sh
.
├── dotfiles/
│   # ^ config files NOT written in nix
├── local-pkgs/
|   # ^ locally packaged software in nix, put outside
|   # modules/ because not using flake-parts
├── modules/
│   ├── features/
|   |   # ^ bluetooth settings, desktop configuration,
|   |   # cli prompt and other building blocks for
|   |   # modules/system-types/ and modules/hosts/
│   ├── hosts/
|   |   # ^ nixos configurations for servers, desktops
|   |   # and all other systems built from
|   |   # modules/features/ and modules/system-types/
│   ├── system-types/
|   |   # ^ types of nixos configurations, using
|   |   # elements from modules/features/ which can
|   |   # be reused as a baseline, such as desktop or
|   |   # server
│   └── users/
|       # ^ user specific settings in nix
├── pub_keys
|   # ^ public ssh keys and certificates
├── scripts
|   # ^ shell scripts and others NOT written in nix
└── secrets
    # ^ SOPS secrets (passwords, sensitive config
    # files, etc...)
```

## How to Use

### Installing a nix configuration

First download any NixOS ISO from https://nixos.org/download/ and put it on a USB drive. Boot into the NixOS installation live environment and then open a terminal:

```sh
# Clone this repository and cd into a directory
git clone https://github.com/TimekillerTK/nix-config && cd nix-config

# Enter the nix shell environment which will acquire needed dependencies for the installation
./run-shell

# Run the installation, where CONFIG is the name of the NixOS configuration to install
sudo install-os CONFIG
```

After these steps are done, reboot and done!

> NOTE: The initial password for login for all users is `Hello123!`

### Applying a nix configuration

NixOS configurations for specific hosts are contained in `modules/hosts/`. To apply a specific configuration (in this example for `anya`):

```sh
sudo nixos-rebuild switch --flake .#<hostname>

# EXAMPLE:
sudo nixos-rebuild switch --flake .#anya
```

### Updating a NixOS system

The automatically generated `flake.lock` file specifies a snapshot in time of [nixpkgs](https://github.com/NixOS/nixpkgs) (and others). To update a system, this file needs to be first updated/regenerated, then `nixos-rebuild` will update the system:

```sh
nix flake update
sudo nixos-rebuild switch --flake .#
```

### Rolling back to a previous configuration

...

### Testing a nix configuration

When modifying nix code, it's nice to be able to check if your modifications are valid and usable.

To test the nix configuration, run the following command to check if it can be built. **If the command completes with no error, the configuration is valid**. Swap `anya` with the name of your target nixos configuration/hostname.

```sh
NIXPKGS_ALLOW_UNFREE=1 nix build .#nixosConfigurations.anya.config.system.build.toplevel --impure
```

> NOTE: This command will take into account both NixOS configurations and home-manager configurations **with this repository's setup specifically.**

This repository was refactored to use the **dendritic pattern** with help from the excellent [Dendritic Design with Flake Parts](https://github.com/Doc-Steve/dendritic-design-with-flake-parts) repository as a guide.
