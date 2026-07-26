{
  # Android tools with adb, allows installation of GrapheneOS (for example)
  config.flake.factory.android-adb = {username}: {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      android-tools # provides `adb` and other tools used during GrapheneOS install
    ];

    # adb permissions for your user to do things
    users.users."${username}".extraGroups = ["adbusers" "plugdev" "kvm"];
  };
}
