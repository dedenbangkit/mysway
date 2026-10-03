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
| `grub/` | GRUB theme + kernel params (`install.sh`) |
| `session/` | "Sway (NVIDIA)" login entry (`install.sh`) |
| `applications/` | Launcher-entry overrides, symlinked into `~/.local/share/applications/` (Slack `--disable-gpu`) |
| `udev/` | Hide Windows OS/RESTORE partitions from Nautilus (`install.sh`) |
| `docs/issues/` | Write-ups of problems hit on this machine |

## Known issues

- [HDMI on the RTX 5060, Sway login sessions, main display, Slack with no window](docs/issues/nvidia-hdmi-sway.md)
- [NVMe I/O stalls](https://github.com/dedenbangkit/mysway/issues/1) (GitHub issue)
