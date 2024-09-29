local double_press = require("shiftDoublePress")

local open_wezterm = function()
  local appName = "com.github.wez.wezterm"
  local app = hs.application.get(appName)

  if app == nil then
    -- FIXME: launchOrFocusByBundleIDでWezTermを起動すると文字化けした状態で起動されてしまう
    -- hs.application.launchOrFocusByBundleID(appName)
    hs.alert("WezTerm is not launched")
  elseif app:isHidden() then
    app:activate()
  elseif not(app:isFrontmost()) then
    app:activate()
  else
    app:hide()
  end
end

double_press.action = open_wezterm
