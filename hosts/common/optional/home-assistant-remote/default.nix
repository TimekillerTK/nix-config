{ pkgs, ... }:
{
  # homeassistant user for shutdown via SSH command
  #
  # NOTE: To test if this is working, simply execute:
  # ssh -i /config/ssh/id_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null homeassistant@hostname.cyn.internal "echo 'test successful' > /ha-test/result"
  users = {
    groups = { homeassistant = {}; }; # group for homeassistant user (required)
    users = {
      homeassistant = {
        shell = pkgs.zsh;
        isSystemUser = true;
        group = "homeassistant";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPbyRIFCnKqR6DXV2vJLd9s8JRjnvwyKJWw8VevEzfSC" # anya
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPnvtbzHUSBupBNOeoGlyQ5rT2JCd0FxenGVs53t61dw" # homeassistant
        ];
      };
    };
  };

  # Passwordless sudo for specific binaries for the homeassistant user
  # to allow user to shutdown/reboot/poweroff the machine
  security.sudo.extraRules = [
    {
      users = ["homeassistant"];
      commands = [
        { command = "/run/current-system/sw/bin/shutdown"; options = ["NOPASSWD"]; }
        { command = "/run/current-system/sw/bin/reboot"; options = ["NOPASSWD"]; }
        { command = "/run/current-system/sw/bin/poweroff"; options = ["NOPASSWD"]; }
      ];
    }
  ];
}
