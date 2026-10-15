# Dhikr — Salawat, Azkar & Quran reminders for Noctalia

Periodic desktop notifications reminding you of salawat upon the Prophet ﷺ,
morning/evening azkar, and random Quran verses. Noctalia port of
[ayah.nvim](https://github.com/mohammed-niri/ayah.nvim) (Neovim), extended with
time-aware azkar.

| Plugin | |
|---|---|
| ID | `mohammed-niri/dhikr` |
| Entries | `remind` (service), `dhikr` (widget), `toggle` (shortcut), `find` (launcher) |
| Launcher prefix | `/dhikr` |
| Sources | [azkar-api](https://github.com/nawafalqari/azkar-api) (azkar), [api.alquran.cloud](https://api.alquran.cloud) (Quran) |

## Features

- Salawat upon the Prophet ﷺ + azkar every N minutes (default 30)
- Every Nth reminder (default 3rd) is a random Quran verse (6236, offline fallback on failure)
- Time-aware azkar from `azkar.json`: **أذكار الصباح 04:00–18:00**, **أذكار المساء 18:00–04:00**
- Per-notification counts for morning / evening azkar (panel-controllable, 1–10)
- Salawat greeting on shell start (toggleable)
- Rotation (no repeats before pool cycles), offline-bundled fallback for every source
- Bar widget `ذِكر` (click = instant reminder, tooltip = latest + countdown)
- Control-center tile to pause / resume reminders
- `/dhikr` launcher: fuzzy-search reminders, select copies + notifies

## Settings

Open with `noctalia msg settings-open-plugin mohammed-niri/dhikr`
(or Settings → Plugins → gear on the Dhikr row).

| Key | Type | Default | Effect |
|---|---|---|---|
| `interval` | int (1–180) | `30` | Minutes between notifications |
| `salawat_enabled` | bool | `true` | Include salawat in rotation |
| `azkar_enabled` | bool | `true` | Include azkar in rotation |
| `notify_on_start` | bool | `true` | One salawat when the shell starts |
| `quran_enabled` | bool | `true` | Every Nth reminder is a Quran verse |
| `quran_every` | int (1–20) | `3` | How often the verse appears |
| `edition` | string | `ar.abdulbasitmurattal` | Quran edition id |
| `translation_edition` | string | `""` | Appended translation (e.g. `en.asad`), empty = off |
| `morning_count` | int (1–10) | `3` | Morning azkar per notification |
| `evening_count` | int (1–10) | `3` | Evening azkar per notification |

## Commands

```sh
# install for local dev (repo root IS the plugin dir)
mkdir -p ~/.local/share/noctalia/plugins
ln -s /path/to/ayah.nvim ~/.local/share/noctalia/plugins/dhikr
noctalia msg plugins enable mohammed-niri/dhikr

# fire a reminder now (advances the rotation)
noctalia msg plugin mohammed-niri/dhikr:remind all now

# refetch azkar.json immediately
noctalia msg plugin mohammed-niri/dhikr:remind all refresh

# reset rotation + timer
noctalia msg plugin mohammed-niri/dhikr:remind all reset

# widget: instant reminder on the focused bar
noctalia msg plugin mohammed-niri/dhikr:dhikr focused now

# reload after plugin.toml changes (.luau edits hot-reload on their own)
noctalia msg config-reload

# open this plugin's settings page
noctalia msg settings-open-plugin mohammed-niri/dhikr

# logs (service logs fetch/decode results as dhikr ...)
tail -f ~/.cache/noctalia/noctalia.log | grep dhikr
```

## Structure

```
plugin.toml          <- id, version, entries, settings schema
service.luau         <- timer loop, rotation, Quran turns, azkar turns
widget.luau          <- bar widget (glyph + click for instant reminder)
shortcut.luau        <- control-center pause/resume tile
provider.luau        <- /dhikr launcher search
lib/reminders.luau   <- bundled offline salawat + azkar (fallback)
lib/quran.luau       <- alquran.cloud client + normalize
lib/azkar.luau       <- azkar.json fetch, time category, rotation, format
translations/en.json <- settings labels (required by manifest)
lua/ayah/*           <- legacy Neovim plugin (untouched)
plugin/ayah.lua      <- legacy Neovim user commands
```