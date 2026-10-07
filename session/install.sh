#!/usr/bin/env bash
# Add a "Sway (NVIDIA)" login session. Sway refuses to start while the NVIDIA driver is loaded
# unless it gets --unsupported-gpu, and the HDMI port only works with that driver. Safe to re-run.
# See docs/issues/nvidia-hdmi-sway.md.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
sessions=/usr/share/wayland-sessions
sudo install -m 755 "$here/sway-session" /usr/local/bin/sway-session  # loads ~/.paths, then runs sway
sudo install -m 644 "$here/sway-nvidia.desktop" "$sessions/sway-nvidia.desktop"

# Hide the plain "Sway" entry (it can't start with the NVIDIA driver loaded). dpkg-divert keeps
# sway package updates from restoring it. Undo: sudo dpkg-divert --rename --remove $sessions/sway.desktop
if ! dpkg-divert --list "$sessions/sway.desktop" | grep -q .; then
  sudo dpkg-divert --local --rename --divert "$sessions/sway.desktop.diverted" --add "$sessions/sway.desktop"
fi
echo "Log out and pick \"Sway (NVIDIA)\" from the gear menu on the GDM login screen."
