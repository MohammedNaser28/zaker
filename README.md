# ayah.nvim

Get a verse (ayah) from the Quran during your coding session. Neovim port of [Ayah-intellij](https://github.com/0x61nas/Ayah-intellij).

## Features

- Random ayah via `vim.notify` every N minutes (`vim.uv` timer)
- Basmalah on `VimEnter` (optional + optional sound)
- `:AyahDetails` float: prev/next (`[`/`]`), copy (`y`), play (`p`), close (`q`)
- Audio via `mpv` / `mpg123` / `ffplay`, fallback to `vim.ui.open`
- Copy to `+` register
- Editions from `api.alquran.cloud/v1`

## Requirements

- Neovim >= 0.10 (`vim.system`, `vim.uv`)
- `curl` in PATH
- One of `mpv`, `mpg123`, `ffplay` for audio (optional)

## Install (lazy.nvim)

```lua
{
  "you/ayah.nvim",
  opts = {
    interval_minutes = 30,
    edition = "ar.abdulbasitmurattal",
    translation_edition = "en.asad", -- nil to disable
    auto_play = false,
    basmalah_on_start = { enabled = true, sound = false },
    audio_player = nil, -- auto-detect
  },
}
```

## Commands

```vim
:AyahNow       random ayah now
:AyahShow 2622 show ayah by global number
:AyahDetails   float with prev/next/play/copy
:AyahNext      \
:AyahPrev       next / previous ayah
:AyahPlay      play/stop audio
:AyahCopy      copy text to clipboard
:AyahStart     \
:AyahStop      start / stop timer
```

## Structure

```
lua/ayah/{init,config,api,player,ui}.lua  <- NotificationTimer*, AudioPlayer, AyahDetailsDialog, AyahSettingsState
plugin/ayah.lua                            <- user commands
```

## API parity with Ayah-intellij

| intellij | nvim |
|---|---|
| `StartupActivity` basmalah | `VimEnter` autocmd |
| `Timer.schedule(..., mins)` | `vim.uv.new_timer()` |
| `BALLOON` + Play/Copy/Details | `vim.notify` + `:AyahDetails` float |
| `JLayer` | `mpv`/`mpg123`/`ffplay` job |
| `ayah.xml` | `setup({})` |
