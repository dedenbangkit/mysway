# mysway

Sway desktop config for Ubuntu 26.04 on an ASUS ROG Zephyrus G16. The config folders
are symlinked into `~/.config`.

| Folder | What |
|---|---|
| `sway/` | Sway config and scripts (screenshot, record, menus, notes popup: Emacs + org in `~/Orgs`, git `dedenbangkit/orgs`) |
| `waybar/` | Bar |
| `foot/`, `fuzzel/` | Terminal, launcher |
| `mpd/` | Music daemon |
| `mpv/` | Video player: uosc UI + thumbfast thumbnails, black/square/blue (`install.sh` fetches scripts, sets default) |
| `yazi/` | File manager: duckdb.yazi table previews for csv/tsv/parquet/xlsx (needs `duckdb` CLI in `~/.local/bin`; plugin patched for DuckDB 1.5 lambda syntax, so `ya pkg upgrade` undoes it) |
| `bottom/` | System monitor `btm`: basic mode (text bars, no graphs), vim keys, black/square/blue; `c`/`m` sort by CPU/memory |
| `ollama/` | Local LLM as a **user** service, not started at boot: the Copilot key and `summarize` start it, `stop-ollama` stops it. Models in `~/.ollama/models` (on /home), flash attention, q8 KV cache, 8K context, unload after 5 min (`install.sh` links it) |
| `oterm/` | Terminal chat for Ollama on the Copilot key (`sway/scripts/ai-chat`, floating scratchpad window); `launch.py` wraps the pipx install to register a black `sway` theme (fuzzel/mako colours) and hide the header bar; 14pt font. Only `config.json` is symlinked into `~/.local/share/oterm/` (chats live there too) |
| `mako/` | Notifications: only a `do-not-disturb` mode (popups held until it's turned off), toggled by Super+D or the bell after the volume on the top bar |
| `copyq/` | Clipboard manager settings: no tray, main window hidden on start, black/square/blue theme (`[Theme]` section). Only `copyq.conf` is symlinked into `~/.config/copyq/` (the rest of that folder is history and keys) |
| `grub/` | GRUB theme + kernel params (`install.sh`) |
| `gdm/` | Login screen: black background, smaller logo, black/square/blue fields and buttons (`install.sh`) |
| `session/` | "Sway (NVIDIA)" login entry (`install.sh`) |
| `applications/` | Launcher-entry overrides, symlinked into `~/.local/share/applications/` (Slack `--disable-gpu`) |
| `udev/` | Hide Windows OS/RESTORE partitions from Nautilus (`install.sh`) |
| `docs/issues/` | Write-ups of problems hit on this machine |

## Known issues

- [HDMI on the RTX 5060, Sway login sessions, main display, Slack with no window](docs/issues/nvidia-hdmi-sway.md)
- [NVMe I/O stalls](https://github.com/dedenbangkit/mysway/issues/1) (GitHub issue)
