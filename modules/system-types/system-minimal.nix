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
    ];

    # Networking
    networking.networkmanager = {
      enable = true;
    };

    # Default shell used on desktops
    programs.zsh.enable = true;
  };
}
