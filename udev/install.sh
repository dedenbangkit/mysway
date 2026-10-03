#!/usr/bin/env bash
# Install udev rules (hide Windows OS/RESTORE partitions from Nautilus). Safe to re-run.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
sudo install -m 644 "$here"/*.rules /etc/udev/rules.d/
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=block --action=change
echo "Done. Close and reopen Nautilus if the entries are still there."
