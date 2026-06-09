{
  inputs,
  pkgs,
  ...
}:
let
  unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

in
{
  # Minimal Python: just the notebook infrastructure.
  # Scientific stacks (numpy/torch/polars/...) belong to per-project uv envs,
  # registered as named kernels via `ipykernel install --user --name <proj>`.
  home.packages = with unstable; [
    python3
    python3Packages.ipykernel
    python3Packages.jupyter-client
    python3Packages.jupytext
    python3Packages.euporie
  ];

  # Jupytext: pair .ipynb <-> .py:percent automatically, strip noisy metadata.
  # Authoring happens in Helix on the .py; euporie opens the .ipynb for execution.
  xdg.configFile."jupytext/jupytext.toml".text = ''
    default_notebook_metadata_filter = "-all"
    default_cell_metadata_filter = "-all"
    formats = "ipynb,py:percent"
  '';

  # Euporie: minimal LSP (ruff for diagnostics, pyright for completions),
  # kitty graphics for inline plots where supported (Ghostty), falls back
  # gracefully to sixel/unicode on other terminals. Deliberately not trying
  # to be a full editor — this is an interrogation tool, not an authoring tool.
  xdg.configFile."euporie/euporie.json".text = builtins.toJSON {
    # Appearance
    color_scheme = "default";
    syntax_theme = "ansi_dark";
    background_pattern = 0;
    show_status_bar = true;
    show_cell_borders = true;
    line_numbers = true;

    # Graphics — euporie probes the terminal and degrades if kitty isn't available
    graphics = "kitty";
    tmux_graphics = false;

    # Editing
    autocomplete = true;
    autosuggest = true;
    autoformat = false; # ruff via LSP handles this
    autoinspect = true;

    # LSP — keep it lean. Pyright for completions/hover, ruff for lints.
    # Cross-cell analysis is limited by design; that's what Helix is for.
    language_servers = {
      pyright = {
        command = [
          "${unstable.pyright}/bin/pyright-langserver"
          "--stdio"
        ];
        languages = [ "python" ];
      };
      ruff = {
        command = [
          "${unstable.ruff}/bin/ruff"
          "server"
        ];
        languages = [ "python" ];
      };
    };

    # Kernel behavior
    run_after_external_edit = true; # re-render when Helix edits the paired .py
    save_after_run = false;
  };

  # Convenience wrapper: `nb model.ipynb` opens a notebook in euporie.
  # Kept as a script (not a shell alias) so it's discoverable in $PATH
  # across shells and can be extended later without touching home-manager.
  home.file.".local/bin/nb" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      if [ $# -lt 1 ]; then
        echo "usage: nb <notebook.ipynb>" >&2
        exit 1
      fi
      exec ${unstable.python3}/bin/euporie-notebook "$@"
    '';
  };

  # Console REPL against any registered kernel — useful for send-to-REPL
  # workflows from Helix via Zellij panes.
  home.file.".local/bin/nbconsole" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      exec ${unstable.python3}/bin/euporie-console "$@"
    '';
  };

  home.sessionVariables = {
    # Let jupyter find per-project kernels installed via `ipykernel install --user`
    JUPYTER_PATH = "$HOME/.local/share/jupyter";
  };
}
