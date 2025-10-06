{
  outputs,
  username,
  gitUser,
  gitEmail,
  ...
}: {
  # Git configuration
  programs.git = {
    enable = true;
    userName = gitUser;
    userEmail = gitEmail;
    ignores = [
      # Nix Flakes
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
      core.excludesfile = "/home/${username}/.config/git/ignore";
      init.defaultBranch = "main";
      safe.directory = ["/nix-config"];
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
