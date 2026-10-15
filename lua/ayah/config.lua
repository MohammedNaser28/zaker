-- ayah.nvim configuration

---@class AyahBasmalahOpts
---@field enabled boolean show basmalah (ayah 1) on VimEnter
---@field sound boolean auto-play basmalah audio
---@field edition string|nil audio edition override, falls back to `edition`

---@class AyahOpts
---@field interval_minutes integer minutes between random ayahs, 0 disables timer
---@field edition string audio/text edition id, e.g. "ar.abdulbasitmurattal"
---@field translation_edition string|nil extra edition fetched for details view, e.g. "en.asad"
---@field auto_play boolean play audio on every notification
---@field basmalah_on_start AyahBasmalahOpts
---@field audio_player string|nil "mpv"|"mpg123"|"ffplay", nil = auto-detect
---@field notify_level integer vim.log.levels.*
---@field float table win opts: width, height, border

local M = {}

---@type AyahOpts
M.defaults = {
  interval_minutes = 30,
  edition = "ar.abdulbasitmurattal",
  translation_edition = nil,
  auto_play = false,
  basmalah_on_start = {
    enabled = true,
    sound = false,
    edition = nil,
  },
  audio_player = nil,
  notify_level = vim.log.levels.INFO,
  float = {
    width = 0.7, -- fraction of `columns` when < 1, else absolute
    height = 0.4,
    border = "rounded",
  },
}

---@type AyahOpts
M.values = vim.deepcopy(M.defaults)

---@param opts AyahOpts|nil
function M.setup(opts)
  opts = opts or {}
  M.values = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts)
end

---@return AyahOpts
function M.get()
  return M.values
end

return M
