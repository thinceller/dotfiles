local wezterm = require 'wezterm'

local mux = wezterm.mux
wezterm.on("gui-startup", function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

local act = wezterm.action

return {
  -- Font
  font = wezterm.font("HackGen Console NF"),
  font_size = 16.0,

  use_ime = true,
  macos_forward_to_ime_modifier_mask = "SHIFT|CTRL",

  -- Apperance
  color_scheme = 'Night Owl (Gogh)',
  window_background_opacity = 0.8,
  macos_window_background_blur = 10,
  window_decorations = "RESIZE",

  -- Keybindings
  leader = {
    key = "j",
    mods = "CTRL",
    timeout_milliseconds = 2000,
  },
  keys = {
    {
      key = "P",
      mods = "CMD",
      action = act.ActivateCommandPalette,
    },
    {
      key = "h",
      mods = "LEADER",
      action = act.ActivatePaneDirection 'Left',
    },
    {
      key = "j",
      mods = "LEADER",
      action = act.ActivatePaneDirection 'Down',
    },
    {
      key = "k",
      mods = "LEADER",
      action = act.ActivatePaneDirection 'Up',
    },
    {
      key = "l",
      mods = "LEADER",
      action = act.ActivatePaneDirection 'Right',
    },
    {
      key = "H",
      mods = "LEADER",
      action = act.AdjustPaneSize { 'Left', 5 },
    },
    {
      key = "J",
      mods = "LEADER",
      action = act.AdjustPaneSize { 'Down', 5 },
    },
    {
      key = "K",
      mods = "LEADER",
      action = act.AdjustPaneSize { 'Up', 5 },
    },
    {
      key = "L",
      mods = "LEADER",
      action = act.AdjustPaneSize { 'Right', 5 },
    },
    {
      key = "q",
      mods = "LEADER",
      action = act.PaneSelect,
    },
    {
      key = "-",
      mods = "LEADER",
      action = act.SplitVertical,
    },
    {
      key = "|",
      mods = "LEADER",
      action = act.SplitHorizontal,
    },
  },
}

