{
  inputs,
  self,
  lib,
  ...
}: {
  # TODO: This is not needed if we use home-manager as a NixOS module, is it?
  # Maybe need to open an issue if not
  #
  # If your anya setup works fine without it, maybe you should
  # flake.homeConfigurations = inputs.self.lib.mkHomeManager "x86_64-linux" "tk";

  flake.modules = lib.mkMerge [
    (self.factory.user "tk" true)
    {
      nixos.tk = {
        users.users.tk = {
          extraGroups = ["networkmanager"];
          openssh.authorizedKeys.keys = [
            (builtins.readFile ../../ssh_keys/anya.pub)
            (builtins.readFile ../../ssh_keys/beltanimal.pub)
            (builtins.readFile ../../ssh_keys/mbp.pub)
            (builtins.readFile ../../ssh_keys/hummingbird.pub)
          ];
        };
      };
      homeManager.tk = {pkgs, ...}: {
        imports = [
          inputs.self.modules.homeManager.system-desktop
        ];
        home.username = "tk";

        # # Custom packages for this user
        # home.packages = with pkgs; [
        #   sops # Mozilla SOPS
        #   awscli2 # AWS CLI

        #   # Python
        #   python313
        #   unstable.poetry
        #   ruff
        #   uv

        #   # pwsh
        #   powershell

        #   # Rust
        #   rustup
        #   unstable.lld # better linker by LLVM
        #   unstable.clang
        #   unstable.mold # even better linker

        #   # Desktop Applications
        #   unstable.element-desktop # Matrix client
        #   unstable.makemkv # DVD Ripper
        #   handbrake # Media Transcoder
        #   unstable.xivlauncher # FFXIV Launcher
        #   rustdesk-flutter # TeamViewer alternative
        #   unstable.drawio # Diagram-creating software
        #   syncthingtray # Tray for Syncthing with Dolphin/Plasma integration

        #   # Other
        #   unstable.devenv # Nix powered dev environments
        #   mono # for running .NET applications
        #   granted # Switching AWS Accounts
        #   brave # Chromium-based browser

        #   # Games
        #   unstable.openrct2 # RollerCoaster Tycoon 2
        #   openttd # Transport Tycoon Deluxe
        #   unstable.vintagestory # Vintage Story
        # ];

        # # Syncthing (personal cloud)
        # services.syncthing = {
        #   enable = true;
        # };

        # # DirEnv configuration
        # programs.direnv = {
        #   enable = true;
        #   enableZshIntegration = true;
        #   nix-direnv.enable = true;
        # };

        # TODO: Fix later - input-remapper is defined in hosts/ config, should be home-manager
        # # For automatically launching input-remapper on user login
        # xdg.configFile."autostart/input-mapper-autoload.desktop" = lib.mkIf nixosConfig.services.input-remapper.enable {
        #   source = "${nixosConfig.services.input-remapper.package}/share/applications/input-remapper-autoload.desktop";
        # };

        # home.file = {
        #   # VS Code Settings files as symlinks
        #   ".config/Code/User/keybindings.json".source = ../../dotfiles/vscode/keybindings.json;
        #   ".config/Code/User/settings.json".source = ../../dotfiles/vscode/settings.json;

        #   # Keypad Rebind keys
        #   ".config/input-remapper-2/presets/Razer Razer Nostromo/nostromo.json".source = ../../dotfiles/input-remapper/nostromo.json;
        #   ".config/input-remapper-2/presets/Razer Razer Tartarus V2/tartarus.json".source = ../../dotfiles/input-remapper/tartarus.json;
        # };

        # programs.home-manager.enable = true;
      };
    }
  ];
}
