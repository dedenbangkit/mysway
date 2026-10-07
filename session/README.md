# Login sessions

`install.sh` (run once; it asks for sudo, safe to re-run):

- installs `sway-nvidia.desktop` → **Sway (NVIDIA)**, which runs `sway-session` (copied to
  `/usr/local/bin`): it sources `~/.paths`, then runs `sway --unsupported-gpu`. GDM starts sessions
  without a login shell, so otherwise sway's PATH lacks `~/.local/bin`, `~/Scripts`, Go, npm, ...
- hides the package's plain **Sway** entry with `dpkg-divert`, so sway updates don't bring it back

The login screen then shows **Sway (NVIDIA)** (daily use) and **Ubuntu** (GNOME fallback).

Why: the HDMI port is on the NVIDIA GPU, and Sway won't start with the NVIDIA driver loaded unless
it gets `--unsupported-gpu`. Full write-up: [docs/issues/nvidia-hdmi-sway.md](../docs/issues/nvidia-hdmi-sway.md).

Bring plain Sway back:

```sh
sudo dpkg-divert --rename --remove /usr/share/wayland-sessions/sway.desktop
```
