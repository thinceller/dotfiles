{ pkgs }:
{
  programs.alacritty = {
    enable = true;

    theme = "tokyo_night";

    settings = {
      # 一般設定
      general = {
        live_config_reload = true;
      };

      # ウィンドウ設定
      window = {
        decorations = "Buttonless";
        # ウィンドウの透明度 (0.0 - 1.0)
        # opacity = 0.85;

        # ウィンドウのパディング
        padding = {
          x = 8;
          y = 8;
        };
      };

      # フォント設定
      font = {
        size = 14.0;

        normal = {
          family = "HackGen Console NF";
          style = "Regular";
        };

        bold = {
          family = "HackGen Console NF";
          style = "Bold";
        };

        italic = {
          family = "HackGen Console NF";
          style = "Italic";
        };
      };

      # カーソル設定
      cursor = {
        style = {
          shape = "Block";
          blinking = "Never";
        };
      };

      # スクロール設定
      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      keyboard = {
        bindings = [
          {
            key = "Return";
            mods = "Shift";
            chars = "\n";
          }
        ];
      };
    };
  };
}
