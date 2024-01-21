{ config, pkgs, lib, ... }:

let 
  orangeColor = "#f0810e";
  yellowColor = "#f9b931";
  blueColor = "#446e86";
  whiteColor = "#f8f2e6";
  blackColor = "#2f312e";
in 
{
  # Enable Starship for ZSH Terminal
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
  
  programs.starship.settings = {
      format = lib.concatStrings [
        "[](${blueColor})"
        "$os"
        "$username"
        "[](fg:${blueColor} bg:${yellowColor})"
        "$directory"
        "[](fg:${yellowColor} bg:${orangeColor} )"
        "$git_branch"
        "$git_status"
        "[ ](fg:${orangeColor})"

        # "[](${orangeColor})"
        # "$os"
        # "$username"
        # "[](bg:${yellowColor} fg:${orangeColor})"
        # "$directory"
        # "[](fg:${yellowColor} bg:${blueColor})"
        # "$git_branch"
        # "$git_status"
        # "[ ](fg:${blueColor})"

        # "[](fg:${blueColor} bg:#86BBD8)"
        # "$c"
        # "$elixir"
        # "$elm"
        # "$golang"
        # "$gradle"
        # "$haskell"
        # "$java"
        # "$julia"
        # "$nodejs"
        # "$nim"
        # "$rust"
        # "$scala"
        # "[](fg:#86BBD8 bg:#06969A)"
        # "$docker_context"
        # "[](fg:#06969A bg:#33658A)"
        # "$time"
        # "[ ](fg:#33658A)"
      ];

      username = {
        show_always = true;
        style_user = "fg:${blackColor} bg:${orangeColor}";
        style_root = "fg:${blackColor} bg:${orangeColor}";
        format = "[$user ]($style)";
        disabled = true;
      };

      os = {
        style = "fg:${whiteColor} bg:${blueColor}";
        disabled = false;
        symbols = {
          NixOS = " ";
        };
      };
 
      directory = {
        style = "fg:${blackColor} bg:${yellowColor}";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          Documents = "󰈙 ";
          Downloads = " ";
          Music = " ";
          Pictures = " ";
        };
      };

      git_branch = {
        symbol = "";
        style = "fg:${blackColor} bg:${orangeColor}";
        format = "[ $symbol $branch ]($style)";
      };

      git_status = {
        style = "fg:${blackColor} bg:${orangeColor}";
        format = "[$all_status$ahead_behind ]($style)";
      };

      nodejs = {
        symbol = "";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      nim = {
        symbol = "󰆥 ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };
    };
}
