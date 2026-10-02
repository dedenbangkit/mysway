#!/usr/bin/env bash
# Install the mysway GRUB theme, show the boot menu and boot with logs instead of the splash.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

sudo cp /etc/default/grub /etc/default/grub.bak-mysway
sudo rm -rf /boot/grub/themes/mysway
sudo mkdir -p /boot/grub/themes
sudo cp -r "$here/theme" /boot/grub/themes/mysway

set_var() {  # set_var KEY VALUE  -> KEY=VALUE in /etc/default/grub
  if grep -qE "^#?\s*$1=" /etc/default/grub; then
    sudo sed -i -E "s|^#?\s*$1=.*|$1=$2|" /etc/default/grub
  else
    echo "$1=$2" | sudo tee -a /etc/default/grub >/dev/null
  fi
}
set_var GRUB_TIMEOUT_STYLE menu
set_var GRUB_TIMEOUT 5
set_var GRUB_CMDLINE_LINUX_DEFAULT '""'
set_var GRUB_THEME '"/boot/grub/themes/mysway/theme.txt"'
set_var GRUB_GFXMODE auto

sudo update-grub
echo; grep -E '^GRUB_(TIMEOUT|CMDLINE|THEME|GFX)' /etc/default/grub
