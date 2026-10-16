# Wireless display (Super+p)

Present on a TV over Wi-Fi, like Windows Win+P. Tested with a Samsung Crystal UHD TU8000
(UA50TU8000KXXD, Tizen 2020), shown as **"[TV] Samsung 8 Series (50)"**.

| Mode | What the TV shows |
|---|---|
| **Extend** | A separate virtual screen (`HEADLESS-n`, 1920×1080, right of the laptop). Only that output is captured; the laptop's workspaces stay private. |
| **Mirror** | The focused physical screen (normally eDP-1), as-is. |
| **Disconnect** | Hangs up, removes the virtual screen, moves workspaces back to the outputs they were on, restores sound. |

## Use

- **Super+p** (or click the TV icon next to the bell on the top bar) opens a fuzzel menu:
  - not connected: *Extend* / *Mirror*, then discovery (2–10 s) of **any** Miracast display in
    range. A display you've streamed to before (`~/.local/state/wireless-display/known`) connects
    straight away when it's the only one found; a new one, or several, opens a picker (known ones
    first). So in an office you never land on the next room's TV by accident.
  - connected: status line, *Switch to Mirror/Extend*, *Sound on TV / on laptop*, *Disconnect*.
- Connecting takes ~10 s. If the TV shows an **Allow** prompt, accept it quickly (see below).
- Extend: move a workspace to the TV with **Super+Ctrl+Shift+→** (back with **←**), or open
  apps while the TV's workspace is focused.
- Top-bar icon: gold = off, blue = connected (tooltip: mode and TV), grey = connecting.
- Without the menu: `wireless-display extend|mirror ["[TV] Samsung 8 Series (50)"]`,
  `wireless-display disconnect`.

## How it works

```
Super+p ─ sway/scripts/wireless-display ─┬─ NetworkManager D-Bus: Wi-Fi P2P StartFind → Miracast sinks (WFD IEs)
                                         ├─ Extend: swaymsg create_output + output HEADLESS-n mode 1920x1080@60Hz
                                         ├─ writes $XDG_RUNTIME_DIR/wireless-display/share  (= output to send)
                                         └─ systemd-run --user wireless-display-stream:
                                              /usr/libexec/gnome-network-displays-stream  (P2P link, RTSP, H.264/AAC)
                                                └─ ScreenCast portal → xdg-desktop-portal-wlr
                                                     └─ chooser_cmd = sway/scripts/screencast-chooser → "Monitor: <share>"
```

- **Miracast source**: GNOME Network Displays 0.99 (`gnome-network-displays` package), only its
  stream binary. Not the GUI, and not its daemon: the daemon's continuous Wi-Fi P2P discovery
  wedges wpa_supplicant ("Reject scan trigger since one is already pending") and the TV never
  receives the connect request. The script discovers once, stops discovery, then starts the stream.
- **Output selection** happens in the portal, not in GND: `portal/xdpw-config` (linked to
  `~/.config/xdg-desktop-portal-wlr/config`) runs `sway/scripts/screencast-chooser` for every
  screen-share request. While a session's state file exists it answers with that session's output
  only; if the output is gone it declines. **It never falls back to another screen.** Outside a
  session it behaves as before (slurp, pick an output).
- **Watcher** (`wireless-display-watch` user unit) follows the stream's state, retries the
  handshake once (Samsung often drops the first), and tears down if the TV goes away.
- **Notifications**: in Extend, mako mode `presenting` (`mako/config`) pins popups to eDP-1, so
  they never appear on the TV even when its workspace is focused. In Mirror they show on the TV
  (it's the same screen); use DND (Super+d) if that matters.
- **Stray TV pointer fix**: GND asks the sink about the `microsoft_cursor` extension (the TV
  draws the pointer, the source sends positions) but never sends positions, so the Samsung shows
  its own browser-style pointer stuck in the top-left corner. The script runs a copy of the
  stream binary, `~/.local/libexec/gnd-stream-nocursor`, with that query name swapped for
  another 16-character one (a duplicate `wfd_display_edid` query). It is re-made automatically
  when apt updates GND; if the string isn't there any more, the stock binary is used.
- **Encoders** (picked by GND): `vah264enc` (Intel VA, hardware) → `x264enc` → `openh264enc`;
  audio `avenc_aac`; mux `mpegtsmux`.

## Install

```sh
sudo apt install gnome-network-displays gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav
portal/install.sh          # links xdpw-config, restarts the portals
swaymsg reload; makoctl reload
```

Requirements met on this machine: Intel CNVi Wi-Fi (`iwlwifi`) with P2P-GO/P2P-client
(`iw list`), NetworkManager with wpa_supplicant (`p2p-dev-wlo1` in `nmcli dev`), sway ≥ 1.8
(`create_output` adds a headless output on the DRM backend). ufw is disabled; if a firewall is
turned on, allow DHCP (UDP 67) and RTSP (TCP 7236) on `p2p-wlo1-*`.

## Limitations

- **Miracast, Wi-Fi Direct only.** The laptop and TV link directly (the laptop is group owner, on
  2.4 GHz channel 6 in tests); the TV's LAN/router connection is not used. The laptop stays on its
  normal Wi-Fi at the same time (the Intel card time-shares 2 channels), which can cost some
  throughput on both.
- **1080p with noticeable lag** (Miracast buffers; not measured here). Fine for slides, documents,
  video; not for games. The virtual
  screen is 16:9 1920×1080; Mirror of the 16:10 laptop panel is letterboxed.
- **Audio** goes to the laptop until you pick *Sound on TV* (GND creates a "GNOME Network
  Displays" sink; the menu switches the default sink and restores it on disconnect).
- **Extend shows what you put there.** Anything opened while the TV's workspace is focused
  (including fuzzel menus and floating popups) appears on the TV. The bars and wallpaper show
  there too (top bar: CPU, clock, next calendar event; the IP address is an icon, hover for it).
- **Switching mode reconnects** (~10 s): a portal session captures one fixed output.
- **No HDCP**: DRM-protected video (Netflix in a browser) may be black on the TV.
- **Other places (office, venues)**: works with displays that accept Miracast over Wi-Fi Direct:
  most Samsung/LG/Sony/Hisense smart TVs, Microsoft Wireless Display Adapter, Roku, many projectors.
  Not with Chromecast-only, AirPlay-only (Apple TV), Barco ClickShare (button/app), or Teams/Zoom
  Rooms that use Miracast *over the LAN* (MICE); GND can do MICE and Chromecast, the menu doesn't yet.
- **Chromecast** displays (e.g. the bedroom SHARP Google TV, `_googlecast` on the LAN) are seen by
  GND but not offered by this menu: P2P peers only.
- Kanshi: no config in use (`exec kanshi` with no `~/.config/kanshi/config`). If profiles are
  added, a headless output makes the output set unmatched, so kanshi leaves things alone during a
  session; don't write a profile that includes `HEADLESS-*`.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| "No wireless display found" | TV off or asleep. Wi-Fi Direct only answers while the TV is on (any source; 2020 Samsungs have no "Screen Mirroring" source entry). `nmcli dev` must list `p2p-dev-wlo1`; Wi-Fi must be on. |
| "Couldn't connect" after ~1 min | TV ignored the request or its Allow prompt timed out (NM gives the peer ~5 s after the WPS handshake). On the TV: Settings → General → External Device Manager → Device Connection Manager → Access Notification → *First Time Only* / *Off*. Also check the TV isn't still in an old session (turn it off and on). |
| Connected, TV shows the laptop screen in Extend | Shouldn't happen: the chooser only returns the session's `HEADLESS-n`. Check `cat $XDG_RUNTIME_DIR/wireless-display/share` and `journalctl --user -u xdg-desktop-portal-wlr`. A stale `~/.config/xdg-desktop-portal-wlr/sway` file would override `config`. |
| Screen sharing in Slack/browser shows no picker | A session is active (or its state dir is stale): that share gets the session's output. `wireless-display disconnect`, or `rm -r $XDG_RUNTIME_DIR/wireless-display`. |
| Stuck "Reject scan trigger since one is already pending" in `journalctl -u wpa_supplicant` | Something keeps P2P discovery running (e.g. `gnome-network-displays-daemon` or the GND app). Quit it; `sudo systemctl restart wpa_supplicant` if it persists. |
| A second, frozen pointer in the TV's top-left corner | The TV's own pointer (see "Stray TV pointer fix"): the stock binary is in use. Check `systemctl --user show wireless-display-stream -p ExecStart` names `gnd-stream-nocursor`; delete it to force a re-patch. |
| Choppy picture | Busy 2.4 GHz band / far from the TV. Logs: `journalctl --user -u wireless-display-stream -f`. |

Logs: `journalctl --user -u wireless-display-stream -u wireless-display-watch`,
`journalctl -u NetworkManager -u wpa_supplicant`. State: `$XDG_RUNTIME_DIR/wireless-display/`.
