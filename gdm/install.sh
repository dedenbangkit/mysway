#!/usr/bin/env bash
# Login screen (GDM): black background, smaller logo and black/square/blue fields and buttons. Safe to re-run.
#   LOGO_WIDTH=260 ./install.sh   -> logo width in logical px (default 300)
# Builds a copy of Yaru's GDM theme with login.css appended and registers it as the
# gdm-theme.gresource alternative, so the GNOME session's own theme is untouched.
# Re-run after a yaru-theme-gnome-shell upgrade to pick up Yaru's changes.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
width="${LOGO_WIDTH:-300}"
yaru=/usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource
dest=/usr/share/gnome-shell/theme/mysway
build="$(mktemp -d)"; trap 'rm -rf "$build"' EXIT

# Theme: extract Yaru, append our CSS to gdm.css (the stylesheet GDM mode loads), recompile
prefix=/org/gnome/shell/theme
{ echo '<?xml version="1.0" encoding="UTF-8"?>'; echo "<gresources><gresource prefix=\"$prefix\">"; } > "$build/theme.xml"
for res in $(gresource list "$yaru"); do
  rel="${res#$prefix/}"
  mkdir -p "$build/src/$(dirname "$rel")"
  gresource extract "$yaru" "$res" > "$build/src/$rel"
  echo "<file>$rel</file>" >> "$build/theme.xml"
done
echo '</gresource></gresources>' >> "$build/theme.xml"
cat "$here/login.css" >> "$build/src/gdm.css"
glib-compile-resources --sourcedir="$build/src" --target="$build/gdm-theme.gresource" "$build/theme.xml"
sudo install -Dm644 "$build/gdm-theme.gresource" "$dest/gdm-theme.gresource"
sudo update-alternatives --install /usr/share/gnome-shell/gdm-theme.gresource gdm-theme.gresource "$dest/gdm-theme.gresource" 20
sudo update-alternatives --set gdm-theme.gresource "$dest/gdm-theme.gresource"

# Font: the gdm user can't see ~/.local/share/fonts (the invoking user's, even under sudo)
user_home=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
sudo install -Dm644 -t /usr/local/share/fonts/mysway \
  "$user_home"/.local/share/fonts/JetBrainsMonoNerd/JetBrainsMonoNerdFont-{Regular,Bold}.ttf
sudo fc-cache -f /usr/local/share/fonts/mysway

# Logo: GDM 50 draws it at the image's own size (710x192 = most of the screen). Wrap the PNG
# in an SVG with a smaller declared size: same on-screen size, but the full-res PNG keeps it
# sharp at 2x scale where a downscaled PNG would be blurry.
python3 - "$here/logo.png" "$width" > "$build/logo.svg" <<'PY'
import base64, struct, sys
data = open(sys.argv[1], 'rb').read()
w, h = struct.unpack('>II', data[16:24])
W = int(sys.argv[2]); H = round(h * W / w)
b64 = base64.b64encode(data).decode()
print(f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
      f'width="{W}" height="{H}" viewBox="0 0 {w} {h}">'
      f'<image width="{w}" height="{h}" xlink:href="data:image/png;base64,{b64}"/></svg>')
PY
sudo install -Dm644 "$build/logo.svg" /usr/share/pixmaps/mysway-login-logo.svg
conf=/etc/gdm3/greeter.dconf-defaults
[[ -e $conf.bak-mysway ]] || sudo cp "$conf" "$conf.bak-mysway"
sudo sed -i -E "s|^#?\s*logo=.*|logo='/usr/share/pixmaps/mysway-login-logo.svg'|" "$conf"
grep -q "^logo='/usr/share/pixmaps/mysway-login-logo.svg'" "$conf" ||
  sudo sed -i "/^\[org\/gnome\/login-screen\]/a logo='/usr/share/pixmaps/mysway-login-logo.svg'" "$conf"

# Background: black, like swaylock
sudo sed -i -E "s|^#?\s*background-color=.*|background-color='#000000'|" "$conf"
grep -q "^background-color='#000000'" "$conf" ||
  printf "\n[com/ubuntu/login-screen]\nbackground-color='#000000'\n" | sudo tee -a "$conf" >/dev/null

echo; update-alternatives --query gdm-theme.gresource | grep -E '^Value'; grep -E '^(logo|background-color)=' "$conf"
echo "Log out to see it (GDM restarts its shell for each greeter)."
