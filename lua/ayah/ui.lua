-- vim.notify + floating window. 

local M = {}

---@param ayah AyahData
---@return string header line
function M.header(ayah)
  local ref = ("#%d • %s (%s) • ayah %d"):format(
    ayah.number,
    ayah.surah_english,
    ayah.surah_name,
    ayah.number_in_surah or 0
  )
  if ayah.revelation and ayah.revelation ~= "" then
    ref = ref .. " • " .. ayah.revelation
  end
  return ref
end

---@param ayah AyahData
---@param level integer|nil
function M.notify(ayah, level)
  vim.notify(ayah.text, level or vim.log.levels.INFO, {
    title = "[ayah] " .. M.header(ayah),
    timeout = 15000,
  })
end

local function resolve_dim(frac_or_abs, total)
  if frac_or_abs < 1 then
    return math.floor(total * frac_or_abs)
  end
  return math.floor(frac_or_abs)
end

---@param ayah AyahData
---@param float_opts table
---@return integer bufnr, integer winid
function M.open_float(ayah, float_opts)
  local width = resolve_dim(float_opts.width or 0.7, vim.o.columns)
  local height = resolve_dim(float_opts.height or 0.4, vim.o.lines)
  local row = math.floor((vim.o.lines - height) / 2 - 1)
  local col = math.floor((vim.o.columns - width) / 2)

  local bufnr = vim.api.nvim_create_buf(false, true)
  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = float_opts.border or "rounded",
    title = " " .. M.header(ayah) .. " ",
    title_pos = "center",
  })

  vim.bo[bufnr].filetype = "ayah"
  vim.bo[bufnr].modifiable = true
  local lines = { ayah.text, "", M.header(ayah) }
  if ayah.translation and ayah.translation ~= "" then
    vim.list_extend(lines, { "", "— " .. ayah.translation })
  end
  vim.list_extend(lines, { "", "[y] copy  [p] play  [ ]/[ ]] prev/next  [q] close" })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(table.concat(lines, "\n"), "\n"))
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].readonly = true

  return bufnr, winid
end

return M
