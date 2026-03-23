{
  flake.modules.nixos.ssh = {lib, ...}: {
    # SSH Config
    services.openssh = {
      enable = true;
      knownHosts = {
        "anya" = {
          hostNames = ["anya" "anya.cyn.internal"];
          publicKey = "anya.cyn.internal ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIiYlYEljfXg8k5TzGkmaIyVGBS08ecklxGoozhLMpMj";
        };
      };
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = lib.mkDefault false;
      };
    };
  };
}
