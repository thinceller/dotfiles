{ pkgs, wezterm-flake }: {
  programs.wezterm = {
    enable = true;
    package = wezterm-flake.packages.${pkgs.system}.default;
    extraConfig = ''
      local mux = wezterm.mux
      wezterm.on("gui-startup", function(cmd)
        local tab, pane, window = mux.spawn_window(cmd or {})
        window:gui_window():maximize()
      end)

      return {
        -- Font
        font = wezterm.font("HackGen Console NF"),
        font_size = 16.0,

        use_ime = true,

        -- Apperance
        color_scheme = 'Night Owl (Gogh)',
        window_background_opacity = 0.8,
        macos_window_background_blur = 10,
        window_decorations = "RESIZE",
      }
    '';
  };
}
