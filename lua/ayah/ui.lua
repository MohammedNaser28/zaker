-- vim.notify + floating window. 

local M = {}

-- U+2067 RIGHT-TO-LEFT ISOLATE .. U+2069 POP DIRECTIONAL ISOLATE.
-- Forces an RTL paragraph for the Arabic text even in LTR popups
-- (vim.notify backends like nvim-notify / snacks have no RTL window opt).
local RLI = "\226\129\167" -- U+2067
local PDI = "\226\129\169" -- U+2069

---@param text string
---@return string isolated RTL paragraph
function M.rtl(text)
  return RLI .. text .. PDI
end

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
  vim.notify(M.rtl(ayah.text), level or vim.log.levels.INFO, {
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
  local lines = { M.rtl(ayah.text), "", M.header(ayah) }
  if ayah.translation and ayah.translation ~= "" then
    vim.list_extend(lines, { "", "— " .. ayah.translation })
  end
  vim.list_extend(lines, { "", "[y] copy  [p] play  [ ]/[ ]] prev/next  [q] close" })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(table.concat(lines, "\n"), "\n"))
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].readonly = true

  -- RTL rendering for the Arabic float. `rightleft`/`arabic` are
  -- window-local; `arabicshape`/`termbidi` are global and only enabled
  -- here (never force-disabled) so Arabic joins correctly in terminals
  -- without native bidi. Disable via `setup({ float = { rtl = false } })`.
  vim.wo[winid].wrap = true
  vim.wo[winid].linebreak = true
  vim.wo[winid].number = false
  vim.wo[winid].relativenumber = false
  vim.wo[winid].cursorline = false
  if float_opts.rtl ~= false then
    vim.wo[winid].rightleft = true
    vim.wo[winid].arabic = true
    if vim.o.arabicshape == false then
      vim.o.arabicshape = true
    end
    if vim.o.termbidi == false then
      pcall(function()
        vim.o.termbidi = true
      end)
    end
  end

  return bufnr, winid
end

return M
