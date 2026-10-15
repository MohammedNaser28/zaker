-- Minimal client for https://api.alquran.cloud/v1

local M = {}

M.BASE = "https://api.alquran.cloud/v1"
M.AYAHS_COUNT = 6236

---@class AyahData
---@field number integer global ayah number 1..6236
---@field text string ayah text
---@field surah_name string arabic surah name
---@field surah_english string english surah name
---@field number_in_surah integer
---@field revelation string Makkah|Madinah
---@field audio string audio url
---@field edition string edition identifier
---@field translation string|nil optional second-edition text

local function curl_json(url)
  local res = vim.system({ "curl", "-sL", "--max-time", "15", url }, { text = true }):wait()
  if res.code ~= 0 then
    return nil, "curl exit " .. res.code .. ": " .. (res.stderr or "")
  end
  local ok, decoded = pcall(vim.json.decode, res.stdout)
  if not ok then
    return nil, "invalid JSON from api"
  end
  if decoded.code ~= 200 or decoded.data == nil then
    return nil, "api error: " .. (decoded.status or decoded.message or "unknown")
  end
  return decoded.data, nil
end

---@param data table raw `data` object
---@param fallback_edition string
---@return AyahData
function M.normalize(data, fallback_edition)
  local surah = data.surah or {}
  return {
    number = data.number,
    text = data.text,
    surah_name = surah.name or "",
    surah_english = surah.englishName or "",
    number_in_surah = data.numberInSurah,
    revelation = surah.revelationType or "",
    audio = data.audio or data.audioSecondary or "",
    edition = (data.edition and data.edition.identifier) or fallback_edition,
  }
end

---@param number integer 1..6236
---@param edition string
---@return AyahData|nil, string|nil err
function M.get_ayah(number, edition)
  local data, err = curl_json(("%s/ayah/%d/%s"):format(M.BASE, number, edition))
  if not data then
    return nil, err
  end
  return M.normalize(data, edition), nil
end

---@param edition string
---@return AyahData|nil, string|nil err
function M.get_random(edition)
  -- api has no stable /random endpoint, roll locally like Ayah.getRandomAyah
  local n = math.random(1, M.AYAHS_COUNT)
  return M.get_ayah(n, edition)
end

---@param ayah AyahData
---@param translation_edition string
---@return string|nil err (mutates ayah.translation on success)
function M.attach_translation(ayah, translation_edition)
  if not translation_edition then
    return nil
  end
  local data, err = curl_json(("%s/ayah/%d/%s"):format(M.BASE, ayah.number, translation_edition))
  if not data then
    return err
  end
  ayah.translation = data.text
  return nil
end

return M
