#!/bin/sh
# Fetch uosc + thumbfast into mpv/ (gitignored), link ~/.config/mpv,
# and make mpv the default video player. Rerun to update the scripts.
set -e
dir=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

curl -fsSLo "$tmp/uosc.zip" https://github.com/tomasklaen/uosc/releases/latest/download/uosc.zip
rm -rf "$dir/scripts/uosc" "$dir/fonts"
unzip -qo "$tmp/uosc.zip" -d "$dir"
rm -f "$dir/scripts/uosc/bin/ziggy-darwin" "$dir/scripts/uosc/bin/ziggy-windows.exe"
curl -fsSLo "$dir/scripts/thumbfast.lua" https://raw.githubusercontent.com/po5/thumbfast/master/thumbfast.lua

if [ -e ~/.config/mpv ] && [ ! -L ~/.config/mpv ]; then
  mv ~/.config/mpv ~/.config/mpv.bak
fi
ln -sfn "$dir" ~/.config/mpv

desktop=/usr/share/applications/mpv.desktop
if [ -f "$desktop" ]; then
  grep '^MimeType=' "$desktop" | cut -d= -f2 | tr ';' '\n' | grep '^video/' |
    xargs xdg-mime default mpv.desktop
fi
echo "mpv: uosc + thumbfast installed, ~/.config/mpv -> $dir"
