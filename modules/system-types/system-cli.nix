{inputs, ...}: {
  # Default for all systems
  flake.modules.nixos.system-cli = {pkgs, ...}: {
    imports = [
      inputs.self.modules.nixos.system-base
    ];

    # System Packages
    environment.systemPackages = with pkgs; [
      vim # best text editor
      nmap # port scanner
      dig # DNS query tool
      nvd # Nix/NixOS package version diff tool
    ];
  };
}
