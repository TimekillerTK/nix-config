{pkgs, ...}: let
  yaziFlavors = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "flavors";
    rev = "main";
    sha256 = "sha256-RrF97Lg9v0LV+XseJw4RrdbXlv+LJzfooOgqHD+LGcw=";
  };
in {
  programs.yazi = {
    enable = true;
    theme = {
      flavor = {
        dark = "catppuccin-mocha";
        light = "catppuccin-mocha";
      };
    };
  };

  # Install the theme files into the expected path
  home.file.".config/yazi/flavors/catppuccin-mocha.yazi".source = "${yaziFlavors}/catppuccin-mocha.yazi";
}
