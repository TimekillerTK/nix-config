{inputs, ...}: {
  # Minimal setup for a system cli, without using home-manager
  flake.modules.nixos.system-minimal = {pkgs, ...}: {
    imports = [
      inputs.self.modules.nixos.system-base
      inputs.self.modules.nixos.secrets
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
  };
  flake.modules.homeManager.system-minimal = {
    imports = [
      inputs.self.modules.homeManager.system-base
    ];
  };
}
