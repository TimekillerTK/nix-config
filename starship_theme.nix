{ config, pkgs, lib, ... }:

let 
  orangeColor = "#f0810e";
  yellowColor = "#f9b931";
  blueColor = "#446e86";
  whiteColor = "#f8f2e6";
  blackColor = "#2f312e";
in 
{
  # Pastel Powerline Preset: https://starship.rs/presets/pastel-powerline.html
  programs.starship.settings = {
      format = lib.concatStrings [
        "[](${orangeColor})"
        "$os"
        "$username"
        "[](bg:${yellowColor} fg:${orangeColor})"
        "$directory"
        "[](fg:${yellowColor} bg:${blueColor})"
        "$git_branch"
        "$git_status"
        "[ ](fg:${blueColor})"
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
        disabled = false;
      };

      os = {
        style = "bg:${orangeColor}";
        disabled = true;
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
        style = "fg:${whiteColor} bg:${blueColor}";
        format = "[ $symbol $branch ]($style)";
      };

      git_status = {
        style = "fg:${whiteColor} bg:${blueColor}";
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
      
      time = {
        disabled = false;
        time_format = "%R"; # Hour:Minute Format
        style = "bg:#33658A";
        format = "[ ♥ $time ]($style)";
      };
    };
}