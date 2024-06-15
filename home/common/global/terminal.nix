{ pkgs, ... }: 
{
  # Alacritty Config (Fast GPU-Accelerated Terminal)
  programs.alacritty = {
    enable = true;
    settings = {
      window.decorations = "None";
      window.opacity = 0.85;
      font.normal.family = "CaskaydiaCove Nerd Font Mono";
      font.normal.style = "Regular";
      font.size = 13.0; 
      # shell.program = "${pkgs.zellij}/bin/zellij"; # Does not work for Zellij, put
      # `eval "$(${pkgs.automate-shell}/bin/zellij setup --generate-auto-start zsh)"`
      # in programs.zsh.initExtra instead
      keyboard.bindings = [
        { key = "F";      mods = "Control";       mode = "~Search";     action = "SearchForward"; }
      ];
    };
  };

}