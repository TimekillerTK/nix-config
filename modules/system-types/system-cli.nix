{inputs, ...}: {
  # Setting up the system CLI, using home-manager
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
      home-manager
    ];

    # Networking
    networking.networkmanager = {
      enable = true;
    };

    # Default shell used on desktops
    programs.zsh.enable = true;
  };
  flake.modules.homeManager.system-cli = {
    imports = [
      inputs.self.modules.homeManager.system-base
      inputs.self.modules.homeManager.shell
      inputs.self.modules.homeManager.git
      inputs.self.modules.homeManager.helix
      inputs.self.modules.homeManager.starship
      inputs.self.modules.homeManager.yazi
    ];
  };
}
