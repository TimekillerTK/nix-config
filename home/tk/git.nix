{ outputs, ... }: 
{
  # Git configuration
  programs.git = {
    enable = true;
    userName = "TimekillerTK";
    userEmail = "erwartungen@protonmail.com";
    ignores = [

      # Nix Flakes
      "flake.nix"
      "devenv.local.nix"
      "devenv.nix"
      "devenv.yaml"
      "!flake.lock"
      "!devenv.lock"

      # direnv
      ".envrc"
      ".direnv"

      # devenv
      ".devenv"

      # Python
      "__pycache__"
      ".venv"
      ".pytest_cache"
      ".ruff_cache"
      ".env"

      # JS
      "node_modules"

      # CDK
      ".cdk.staging"
      "cdk.out"

      # Other
      "cdk.context.json"
      ".DS_Store"
    ];

    extraConfig = {
      core.excludesfile = "/home/${outputs.username}/.config/git/ignore";
      init.defaultBranch = "main";
    };

    # Better `git diff` / `git show`
    delta = {
      enable = true;
      options = {
        navigate = true;
        line-numbers = true;
        side-by-side = true;
        syntax-theme = "Dracula";
      };
    };
  };
}