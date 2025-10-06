{
  pkgs,
  bunny_user,
  ...
}: let
  bunny_script = pkgs.writeShellScriptBin "bunny-script" ''
    export BUNNY_USER=${bunny_user}
    export TOOL_KDIALOG="${pkgs.kdePackages.kdialog}/bin/kdialog"
    ${builtins.readFile ./bunny-script.sh}
  '';
  bunny_envvars = pkgs.writeShellScriptBin "bunny-envvars" ''
    export TOOL_PS="${pkgs.procps}/bin/ps"
    export TOOL_RG="${pkgs.unstable.ripgrep}/bin/rg"
    export TOOL_AWK="${pkgs.gawk}/bin/awk"
    ${builtins.readFile ./bunny-envvars.sh}
  '';
in {
  # System Packages
  environment.systemPackages = [
    bunny_envvars
    bunny_script
  ];

  # Files/directories managed by systemd-tmpfiles - these files will be ensured
  # to be present each boot or nix config activation.
  systemd.tmpfiles.rules = [
    "d /homeassistant 770 homeassistant homeassistant -"
    "f /homeassistant/envvars 0660 homeassistant homeassistant -"
  ];

  # homeassistant user for shutdown via SSH command and running scripts
  #
  # NOTE: To test if this is working, simply execute:
  # ssh -i /config/ssh/id_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null homeassistant@hostname.cyn.internal "echo 'test successful' > /ha-test/result"
  users = {
    groups = {homeassistant = {};}; # group for homeassistant user (required)
    users = {
      homeassistant = {
        shell = pkgs.zsh;
        isNormalUser = true;
        group = "homeassistant";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPbyRIFCnKqR6DXV2vJLd9s8JRjnvwyKJWw8VevEzfSC" # anya
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPnvtbzHUSBupBNOeoGlyQ5rT2JCd0FxenGVs53t61dw" # homeassistant
        ];
      };
      ${bunny_user}.extraGroups = ["homeassistant"]; # Needs access, otherwise script will be inaccessible
    };
  };

  security.sudo = {
    extraRules = [
      {
        users = ["homeassistant"];
        commands = [
          # Passwordless sudo for specific binaries for the homeassistant user
          # to allow user to shutdown/reboot/poweroff the machine
          {
            command = "/run/current-system/sw/bin/shutdown";
            options = ["NOPASSWD"];
          }
          {
            command = "/run/current-system/sw/bin/reboot";
            options = ["NOPASSWD"];
          }
          {
            command = "/run/current-system/sw/bin/poweroff";
            options = ["NOPASSWD"];
          }
        ];
      }
      {
        users = ["homeassistant"];
        runAs = bunny_user;
        commands = [
          # Permission to allow running kdialog AS specific user
          {
            command = "${pkgs.kdePackages.kdialog}/bin/kdialog";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
    # Allow specific environment variable usage while using the kdialog command (and only that command)
    extraConfig = ''
      Defaults! ${pkgs.kdePackages.kdialog}/bin/kdialog env_keep += "XDG_RUNTIME_DIR WAYLAND_DISPLAY DBUS_SESSION_BUS_ADDRESS"
    '';
  };

  # systemd service which exports users' environment variables
  systemd.services.bunny_envvars = {
    enable = true;
    description = "Dumps some EnvVars of user to a file, so we can leverage them for bunny-script. Runs when a user logs into a Wayland desktop.";
    requires = ["systemd-logind.service"];
    after = ["systemd-logind.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${bunny_envvars}/bin/bunny-envvars ${bunny_user}";
    };
  };
}
