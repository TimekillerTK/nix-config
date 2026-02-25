{inputs, ...}: {
  # Minimal setup for a system cli, without using home-manager
  flake.modules.nixos.system-minimal = {pkgs, ...}: {
    imports = [
      inputs.self.modules.nixos.system-base
      inputs.self.modules.nixos.ssh
    ];
    # System Packages
    environment.systemPackages = with pkgs; [
      unstable.helix # second best text editor
      nmap # port scanner
      dig # DNS query tool
      nvd # Nix/NixOS package version diff tool
      git
    ];

    # Networking
    networking.networkmanager = {
      enable = true;
    };

    # Needed since it's our users default shell
    programs.zsh = {
      enable = true;
      initContent = ''
        # These fix zsh CTRL+LEFT & CTRL+RIGHT keybindings for
        # jumping by word
        bindkey '^[[1;5C' forward-word
        bindkey '^[[1;5D' backward-word
      '';
    };
  };
}
