{ inputs, pkgs, ... }:
let
  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  programs.helix = {
    enable = true;
    package = unstable.helix;
    defaultEditor = true;
    settings = {
      theme = "ayu_dark";
      editor = {
        line-number = "absolute";
        true-color = true;
        rulers = [
          80
          120
        ];
        color-modes = true;
        end-of-line-diagnostics = "hint";
        auto-pairs = true;
        auto-completion = true;
        auto-format = true;

        indent-guides = {
          render = true;
          character = "|";
        };

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        search = {
          smart-case = true;
          wrap-around = true;
        };

        file-picker = {
          hidden = false;
          follow-symlinks = true;
          git-ignore = true;
        };

        statusline = {
          left = [
            "mode"
            "spinner"
            "file-name"
            "file-modification-indicator"
          ];
          right = [
            "diagnostics"
            "selections"
            "position"
            "file-encoding"
          ];
        };

        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };
      };
    };
  };
}
