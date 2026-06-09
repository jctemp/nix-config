{
  inputs,
  osConfig,
  pkgs,
  ...
}:
let
  unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
  nixpkgsChannel = osConfig.system.nixos.release;
in
{
  programs.helix.languages = {
    language-server = {
      nixd = {
        command = "${unstable.nixd}/bin/nixd";
        config.nixd = {
          nixpkgs.expr = ''
            import (builtins.getFlake "github:NixOS/nixpkgs/nixos-${nixpkgsChannel}") { system = "x86_64-linux"; }
          '';
          options = {
            nixos.expr = ''
              let
                nixpkgs = builtins.getFlake "github:NixOS/nixpkgs/nixos-${nixpkgsChannel}";
              in (nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                  (builtins.getFlake "github:Mic92/sops-nix").nixosModules.sops
                  (builtins.getFlake "github:nix-community/impermanence").nixosModules.impermanence
                  (builtins.getFlake "github:nix-community/disko").nixosModules.disko
                  (builtins.getFlake "github:numtide/nixos-facter-modules").nixosModules.facter
                ];
              }).options
            '';
            home-manager.expr = ''
              let
                hm = builtins.getFlake "github:nix-community/home-manager";
                nixpkgs = builtins.getFlake "github:NixOS/nixpkgs/nixos-${nixpkgsChannel}";
              in (hm.lib.homeManagerConfiguration {
                pkgs = import nixpkgs { system = "x86_64-linux"; };
                modules = [{
                  home.stateVersion = "24.11";
                  home.username = "dummy";
                  home.homeDirectory = "/home/dummy";
                }];
              }).options
            '';
          };
        };
      };

      bash-language-server = {
        command = "${unstable.bash-language-server}/bin/bash-language-server";
        args = [ "start" ];
      };
      ty = {
        command = "${unstable.ty}/bin/ty";
        args = [ "server" ];
      };
      pyright = {
        command = "${unstable.pyright}/bin/pyright-langserver";
        args = [ "--stdio" ];
      };
      ruff = {
        command = "${unstable.ruff}/bin/ruff";
        args = [ "server" ];
      };
      zls = {
        command = "${unstable.zls}/bin/zls";
      };
      clangd = {
        command = "${unstable.clang-tools}/bin/clangd";
        args = [
          "--background-index"
          "--clang-tidy"
          "--completion-style=detailed"
          "--header-insertion=iwyu"
        ];
      };
      rust-analyzer = {
        command = "${unstable.rust-analyzer}/bin/rust-analyzer";
      };
      taplo = {
        command = "${unstable.taplo}/bin/taplo";
        args = [
          "lsp"
          "stdio"
        ];
      };
      vscode-json-languageserver = {
        command = "${unstable.vscode-langservers-extracted}/bin/vscode-json-languageserver";
        args = [ "--stdio" ];
      };
      yaml-language-server = {
        command = "${unstable.yaml-language-server}/bin/yaml-language-server";
        args = [ "--stdio" ];
      };
      marksman = {
        command = "${unstable.marksman}/bin/marksman";
        args = [ "server" ];
      };
      tinymist = {
        command = "${unstable.tinymist}/bin/tinymist";
      };
      texlab = {
        command = "${unstable.texlab}/bin/texlab";
      };
    };

    language = [
      {
        name = "nix";
        auto-format = true;
        language-servers = [ "nixd" ];
        formatter.command = "${unstable.nixfmt}/bin/nixfmt";
      }
      {
        name = "bash";
        auto-format = true;
        language-servers = [ "bash-language-server" ];
        formatter = {
          command = "${unstable.shfmt}/bin/shfmt";
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
          "ty"
          "pyright"
          "ruff"
        ];
        formatter = {
          command = "${unstable.ruff}/bin/ruff";
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
          command = "${unstable.zig}/bin/zig";
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
          command = "${unstable.clang-tools}/bin/clang-format";
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
          command = "${unstable.clang-tools}/bin/clang-format";
          args = [
            "--style=file"
            "--fallback-style=LLVM"
          ];
        };
      }
      {
        name = "rust";
        auto-format = true;
        language-servers = [ "rust-analyzer" ];
        formatter = {
          command = "${unstable.rustfmt}/bin/rustfmt";
          args = [
            "--edition"
            "2021"
          ];
        };
      }
      {
        name = "toml";
        auto-format = true;
        language-servers = [ "taplo" ];
        formatter = {
          command = "${unstable.taplo}/bin/taplo";
          args = [
            "fmt"
            "-"
          ];
        };
      }
      {
        name = "json";
        auto-format = true;
        language-servers = [ "vscode-json-languageserver" ];
        formatter = {
          command = "${unstable.prettier}/bin/prettier";
          args = [
            "--parser"
            "json"
          ];
        };
      }
      {
        name = "yaml";
        auto-format = true;
        language-servers = [ "yaml-language-server" ];
        formatter = {
          command = "${unstable.prettier}/bin/prettier";
          args = [
            "--parser"
            "yaml"
          ];
        };
      }
      {
        name = "markdown";
        auto-format = true;
        language-servers = [ "marksman" ];
        formatter = {
          command = "${unstable.prettier}/bin/prettier";
          args = [
            "--parser"
            "markdown"
            "--prose-wrap"
            "always"
          ];
        };
      }
      {
        name = "typst";
        auto-format = true;
        language-servers = [ "tinymist" ];
        formatter = {
          command = "${unstable.typstyle}/bin/typstyle";
          args = [ "--stdout" ];
        };
      }
      {
        name = "latex";
        auto-format = true;
        language-servers = [ "texlab" ];
      }
      {
        name = "bibtex";
        auto-format = true;
        language-servers = [ "texlab" ];
      }
      {
        name = "sql";
        auto-format = true;
        formatter = {
          command = "${unstable.pgformatter}/bin/pg_format";
          args = [
            "--keyword-case"
            "2"
            "--type-case"
            "2"
          ];
        };
      }
    ];
  };

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
    _minted-*/
    *.aux
    *.fls
    *.fdb_latexmk
    *.bbl
    *.blg
    *.toc
    *.out
  '';

  home.packages = with unstable; [
    # Nix
    nixd
    nixfmt
    statix
    deadnix

    # Bash
    bash-language-server
    shfmt
    shellcheck

    # Python
    ty
    pyright
    ruff
    uv
    python3
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

    # Rust
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer

    # TOML
    taplo

    # JSON
    vscode-langservers-extracted
    prettier

    # YAML
    yaml-language-server

    # Markdown
    marksman

    # Typst
    typst
    tinymist
    typstyle

    # LaTeX
    texlive.combined.scheme-medium
    texlab

    # SQL
    pgformatter

    # General
    tree-sitter
  ];

  home.sessionVariables = {
    RUST_SRC_PATH = "${unstable.rust.packages.stable.rustPlatform.rustLibSrc}";
  };
}
