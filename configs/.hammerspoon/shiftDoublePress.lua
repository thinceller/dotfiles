-- https://gist.github.com/a24k/091bcd2c8f09bb7f41ceeaf926e23574

local alert = require("hs.alert")
local timer = require("hs.timer")
local eventtap = require("hs.eventtap")

local events = eventtap.event.types

local module = {}

-- Save this in your Hammerspoon configuration directiorn (~/.hammerspoon/)
-- You either override timeFrame and action here or after including this file from another, e.g.
--
-- altDoublePress = require("altDoublePress")
-- altDoublePress.timeFrame = 2
-- altDoublePress.action = function()
--    do something special
-- end

-- how quickly must the two single alt taps occur?
module.timeFrame = 1

-- what to do when the double tap of alt occurs
module.action = function()
  alert("You double tapped shift!")
end

-- Synopsis:

-- what we're looking for is 4 events within a set time period and no intervening other key events:
--  flagsChanged with only alt = true
--  flagsChanged with all = false
--  flagsChanged with only alt = true
--  flagsChanged with all = false

local timeFirstControl, firstDown, secondDown = 0, false, false

-- verify that no keyboard flags are being pressed
local noFlags = function(ev)
  local result = true
  for k, v in pairs(ev:getFlags()) do
    if v then
      result = false
      break
    end
  end
  return result
end

-- verify that *only* the alt key flag is being pressed
local onlyShift = function(ev)
  local result = ev:getFlags().shift
  for k, v in pairs(ev:getFlags()) do
    if k ~= "shift" and v then
      result = false
      break
    end
  end
  return result
end

-- the actual workhorse

module.eventWatcher = eventtap
  .new({ events.flagsChanged, events.keyDown }, function(ev)
    -- if it's been too long; previous state doesn't matter
    if (timer.secondsSinceEpoch() - timeFirstControl) > module.timeFrame then
      timeFirstControl, firstDown, secondDown = 0, false, false
    end

    if ev:getType() == events.flagsChanged then
      if noFlags(ev) and firstDown and secondDown then -- alt up and we've seen two, so do action
        if module.action then
          module.action()
        end
        timeFirstControl, firstDown, secondDown = 0, false, false
      elseif onlyShift(ev) and not firstDown then -- alt down and it's a first
        firstDown = true
        timeFirstControl = timer.secondsSinceEpoch()
      elseif onlyShift(ev) and firstDown then -- alt down and it's the second
        secondDown = true
      elseif not noFlags(ev) then -- otherwise reset and start over
        timeFirstControl, firstDown, secondDown = 0, false, false
      end
    else -- it was a key press, so not a lone alt char -- we don't care about it
      timeFirstControl, firstDown, secondDown = 0, false, false
    end
    return false
  end)
  :start()

return module
