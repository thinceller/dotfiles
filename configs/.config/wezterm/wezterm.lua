local wezterm = require("wezterm")
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

local mux = wezterm.mux

-- resurrect
wezterm.on("gui-startup", resurrect.resurrect_on_gui_startup)
resurrect.periodic_save({ interval_seconds = 15 * 60, save_workspaces = true, save_windows = true, save_tabs = true })

-- for Claude Code notification
wezterm.on("bell", function(window, pane)
  window:toast_notification("Claude Code", "Task completed", nil, 4000)
end)

local act = wezterm.action

local config = {
  -- Font
  font = wezterm.font("HackGen Console NF"),
  font_size = 16.0,

  use_ime = true,
  macos_forward_to_ime_modifier_mask = "SHIFT|CTRL",
  audible_bell = "SystemBeep",

  -- Appearance
  color_scheme = "Night Owl (Gogh)",
  window_background_opacity = 0.8,
  macos_window_background_blur = 10,
  window_decorations = "RESIZE",
  show_new_tab_button_in_tab_bar = false,

  -- Workspace
  default_workspace = "~",

  -- Keybindings
  leader = {
    key = "j",
    mods = "CTRL",
    timeout_milliseconds = 2000,
  },
  keys = {
    {
      key = "p",
      mods = "CMD|SHIFT",
      action = act.ActivateCommandPalette,
    },
    {
      key = "h",
      mods = "LEADER",
      action = act.ActivatePaneDirection("Left"),
    },
    {
      key = "j",
      mods = "LEADER",
      action = act.ActivatePaneDirection("Down"),
    },
    {
      key = "k",
      mods = "LEADER",
      action = act.ActivatePaneDirection("Up"),
    },
    {
      key = "l",
      mods = "LEADER",
      action = act.ActivatePaneDirection("Right"),
    },
    {
      key = "h",
      mods = "LEADER|SHIFT",
      action = act.AdjustPaneSize({ "Left", 5 }),
    },
    {
      key = "j",
      mods = "LEADER|SHIFT",
      action = act.AdjustPaneSize({ "Down", 5 }),
    },
    {
      key = "k",
      mods = "LEADER|SHIFT",
      action = act.AdjustPaneSize({ "Up", 5 }),
    },
    {
      key = "l",
      mods = "LEADER|SHIFT",
      action = act.AdjustPaneSize({ "Right", 5 }),
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
    -- workspace
    {
      key = "s",
      mods = "LEADER",
      action = workspace_switcher.switch_workspace(),
    },
    {
      key = "r",
      mods = "LEADER",
      action = act.PromptInputLine({
        description = wezterm.format({
          { Text = "(wezterm) Rename workspace" },
        }),
        action = wezterm.action_callback(function(_, _, line)
          if line then
            mux.rename_workspace(mux.get_active_workspace(), line)
          end
        end),
      }),
    },
    {
      key = "w",
      mods = "LEADER",
      action = act.PromptInputLine({
        description = wezterm.format({
          { Text = "(wezterm) Create a new workspace" },
        }),
        action = wezterm.action_callback(function(win, pane, line)
          if line then
            win:perform_action(
              act.SwitchToWorkspace({
                name = line,
              }),
              pane
            )
          end
        end),
      }),
    },
    -- resurrect
    {
      key = "s",
      mods = "LEADER|SHIFT",
      action = wezterm.action_callback(function()
        resurrect.save_state(resurrect.workspace_state.get_workspace_state())
        resurrect.window_state.save_window_action()
      end),
    },
    {
      key = "r",
      mods = "LEADER|SHIFT",
      action = wezterm.action_callback(function(win, pane)
        resurrect.fuzzy_load(win, pane, function(id, label)
          local type = string.match(id, "^([^/]+)") -- match before '/'
          id = string.match(id, "([^/]+)$") -- match after '/'
          id = string.match(id, "(.+)%..+$") -- remove file extention
          local opts = {
            relative = true,
            restore_text = true,
            on_pane_restore = resurrect.tab_state.default_on_pane_restore,
          }
          if type == "workspace" then
            local state = resurrect.load_state(id, "workspace")
            resurrect.workspace_state.restore_workspace(state, opts)
          elseif type == "window" then
            local state = resurrect.load_state(id, "window")
            resurrect.window_state.restore_window(pane:window(), state, opts)
          elseif type == "tab" then
            local state = resurrect.load_state(id, "tab")
            resurrect.tab_state.restore_tab(pane:tab(), state, opts)
          end
        end)
      end),
    },
  },
}

bar.apply_to_config(config)

return config
