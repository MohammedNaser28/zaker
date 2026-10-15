-- ayah.nvim entry point.

local config = require("ayah.config")
local api = require("ayah.api")
local player = require("ayah.player")
local ui = require("ayah.ui")

local M = {}

M.last_ayah = nil ---@type AyahData|nil
M._timer = nil ---@type userdata|nil
M._detail_win = nil ---@type integer|nil

local function current_edition()
  return config.get().edition
end

local function maybe_translate(ayah)
  local t = config.get().translation_edition
  if t then
    local err = api.attach_translation(ayah, t)
    if err then
      vim.notify("[ayah] translation: " .. err, vim.log.levels.DEBUG)
    end
  end
end

---@param ayah AyahData|nil
---@param err string|nil
local function handle_fetched(ayah, err)
  if err or not ayah then
    vim.notify("[ayah] " .. (err or "fetch failed, check internet"), vim.log.levels.ERROR)
    return
  end
  M.last_ayah = ayah
  local cfg = config.get()
  ui.notify(ayah, cfg.notify_level)
  if cfg.auto_play and ayah.audio ~= "" then
    player.play(ayah.audio, { player = cfg.audio_player })
  end
end

function M.show_random()
  local edition = current_edition()
  local ayah, err = api.get_random(edition)
  if ayah then
    maybe_translate(ayah)
  end
  handle_fetched(ayah, err)
end

---@param number integer|nil global ayah number, nil = last or random
function M.show(number)
  local edition = current_edition()
  local ayah, err
  if number then
    ayah, err = api.get_ayah(number, edition)
  elseif M.last_ayah then
    ayah, err = M.last_ayah, nil
  else
    ayah, err = api.get_random(edition)
  end
  if ayah and number then
    maybe_translate(ayah)
  end
  handle_fetched(ayah, err)
end

function M.show_details()
  if not M.last_ayah then
    M.show_random()
    if not M.last_ayah then
      return
    end
  end
  local ayah = M.last_ayah
  maybe_translate(ayah)
  local cfg = config.get()
  if M._detail_win and vim.api.nvim_win_is_valid(M._detail_win) then
    vim.api.nvim_set_current_win(M._detail_win)
    return
  end
  local bufnr, winid = ui.open_float(ayah, cfg.float)
  M._detail_win = winid

  local function close()
    player.stop()
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_win_close(winid, true)
    end
    M._detail_win = nil
  end

  local function reload(n)
    player.stop()
    local next_ayah, err = api.get_ayah(n, ayah.edition)
    if not next_ayah then
      vim.notify("[ayah] " .. (err or "load failed"), vim.log.levels.ERROR)
      return
    end
    maybe_translate(next_ayah)
    M.last_ayah = next_ayah
    ayah = next_ayah
    close()
    M.show_details()
  end

  local map = function(lhs, rhs)
    vim.keymap.set("n", lhs, rhs, { buffer = bufnr, nowait = true, silent = true })
  end
  map("q", close)
  map("<Esc>", close)
  map("y", function()
    M.copy()
  end)
  map("p", function()
    M.toggle_play()
  end)
  map("]", function()
    if ayah.number < api.AYAHS_COUNT then
      reload(ayah.number + 1)
    end
  end)
  map("[", function()
    if ayah.number > 1 then
      reload(ayah.number - 1)
    end
  end)
end

function M.step(delta)
  local base = M.last_ayah and M.last_ayah.number or math.random(1, api.AYAHS_COUNT)
  local n = math.min(api.AYAHS_COUNT, math.max(1, base + delta))
  local ayah, err = api.get_ayah(n, current_edition())
  if ayah then
    maybe_translate(ayah)
  end
  handle_fetched(ayah, err)
end

function M.copy()
  if not M.last_ayah then
    vim.notify("[ayah] nothing to copy yet", vim.log.levels.WARN)
    return
  end
  vim.fn.setreg("+", M.last_ayah.text)
  vim.fn.setreg('"', M.last_ayah.text)
  vim.notify("[ayah] copied", vim.log.levels.INFO)
end

function M.toggle_play()
  if not M.last_ayah or M.last_ayah.audio == "" then
    vim.notify("[ayah] nothing to play", vim.log.levels.WARN)
    return
  end
  player.toggle(M.last_ayah.audio, { player = config.get().audio_player })
end

function M.start()
  M.stop()
  local mins = config.get().interval_minutes
  if not mins or mins <= 0 then
    return
  end
  M._timer = vim.uv.new_timer()
  M._timer:start(
    1000,
    mins * 60 * 1000,
    vim.schedule_wrap(function()
      M.show_random()
    end)
  )
end

function M.stop()
  if M._timer then
    pcall(function()
      M._timer:stop()
      M._timer:close()
    end)
    M._timer = nil
  end
  player.stop()
end

local function show_basmalah()
  local cfg = config.get()
  local b = cfg.basmalah_on_start
  if not b.enabled then
    return
  end
  local ayah, err = api.get_ayah(1, b.edition or cfg.edition)
  if not ayah then
    vim.notify("[ayah] basmalah: " .. (err or "failed"), vim.log.levels.DEBUG)
    return
  end
  M.last_ayah = ayah
  ui.notify(ayah, cfg.notify_level)
  if b.sound and ayah.audio ~= "" then
    player.play(ayah.audio, { player = cfg.audio_player })
  end
end

---@param opts AyahOpts|nil
function M.setup(opts)
  math.randomseed(os.time())
  config.setup(opts)
  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("AyahNvim", { clear = true }),
    callback = vim.schedule_wrap(show_basmalah),
  })
  M.start()
end

return M
