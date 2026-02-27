{
  flake.modules.homeManager.dev-packages = {pkgs, ...}: {
    # Development packages for software dev specifically
    home.packages = with pkgs; [
      jq # JSON parsing utility
      cachix # nix binary cache

      # Python
      python313
      unstable.poetry
      ruff
      uv

      # pwsh
      powershell

      # Rust
      rustup
      unstable.lld # better linker by LLVM
      unstable.clang
      unstable.mold # even better linker

      # Other
      unstable.devenv # Nix powered dev environments
      mono # for running .NET applications
      granted # Switching AWS Accounts
      sops # Mozilla SOPS
      awscli2 # AWS CLI

    ];
  };
}
