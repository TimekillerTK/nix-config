{
  flake.modules.nixos.ssh = {lib, ...}: {
    # SSH Config
    services.openssh = {
      enable = true;
      knownHosts = {
        "anya" = {
          hostNames = ["anya" "anya.cyn.internal"];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIiYlYEljfXg8k5TzGkmaIyVGBS08ecklxGoozhLMpMj";
        };
        "beltanimal" = {
          hostNames = ["beltanimal" "beltanimal.cyn.internal" "beltanimal-eth.cyn.internal"];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJuqijvqXgfYapPwHtemucjmUL/gcWaISHNFp+DMGrw";
        };
        "dockerhost" = {
          hostNames = ["dockerhost" "dockerhost.cyn.internal"];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIveipqmKwZxOtRUEtr21wsAIcGfVRkE6Wb10zUn0MBr";
        };
        "grafana" = {
          hostNames = ["host.grafana.cyn.internal"];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICt3wRtjmz0t6lv1z4i4+bu5ioApzlJdWQgU/bHDqGCz";
        };
        "hummingbird" = {
          hostNames = ["hummingbird" "hummingbird.cyn.internal"];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfUJfTn9XMuue/W7Pm1T9UpqDBMq3grqyl0+hql+yGc";
        };
        "nix-cache" = {
          hostNames = ["host.nix-cache.cyn.internal"];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKoVhdC5Yye8JRhrJJDrFLwRm98K7di4NwR+Hv2YVMLT";
        };
        "router" = {
          hostNames = ["172.21.10.1" "router" "router.cyn.internal"];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMv2PcJmfab9tBOtlB0VcI3vPgBDGFSn/h4+uw0Z3cqm";
        };
        "vh-server" = {
          hostNames = ["vh-server" "vh-server.cyn.internal"];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHiojMVclIJ8rswJO+obzXFKCrL6lA2SLuM7LztpalZM";
        };
      };
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = lib.mkDefault false;
      };
    };
  };
}
