{inputs, ...}: {
  # Default for all systems
  flake.modules.nixos.system-cli = {pkgs, ...}: {
    imports = [
      inputs.self.modules.nixos.system-base
      inputs.self.modules.nixos.ssh
    ];

    # System Packages
    environment.systemPackages = with pkgs; [
      vim # second best text editor
      nmap # port scanner
      dig # DNS query tool
      nvd # Nix/NixOS package version diff tool
    ];
  };
  flake.modules.homeManager.system-cli = {
    imports = [
      inputs.self.modules.homeManager.system-base
    ];
  };
}
