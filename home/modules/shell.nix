{ pkgs, ... }:
{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      system-rebuild = "sudo nixos-rebuild switch --flake .#desktop";
      home-rebuild = "home-manager switch --flake .#zen";
      ls = "ls --color=auto";
      grep = "grep --color=auto";
      fgrep = "fgrep --color=auto";
      egrep = "egrep --color=auto";
      df = "df -h";
      du = "du -h";
      free = "free -h";
      less = "less -i";
      mkdir = "mkdir -pv";
      ping = "ping -c 3";
      ".." = "cd ..";
    };
    bashrcExtra = ''
      export HISTSIZE=10000
      export HISTFILESIZE=20000
      export HISTCONTROL=ignoreboth:erasedups
    '';
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      character = {
        success_symbol = "[>](bold green)";
        error_symbol = "[x](bold red)";
        vimcmd_symbol = "[<](bold green)";
      };
      git_status = {
        ahead = ">";
        behind = "<";
        diverged = "<>";
        renamed = "r";
        deleted = "x";
      };
      directory.read_only = " ro";
      git_branch.symbol = "git ";
      nix_shell.symbol = "nix ";
      os.symbols.NixOS = "nix ";
    };
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
    config = {
      warn_timeout = "1h";
      load_dotenv = true;
    };
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--border"
    ];
  };

  programs.zellij = {
    enable = true;
    enableBashIntegration = false;
    settings = {
      simplified_ui = true;
      show_startup_tips = false;
      copy_command = "${pkgs.xclip}/bin/xclip -sel clipboard";
    };
  };

  home.packages = with pkgs; [
    gh
    fzf
    fd
    ripgrep
    bat
    eza
    zoxide
  ];

  home.sessionVariables = {
    PAGER = "less";
    LESS = "-R";
  };
}
