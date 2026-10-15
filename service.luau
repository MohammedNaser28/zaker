-- Headless service: rotates salawat / azkar reminders, with every Nth
-- reminder a random Quran verse fetched from api.alquran.cloud.
-- Offline pool rotation (no repeats per cycle); Quran turns fall back
-- to the offline pool when the network fails.

local reminders = require("./lib/reminders.luau")
local quran = require("./lib/quran.luau")

local TICK_MS = 30 * 1000
local cursor = 0
local fireCount = 0
local nextFireMs = nil

math.randomseed(noctalia.nowMs())
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

local function quranEvery()
  local n = noctalia.getConfig("quran_every")
  if type(n) ~= "number" or n < 1 then
    n = 3
  end
  return n
end

local function isEnabled()
  return noctalia.state.get("dhikr/enabled") ~= false
end

local function publish(item)
  noctalia.state.set("dhikr/latest", item.text)
  noctalia.state.set("dhikr/kind", item.kind)
  noctalia.notify(item.title, item.text)
end

local function fireOffline()
  local items = pool()
  if #items == 0 then
    return
  end
  cursor = (cursor % #items) + 1
  publish(items[cursor])
end

local function fireQuran()
  local edition = noctalia.getConfig("edition")
  if type(edition) ~= "string" or edition == "" then
    edition = "ar.abdulbasitmurattal"
  end
  local n = math.random(1, quran.AYAHS_COUNT)
  local accepted = noctalia.http({ url = quran.ayahUrl(n, edition) }, function(res)
    if not res.ok or res.status ~= 200 then
      noctalia.log("dhikr quran fetch failed: ok=" .. tostring(res.ok) .. " status=" .. tostring(res.status))
      fireOffline()
      return
    end
    local decoded, err = noctalia.json.decode(res.body)
    if decoded == nil or decoded.code ~= 200 or decoded.data == nil then
      noctalia.log("dhikr quran decode failed: " .. tostring(err))
      fireOffline()
      return
    end
    local ayah = quran.normalize(decoded.data, edition)
    noctalia.log("dhikr quran ok #" .. tostring(ayah.number))
    local body = ayah.text .. "\n\n— " .. quran.header(ayah)
    local trEdition = noctalia.getConfig("translation_edition")
    if type(trEdition) == "string" and trEdition ~= "" then
      noctalia.http({ url = quran.ayahUrl(ayah.number, trEdition) }, function(res2)
        if res2.ok and res2.status == 200 then
          local d2, _ = noctalia.json.decode(res2.body)
          if d2 ~= nil and d2.code == 200 and d2.data ~= nil then
            local t = d2.data.text
            if type(t) == "string" then
              if t:sub(1, 3) == "\239\187\191" then
                t = t:sub(4)
              end
              body = body .. "\n\n— " .. t
            end
          end
        end
        publish({ kind = "quran", title = "📖 آية من القرآن", text = body })
      end)
    else
      publish({ kind = "quran", title = "📖 آية من القرآن", text = body })
    end
  end)
  if not accepted then
    noctalia.log("dhikr quran request not accepted")
    fireOffline()
  end
end

local function fire()
  fireCount = fireCount + 1
  local quranOn = noctalia.getConfig("quran_enabled")
  if quranOn == nil then
    quranOn = true
  end
  if quranOn and (fireCount % quranEvery()) == 0 then
    fireQuran()
  else
    fireOffline()
  end
end

-- Greeting: one salawat shortly after the shell starts.
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
    fireCount = 0
  end
end

function onConfigChanged()
  nextFireMs = nil
end
