{
  flake.modules.homeManager.yazi = {pkgs, ...}: let
    yaziFlavors = pkgs.fetchFromGitHub {
      owner = "yazi-rs";
      repo = "flavors";
      rev = "9e053d0686a7d54a125d67bdd3aabaa5116d6e99";
      sha256 = "sha256-B9b6T9/RkJDkehMC5/MxqnkjxWj5LZg4jehAn6aeamE=";
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
  };
}
