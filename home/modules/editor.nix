_:
{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      theme = "ayu_dark";
      editor = {
        line-number = "absolute";
        true-color = true;
        rulers = [ 80 120 ];
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
      };
    };
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
  '';
}
