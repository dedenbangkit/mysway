#!/usr/bin/env bash
# Save/open dialogs: route the FileChooser portal to gtk4-filechooser (classic GTK4 chooser,
# which autocompletes names of files already in the folder). Safe to re-run.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
data="${XDG_DATA_HOME:-$HOME/.local/share}"
mkdir -p "$data/xdg-desktop-portal/portals" "$data/dbus-1/services" "$HOME/.config/xdg-desktop-portal"
ln -sfn "$here/gtk4fc.portal" "$data/xdg-desktop-portal/portals/gtk4fc.portal"
ln -sfn "$here/sway-portals.conf" "$HOME/.config/xdg-desktop-portal/sway-portals.conf"
cat > "$data/dbus-1/services/org.freedesktop.impl.portal.desktop.gtk4fc.service" <<SVC
[D-BUS Service]
Name=org.freedesktop.impl.portal.desktop.gtk4fc
Exec=$here/gtk4-filechooser
SVC
systemctl --user restart xdg-desktop-portal.service
