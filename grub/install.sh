#!/usr/bin/env bash
# Install the mysway GRUB theme, show the boot menu, boot with logs instead of the splash,
# and use a big (16x32) console font on this 2560x1600 screen. Safe to re-run.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

[[ -e /etc/default/grub.bak-mysway ]] || sudo cp /etc/default/grub /etc/default/grub.bak-mysway
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
# The Micron 2500 behind Intel VMD loses I/O completion interrupts ("timeout, completion polled"), stalling disk I/O.
# APST off alone didn't fix it; also turn off PCIe ASPM, and cut the stall from 30s to 5s when it still happens.
set_var GRUB_CMDLINE_LINUX_DEFAULT '"fbcon=font:TER16x32 nvme_core.default_ps_max_latency_us=0 pcie_aspm=off nvme_core.io_timeout=5"'
set_var GRUB_THEME '"/boot/grub/themes/mysway/theme.txt"'
# "auto" let the firmware pick a low mode, so the theme came out huge; ask for native first
set_var GRUB_GFXMODE 2560x1600x32,1920x1200x32,auto
set_var GRUB_GFXPAYLOAD_LINUX keep

# Console font for TTYs and late boot (kernel font above covers early boot)
[[ -e /etc/default/console-setup.bak-mysway ]] || sudo cp /etc/default/console-setup /etc/default/console-setup.bak-mysway
sudo sed -i -E 's/^FONTFACE=.*/FONTFACE="Terminus"/; s/^FONTSIZE=.*/FONTSIZE="16x32"/' /etc/default/console-setup
sudo update-initramfs -u

sudo update-grub
echo; grep -E '^GRUB_(TIMEOUT|CMDLINE|THEME|GFX)' /etc/default/grub; grep -E '^FONT' /etc/default/console-setup
