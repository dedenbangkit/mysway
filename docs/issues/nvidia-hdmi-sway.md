# HDMI on the RTX 5060, Sway, login sessions, and Slack

**Date:** 2026-10-04
**Machine:** ASUS ROG Zephyrus G16 — Intel Arrow Lake iGPU + NVIDIA RTX 5060 Laptop (GB206M, Blackwell)
**OS:** Ubuntu 26.04, kernel 7.0.0-38-generic, Sway 1.11
**Status:** Resolved

## Summary

The external LG monitor on HDMI wasn't detected. The HDMI port is wired to the
NVIDIA GPU, and that GPU needs the **open** NVIDIA kernel driver. Fixing that broke
the normal Sway login, because Sway refuses to run while an NVIDIA driver is loaded.
That needed a separate "Sway (NVIDIA)" login entry. Once both screens worked, the
monitor layout was wrong: the LG was the main display and the laptop was the second
one, which made the cursor jump to the wrong places. Slack also stopped showing
its window and needed GPU rendering turned off (section 5).

## 1. HDMI not detected — wrong NVIDIA driver

### Symptoms

- Nothing shows up on the HDMI monitor and Sway doesn't list an HDMI output.
- The kernel log shows the NVIDIA GPU failing to start:

  ```
  NVRM: ... requires use of the NVIDIA open kernel modules
  NVRM: RmInitAdapter failed!
  ```

- No DRM card exists for the NVIDIA GPU.

### Cause

On this laptop the ports are split between the two GPUs:

| Port | GPU |
|---|---|
| HDMI | NVIDIA RTX 5060 (`card2`) |
| USB-C / DisplayPort | Intel iGPU (`card1`, the boot/primary GPU) |

Blackwell GPUs (RTX 50 series) only work with NVIDIA's **open** kernel modules.
The closed `nvidia-driver-595` was installed. Both the closed and the open module
packages were present, and `modprobe` picked the closed one, which can't start the
GPU, so the HDMI port never appeared.

### Fix

Install the open driver and remove the closed kernel modules:

```sh
sudo apt install nvidia-driver-595-open linux-modules-nvidia-595-open-generic-hwe-26.04
sudo apt remove 'linux-modules-nvidia-595-[0-9]*'   # closed variants
sudo reboot
```

### How to check it's right

```sh
modinfo -F license nvidia        # must be "Dual MIT/GPL" (open); "NVIDIA" = closed
modinfo -n nvidia                # path should contain nvidia-595-open
journalctl -k -b | grep -c RmInitAdapter   # should be 0
swaymsg -t get_outputs | jq -r '.[].name'  # should list HDMI-A-2
```

### Watch out

A driver upgrade (`ubuntu-drivers`, the upgrades script, or a new kernel) can bring
back the closed variant. If HDMI disappears again, run the checks above first.

## 2. Sway won't log in — "Proprietary Nvidia drivers are in use"

### Symptoms

After the driver switch, choosing **Sway** on the GDM login screen goes straight back
to the login screen. Sway logs:

```
Proprietary Nvidia drivers are in use. ... launch with --unsupported-gpu
```

### Cause

Sway refuses to start when it detects the NVIDIA driver, even the open one. It
checks for the **loaded driver**, not for a connected screen, so unplugging the HDMI
cable does **not** help. The driver loads at boot either way.

### Fix

Add a separate login entry that starts Sway with `--unsupported-gpu`
([`session/sway-nvidia.desktop`](../../session/sway-nvidia.desktop)), installed by
[`session/install.sh`](../../session/install.sh).

Intel stays the primary GPU and does the rendering. NVIDIA only drives the HDMI
port. In practice `--unsupported-gpu` has been fine.

If the cursor is ever invisible on the HDMI screen, try starting Sway with
`WLR_NO_HARDWARE_CURSORS=1`.

## 3. Hiding the plain "Sway" login entry

After step 2 the login screen showed three entries: **Sway**, **Sway (NVIDIA)** and
**Ubuntu**. The plain **Sway** entry can never work while the NVIDIA driver is
installed, so it's hidden.

`/usr/share/wayland-sessions/sway.desktop` belongs to the `sway` package. Deleting
it doesn't stick, because the next sway update puts it back. Instead,
`session/install.sh` uses `dpkg-divert`. This tells dpkg to store that file as
`sway.desktop.diverted`, now and in every future update. The login screen only
lists `*.desktop` files, so the entry disappears.

```sh
# hide (done by session/install.sh)
sudo dpkg-divert --local --rename \
  --divert /usr/share/wayland-sessions/sway.desktop.diverted \
  --add /usr/share/wayland-sessions/sway.desktop

# check
dpkg-divert --list | grep sway

# undo (bring plain Sway back)
sudo dpkg-divert --rename --remove /usr/share/wayland-sessions/sway.desktop
```

`sway-nvidia.desktop` is our own file and isn't owned by any package, so updates
never touch it.

The result is two login entries: **Sway (NVIDIA)** for daily use and **Ubuntu**
(GNOME) as a fallback.

You would only want plain Sway back if the NVIDIA driver were removed or
blacklisted, and that would also disable HDMI.

## 4. Wrong main display — cursor behaving oddly

### Symptoms

With both screens on, the LG monitor acted as the main display and the laptop as the
second one. The cursor crossed between screens at the wrong edge, and workspace 1
opened on the LG.

### Cause

Sway has no "primary display" setting. The output at position `0,0` effectively
acts as the main one, and X11 apps also treat it as primary. Without an explicit
layout, Sway put `HDMI-A-2` at `0,0` and the laptop (`eDP-1`) to its right.

### Fix

In [`sway/config`](../../sway/config):

```
output eDP-1 scale 1.5 position 0 0
output HDMI-A-2 position 1706 0
workspace 1 output eDP-1
```

The LG's x position is the laptop's width in logical pixels: 2560 / 1.5 = **1706**
(Sway rounds down). Using 1707 leaves a 1px gap between the screens. To verify:

```sh
swaymsg -t get_outputs | jq -r '.[] | "\(.name) \(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"'
```

If the monitor is ever physically on the **left** of the laptop instead, swap the
positions: put `HDMI-A-2` at `0 0` and `eDP-1` at `1920 0`. Keep
`workspace 1 output eDP-1` so workspace 1 still opens on the laptop.

## 5. Slack runs but never shows a window

### Symptoms

Slack (snap 4.52.171) starts: the process runs, it logs in, and it loads the
workspace. But no window ever appears, and Sway has no Slack window in its tree.
This showed up on the same day as the NVIDIA driver switch.

### Cause

There are two separate problems:

1. **GPU rendering fails.** Slack's bundled graphics libraries don't load properly
   on this setup:

   ```
   MESA-LOADER: failed to open dri: /usr/lib/x86_64-linux-gnu/gbm/dri_gbm.so: cannot open shared object file
   ```

   Chromium/Electron then never maps its Wayland window. In repeated tests, plain
   `slack` never got a window, while `slack --disable-gpu` got one within 1s every
   time. Turning off **Hardware acceleration** inside Slack's own settings is
   **not** enough on its own; the command-line flag is needed.

2. **It started hidden in the tray.** Slack's `hideOnStartup` setting was on, and
   the snap's AppArmor profile blocks its tray-icon updates:

   ```
   apparmor="DENIED" operation="dbus_signal" path="/StatusNotifierItem" ... label="snap.slack.slack"
   ```

   So even when Slack did start, there was no reliable tray icon to click to open it.

### Fix

- [`applications/slack_slack.desktop`](../../applications/slack_slack.desktop) is a
  copy of the snap's launcher entry with `Exec=/snap/bin/slack --disable-gpu %U`.
  It's symlinked into `~/.local/share/applications/`, which takes priority over the
  snap's own entry in `/var/lib/snapd/desktop/applications/`. fuzzel and
  `slack://` links both use it.

  ```sh
  ln -s ~/Repos/myrepos/mysway/applications/slack_slack.desktop ~/.local/share/applications/
  ```

- In Slack's settings file
  (`~/snap/slack/current/.config/Slack/storage/root-state.json`, under
  `.settings`), `hideOnStartup` and `useHwAcceleration` were set to `false`. Edit
  the file only while Slack is closed, because Slack overwrites it when it quits.

### Notes

- Running `slack` from a terminal still needs `--disable-gpu` added by hand.
- Software rendering is fine for chat. Calls and screen sharing use a bit more CPU.
- If the snap renames its launcher entry, the override stops applying. Compare
  with `/var/lib/snapd/desktop/applications/slack_slack.desktop`.
- Other Electron/Chromium apps that start with no window: try `--disable-gpu` first.
