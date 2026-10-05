# mysway

Sway desktop config for Ubuntu 26.04 on an ASUS ROG Zephyrus G16. The config folders
are symlinked into `~/.config`.

| Folder | What |
|---|---|
| `sway/` | Sway config and scripts (screenshot, record, menus) |
| `waybar/` | Bar |
| `foot/`, `fuzzel/` | Terminal, launcher |
| `mpd/` | Music daemon |
| `mpv/` | Video player: uosc UI + thumbfast thumbnails, black/square/blue (`install.sh` fetches scripts, sets default) |
| `yazi/` | File manager: duckdb.yazi table previews for csv/tsv/parquet/xlsx (needs `duckdb` CLI in `~/.local/bin`; plugin patched for DuckDB 1.5 lambda syntax, so `ya pkg upgrade` undoes it) |
| `bottom/` | System monitor `btm`: basic mode (text bars, no graphs), vim keys, black/square/blue; `c`/`m` sort by CPU/memory |
| `ollama/` | Local LLM service override: runs as me with models in `~/.ollama/models` (on /home), flash attention, q8 KV cache, 8K context, unload after 5 min (`install.sh`) |
| `oterm/` | Terminal chat for Ollama on the Copilot key (`sway/scripts/ai-chat`, floating scratchpad window); `ansi-dark` theme follows foot colours. Only `config.json` is symlinked into `~/.local/share/oterm/` (chats live there too) |
| `copyq/` | Clipboard manager settings: no tray, main window hidden on start, black/square/blue theme (`[Theme]` section). Only `copyq.conf` is symlinked into `~/.config/copyq/` (the rest of that folder is history and keys) |
| `grub/` | GRUB theme + kernel params (`install.sh`) |
| `session/` | "Sway (NVIDIA)" login entry (`install.sh`) |
| `applications/` | Launcher-entry overrides, symlinked into `~/.local/share/applications/` (Slack `--disable-gpu`) |
| `udev/` | Hide Windows OS/RESTORE partitions from Nautilus (`install.sh`) |
| `docs/issues/` | Write-ups of problems hit on this machine |

## Known issues

- [HDMI on the RTX 5060, Sway login sessions, main display, Slack with no window](docs/issues/nvidia-hdmi-sway.md)
- [NVMe I/O stalls](https://github.com/dedenbangkit/mysway/issues/1) (GitHub issue)
