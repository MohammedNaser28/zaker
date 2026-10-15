-- Bar widget: shows a dhikr glyph; click fires an immediate reminder.
-- Tooltip previews the latest reminder published by the service.

local reminders = require("./lib/reminders.luau")

local function pool()
  local salawat_on = noctalia.getConfig("salawat_enabled")
  local azkar_on = noctalia.getConfig("azkar_enabled")
  if salawat_on == nil then
    salawat_on = true
  end
  if azkar_on == nil then
    azkar_on = true
  end
  return reminders.collect(salawat_on, azkar_on)
end

function update()
  noctalia.setUpdateInterval(60000)
  barWidget.setGlyph("moon")
  barWidget.setText("ذِكر")
  local latest = noctalia.state.get("dhikr/latest")
  local nextIn = noctalia.state.get("dhikr/next_in_min")
  if latest ~= nil then
    if nextIn ~= nil then
      barWidget.setTooltip({
        { key = "Latest", value = latest },
        { key = "Next in", value = tostring(nextIn) .. " min" },
      })
    else
      barWidget.setTooltip({ { key = "Latest", value = latest } })
    end
  else
    barWidget.setTooltip("Dhikr — click for a reminder now")
  end
end

function onClick()
  local items = pool()
  if #items == 0 then
    return
  end
  local idx = (math.floor(noctalia.nowMs() / 1000) % #items) + 1
  local item = items[idx]
  noctalia.state.set("dhikr/latest", item.text)
  noctalia.notify(item.title, item.text)
end

function onIpc(event, _payload)
  if event == "now" then
    onClick()
  end
end
