{ pkgs, ... }:
{
  programs.helix.languages = {
    language-server = {
      nixd = {
        command = "${pkgs.nixd}/bin/nixd";
      };
      bash-language-server = {
        command = "${pkgs.bash-language-server}/bin/bash-language-server";
        args = [ "start" ];
      };
      pyright = {
        command = "${pkgs.pyright}/bin/pyright-langserver";
        args = [ "--stdio" ];
      };
      ruff = {
        command = "${pkgs.ruff}/bin/ruff";
        args = [ "server" ];
      };
      zls = {
        command = "${pkgs.zls}/bin/zls";
      };
      clangd = {
        command = "${pkgs.clang-tools}/bin/clangd";
        args = [
          "--background-index"
          "--clang-tidy"
          "--completion-style=detailed"
          "--header-insertion=iwyu"
        ];
      };
    };

    language = [
      {
        name = "nix";
        auto-format = true;
        language-servers = [ "nixd" ];
        formatter.command = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";
      }
      {
        name = "bash";
        auto-format = true;
        language-servers = [ "bash-language-server" ];
        formatter = {
          command = "${pkgs.shfmt}/bin/shfmt";
          args = [
            "-i"
            "2"
            "-ci"
            "-bn"
          ];
        };
      }
      {
        name = "python";
        auto-format = true;
        language-servers = [
          "pyright"
          "ruff"
        ];
        formatter = {
          command = "${pkgs.ruff}/bin/ruff";
          args = [
            "format"
            "-"
          ];
        };
      }
      {
        name = "zig";
        auto-format = true;
        language-servers = [ "zls" ];
        formatter = {
          command = "${pkgs.zig}/bin/zig";
          args = [
            "fmt"
            "--stdin"
          ];
        };
      }
      {
        name = "c";
        auto-format = true;
        language-servers = [ "clangd" ];
        formatter = {
          command = "${pkgs.clang-tools}/bin/clang-format";
          args = [
            "--style=file"
            "--fallback-style=LLVM"
          ];
        };
      }
      {
        name = "cpp";
        auto-format = true;
        language-servers = [ "clangd" ];
        formatter = {
          command = "${pkgs.clang-tools}/bin/clang-format";
          args = [
            "--style=file"
            "--fallback-style=LLVM"
          ];
        };
      }
    ];
  };

  # Override ignore patterns with development-specific entries
  xdg.configFile."helix/ignore".text = ''
    .git/
    node_modules/
    target/
    .direnv/
    result
    result-*
    *.tmp
    *.log
    __pycache__/
    *.pyc
    .zig-cache/
    zig-out/
    build/
  '';

  home.packages = with pkgs; [
    # Nix
    nixd
    nixpkgs-fmt
    statix
    deadnix

    # Bash
    bash-language-server
    shfmt
    shellcheck

    # Python
    pyright
    ruff
    python3
    python3Packages.pip
    python3Packages.ipython

    # Zig
    zig
    zls

    # C/C++
    clang
    clang-tools
    cmake
    ninja
    gnumake
    gdb
    lldb

    # General
    tree-sitter
  ];
}
