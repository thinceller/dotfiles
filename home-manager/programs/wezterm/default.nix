{ pkgs }:
{
  programs.wezterm = {
    enable = true;

    extraConfig = ''
      local config = {
        font = wezterm.font("HackGen Console NF"),
        font_size = 14.0,

        use_ime = true,
        macos_forward_to_ime_modifier_mask = "SHIFT|CTRL",
        audible_bell = "SystemBeep",

        color_scheme = "Tokyo Night",
        window_background_opacity = 0.85,
        window_decorations = "RESIZE",
        hide_tab_bar_if_only_one_tab = true,

        keys = {
          {
            key = "Enter",
            mods = "SHIFT",
            action = wezterm.action.SendString('\n')
          }
        }
      }

      return config
    '';
  };
}
