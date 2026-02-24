{pkgs, ...}: {
  home.username = "user";
  home.homeDirectory = "/home/user";

  home.stateVersion = "23.11";

  home.packages = [
    pkgs.hello
  ];
}
