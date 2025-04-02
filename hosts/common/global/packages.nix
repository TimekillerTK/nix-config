{ config, lib, inputs, pkgs, ... }:
{
  # System Packages
  environment.systemPackages = with pkgs; [
    vim # best text editor
    nmap # port scanner
    dig # DNS query tool
    nvd # Nix/NixOS package version diff tool
  ];
}