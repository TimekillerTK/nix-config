{
  flake.modules.homeManager.git = {
    # Git configuration
    programs.git = {
      enable = true;

      settings = {
        init.defaultBranch = "main";
        safe.directory = ["/nix-config" "/var/lib/nix-auto-update/repo"];
      };

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
    };

    # For better `git diff` / `git show`
    programs.delta = {
      enable = true;
      options = {
        navigate = true;
        line-numbers = true;
        side-by-side = true;
        syntax-theme = "Dracula";
      };
      enableGitIntegration = true;
    };
  };
}
