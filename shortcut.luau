-- Control-center tile: toggles periodic reminders on/off.
-- State is shared with the service via the in-memory channel.

local function isOn()
  return noctalia.state.get("dhikr/enabled") ~= false
end

local function render()
  shortcut.setLabel("Dhikr")
  if isOn() then
    shortcut.setIcon("bell")
  else
    shortcut.setIcon("bell-off")
  end
  shortcut.setActive(isOn())
end

render()

function onClick()
  local on = not isOn()
  noctalia.state.set("dhikr/enabled", on)
  render()
  if on then
    noctalia.notify("Dhikr", "Reminders resumed")
  else
    noctalia.notify("Dhikr", "Reminders paused")
  end
end
