-- Headless service: fires a salawat / dhikr notification every interval.
-- Rotation (not pure random) so reminders don't repeat before the pool cycles.

local reminders = require("./lib/reminders.luau")

local TICK_MS = 30 * 1000
local cursor = 0
local nextFireMs = nil

noctalia.setUpdateInterval(TICK_MS)

local function intervalMs()
  local mins = noctalia.getConfig("interval")
  if type(mins) ~= "number" or mins < 1 then
    mins = 30
  end
  return mins * 60 * 1000
end

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

local function isEnabled()
  return noctalia.state.get("dhikr/enabled") ~= false
end

local function fire()
  local items = pool()
  if #items == 0 then
    return
  end
  cursor = (cursor % #items) + 1
  local item = items[cursor]
  noctalia.state.set("dhikr/latest", item.text)
  noctalia.state.set("dhikr/kind", item.kind)
  noctalia.notify(item.title, item.text)
end

-- Basamalah-equivalent: one salawat greeting shortly after the shell starts.
if noctalia.getConfig("notify_on_start") ~= false then
  local items = pool()
  if #items > 0 then
    local first = items[1]
    noctalia.state.set("dhikr/latest", first.text)
    noctalia.notify(first.title, first.text)
  end
end

function update()
  if not isEnabled() then
    return
  end
  local now = noctalia.nowMs()
  if nextFireMs == nil then
    nextFireMs = now + intervalMs()
    return
  end
  if now >= nextFireMs then
    fire()
    nextFireMs = now + intervalMs()
  end
  local remainMin = math.floor((nextFireMs - now) / 60000)
  noctalia.state.set("dhikr/next_in_min", remainMin)
end

function onIpc(event, _payload)
  if event == "now" then
    fire()
    nextFireMs = noctalia.nowMs() + intervalMs()
  elseif event == "reset" then
    nextFireMs = nil
    cursor = 0
  end
end

function onConfigChanged()
  nextFireMs = nil
end
