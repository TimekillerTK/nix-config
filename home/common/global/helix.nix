# Helix Home-Manager IDE Config
{
  pkgs,
  username,
  ...
}: {
  home.packages = with pkgs; [
    unstable.helix # Code Editor

    # Language Servers (and/or similar)
    vscode-langservers-extracted # support for many others
    yaml-language-server
    unstable.nixd # LSP
    pyright # Python
    taplo # TOML
    bash-language-server # bash
    shfmt # shell/bash formatter
    alejandra # Nix Formatter
    nodePackages.prettier # YAML formatter
    typescript-language-server # TypeScript
    wl-clipboard # copy/paste support from system clipboard on Wayland
  ];

  # To stop myself from automatically using `code .`
  programs.zsh.shellAliases = {
    # VS Code CAN be absent or present, so we do not use a nix store path
    # but we still want to ensure we can still run it with `vscode`.
    vscode = "/home/${username}/.nix-profile/bin/code";
    code = "${pkgs.unstable.helix}/bin/hx";
  };

  # Set Helix as the default editor (for git operations and such)
  home.sessionVariables.EDITOR = "hx";

  home.file = {
    # Helix IDE config files
    ".config/helix/config.toml".source = ../../../dotfiles/helix/config.toml;
    ".config/helix/languages.toml".source = ../../../dotfiles/helix/languages.toml;
  };
}
