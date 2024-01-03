{ config, pkgs, vscode-pkgs, ... }:

{
  # VS Code 
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;

    # To find an extension, click on extension in VS Code, it will open a link or use nix repl
    extensions = with vscode-pkgs.vscode-marketplace; [

      # Rust
      rust-lang.rust-analyzer

      # Python
      ms-python.python
      ms-python.vscode-pylance
      ms-python.black-formatter
      ms-python.isort

      # Powershell
      ms-vscode.powershell

      # Gitlab
      gitlab.gitlab-workflow

      # AWS
      amazonwebservices.aws-toolkit-vscode

      # Markdown
      yzhang.markdown-all-in-one
      davidanson.vscode-markdownlint

      # Other
      jnoortheen.nix-ide          # Nix Language
      mechatroner.rainbow-csv     # CSV 
      redhat.vscode-yaml          # YAML
      tamasfe.even-better-toml    # TOML
      donjayamanne.githistory     # git history
      ms-vscode-remote.remote-ssh
    ];

    keybindings = [

      # Enable Custom Keybinds
      { key = "ctrl+alt+up"; command = "editor.action.insertCursorAbove"; when = "editorTextFocus"; }
      { key = "ctrl+alt+down"; command = "editor.action.insertCursorBelow"; when = "editorTextFocus"; }
      { key = "shift+alt+up"; command = "editor.action.copyLinesUpAction"; when = "editorTextFocus && !editorReadonly"; }
      { key = "shift+alt+down"; command = "editor.action.copyLinesDownAction"; when = "editorTextFocus && !editorReadonly"; }

      # Disable Default Keybinds
      { key = "ctrl+shift+up"; command = "-editor.action.insertCursorAbove"; when = "editorTextFocus"; }
      { key = "ctrl+shift+down"; command = "-editor.action.insertCursorBelow"; when = "editorTextFocus"; }
      { key = "ctrl+shift+alt+up"; command = "-editor.action.copyLinesUpAction"; when = "editorTextFocus && !editorReadonly"; }
      { key = "ctrl+shift+alt+down"; command = "-editor.action.copyLinesDownAction"; when = "editorTextFocus && !editorReadonly"; }
    
    ];

    userSettings = { 

      # General Settings
      "files.autoSave" = "afterDelay"; 
      "editor.fontFamily" = "'CaskaydiaCove Nerd Font', 'monospace', monospace";
      "editor.fontSize" = 14;
      "editor.suggest.showMethods" = true;
      "editor.suggest.preview" = true;
      "editor.acceptSuggestionOnEnter" = "on";
      "editor.snippetSuggestions" = "top";
      "editor.accessibilitySupport" = "off";
      "explorer.confirmDelete" = false;
      "explorer.confirmDragAndDrop" = false;
      "terminal.integrated.fontFamily" = "monospace";
      "terminal.integrated.fontSize" = 15;
      "security.workspace.trust.untrustedFiles" = "open";
      "problems.showCurrentInStatus" = true;
      "workbench.sideBar.location" = "right";
      "git.autofetch" = true;
      "git.openRepositoryInParentFolders" = "never";

      # Disable Telemetry
      "redhat.telemetry.enabled" = false;
      "aws.telemetry" = false;

      # JSON Settings
      "[json]" = {
        "editor.defaultFormatter" = "vscode.json-language-features";
      };
      "json.schemas" = [];

      # YAML Settings
      "[yaml]" = {
        "editor.insertSpaces" = true;
        "editor.tabSize" = 2;
        "editor.autoIndent" = "advanced";
        "editor.defaultFormatter" = "redhat.vscode-yaml";
      };
      "yaml.schemas" = {};
      "files.associations" = {
        "*.yml" = "yaml";
      };
      "yaml.customTags" = [  # Gitlab & CFN Custom Tags
        "!reference sequence"
        "!And"
        "!And sequence"
        "!If"
        "!If sequence"
        "!Not"
        "!Not sequence"
        "!Equals"
        "!Equals sequence"
        "!Or"
        "!Or sequence"
        "!FindInMap"
        "!FindInMap sequence"
        "!Base64"
        "!Join"
        "!Join sequence"
        "!Cidr"
        "!Ref"
        "!Sub"
        "!Sub sequence"
        "!GetAtt"
        "!GetAZs"
        "!ImportValue"
        "!ImportValue sequence"
        "!Select"
        "!Select sequence"
        "!Split"
        "!Split sequence"
      ];

      # Python Settings
      "[python]" = {
        "editor.wordBasedSuggestions" = false;
        "editor.formatOnType" = true;
        "editor.defaultFormatter" = "ms-python.black-formatter";
        "editor.formatOnSave" = true;
        "editor.codeActionsOnSave" = {
          "source.organizeImports" = true;
        };
      };
      "isort.args" = [
        "--profile"
        "black"
      ];
      "python.linting.mypyEnabled" = false;
      "python.autoComplete.extraPaths" = [];
      "python.analysis.extraPaths" = [];
      "python.analysis.typeCheckingMode" = "basic";

      # Powershell Settings
      "powershell.powerShellAdditionalExePaths" = {
        "pwsh" = "/Users/tk/.nix-profile/bin/pwsh";
      };
      "powershell.powerShellDefaultVersion" = "pwsh";
      "powershell.promptToUpdatePowerShell" = false;

      # AWS Settings
      "aws.samcli.lambdaTimeout" = 91234; # AWS Toolkit complains if this is missing
      "aws.codeWhisperer.shareCodeWhispererContentWithAWS" = false;
      "aws.suppressPrompts" = {
        "apprunnerNotifyPricing" = false;
        "yamlExtPrompt" = true;
        "regionAddAutomatically" = true;
        "codeWhispererConnectionExpired" = true;
        "codeWhispererNewWelcomeMessage" = true;
      };
      "cfnLint.validateUsingJsonSchema" = true;
      "cfnLint.ignoreRules" = [];

      # Markdown Settings
      "markdownlint.config" = {
        "MD033" = false; # HTML in Markdown
        "default" = true;
      };
      "[markdown]" = {
        "editor.defaultFormatter" = "yzhang.markdown-all-in-one";
      };

    };
  };
}