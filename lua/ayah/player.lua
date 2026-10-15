-- Uses mpv > mpg123 > ffplay, falls back to vim.ui.open(url).

local M = {}

M.job_id = nil
M.current_url = nil

local CANDIDATES = {
  mpv = { "mpv", "--no-video", "--really-quiet" },
  mpg123 = { "mpg123", "-q" },
  ffplay = { "ffplay", "-nodisp", "-autoexit", "-loglevel", "quiet" },
}

---@param preferred string|nil
---@return string|nil name, string[]|nil base_cmd
function M.detect(preferred)
  if preferred and CANDIDATES[preferred] and vim.fn.executable(preferred) == 1 then
    return preferred, CANDIDATES[preferred]
  end
  for name, cmd in pairs(CANDIDATES) do
    if vim.fn.executable(name) == 1 then
      return name, cmd
    end
  end
  return nil, nil
end

---@return boolean
function M.is_playing()
  return M.job_id ~= nil
end

function M.stop()
  if M.job_id then
    pcall(vim.fn.jobstop, M.job_id)
    M.job_id = nil
    M.current_url = nil
  end
end

---@param url string
---@param opts {player:string|nil, on_exit:fun()|nil}|nil
function M.play(url, opts)
  opts = opts or {}
  if url == nil or url == "" then
    vim.notify("[ayah] no audio url", vim.log.levels.WARN)
    return
  end
  M.stop()
  local _, base = M.detect(opts.player)
  if not base then
    -- no CLI player: hand off to browser / xdg-open
    vim.ui.open(url)
    return
  end
  local cmd = vim.list_extend(vim.deepcopy(base), { url })
  M.current_url = url
  M.job_id = vim.fn.jobstart(cmd, {
    on_exit = function()
      M.job_id = nil
      M.current_url = nil
      if opts.on_exit then
        vim.schedule(opts.on_exit)
      end
    end,
  })
  if M.job_id <= 0 then
    M.job_id = nil
    vim.notify("[ayah] failed to start audio player", vim.log.levels.ERROR)
  end
end

---@param url string
---@param opts table|nil
function M.toggle(url, opts)
  if M.is_playing() then
    M.stop()
  else
    M.play(url, opts)
  end
end

return M
