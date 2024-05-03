# This is a reusable module which sets up SOPS for using SSH Host Keys
{ inputs, config, lib, ... }: 
{
  imports = [
    # SOPS
    inputs.sops-nix.nixosModules.sops
  ];

  # Settings
  sops = {
    defaultSopsFile = lib.mkDefault ../secrets.yml;
    age = {
      # This will automatically import SSH keys as age keys
      sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      # This is using an age key that is expected to already be in the filesystem
      keyFile = "/var/lib/sops-nix/key.txt";
      # This will generate a new key if the key specified above does not exist
      generateKey = true;
    };
  };
}