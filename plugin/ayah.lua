-- plugin/ayah.lua: user commands (loaded automatically by Neovim)
if vim.g.loaded_ayah_nvim then
  return
end
vim.g.loaded_ayah_nvim = 1

local function req(fn, ...)
  local args = { ... }
  return function(opts)
    local nargs = opts and opts.args ~= "" and opts.args or nil
    if nargs then
      require("ayah")[fn](tonumber(nargs) or nargs)
    else
      require("ayah")[fn](unpack(args))
    end
  end
end

vim.api.nvim_create_user_command("AyahNow", function()
  require("ayah").show_random()
end, { desc = "Show a random ayah" })

vim.api.nvim_create_user_command("AyahShow", function(opts)
  require("ayah").show(opts.args ~= "" and tonumber(opts.args) or nil)
end, { nargs = "?", desc = "Show ayah by number, or last" })

vim.api.nvim_create_user_command("AyahDetails", function()
  require("ayah").show_details()
end, { desc = "Open ayah details float" })

vim.api.nvim_create_user_command("AyahNext", function()
  require("ayah").step(1)
end, { desc = "Next ayah" })

vim.api.nvim_create_user_command("AyahPrev", function()
  require("ayah").step(-1)
end, { desc = "Previous ayah" })

vim.api.nvim_create_user_command("AyahPlay", function()
  require("ayah").toggle_play()
end, { desc = "Play/stop current ayah audio" })

vim.api.nvim_create_user_command("AyahCopy", function()
  require("ayah").copy()
end, { desc = "Copy current ayah to clipboard" })

vim.api.nvim_create_user_command("AyahStart", function()
  require("ayah").start()
end, { desc = "Start periodic ayahs" })

vim.api.nvim_create_user_command("AyahStop", function()
  require("ayah").stop()
end, { desc = "Stop periodic ayahs" })
