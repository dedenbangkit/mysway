#!/usr/bin/env python3
"""Build the mysway GRUB theme assets (fonts + box images) into ./theme.

Look matches fuzzel/Sway: black box, 2px #3584E4 border, square corners,
selected row solid blue with white text. `./build.py --preview out.png`
also renders an approximate 2560x1600 mock of the boot screen.
"""
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
THEME = HERE / "theme"
FONTS = Path.home() / ".local/share/fonts/JetBrainsMonoNerd"
BLUE, BLACK, BORDER = (0x35, 0x84, 0xE4), (0, 0, 0), 2

# (file, ttf, size) -> GRUB name "JetBrainsMono NF <Style> <size>"
PF2 = [
    ("jbm-regular-20.pf2", "JetBrainsMonoNerdFont-Regular.ttf", 20),
    ("jbm-regular-24.pf2", "JetBrainsMonoNerdFont-Regular.ttf", 24),
    ("jbm-bold-24.pf2", "JetBrainsMonoNerdFont-Bold.ttf", 24),
]


def solid(name, size, color):
    Image.new("RGB", size, color).save(THEME / name)


def build():
    for old in THEME.glob("*.pf2"):
        old.unlink()
    for old in THEME.glob("progress_*.png"):
        old.unlink()
    for out, ttf, size in PF2:
        # ASCII + Latin-1 + arrows/bullets keeps the files small
        subprocess.run(["grub-mkfont", "-s", str(size), "-r", "0x20-0x7e,0xa0-0xff,0x2022-0x2022,0x2190-0x2193",
                        "-o", str(THEME / out), str(FONTS / ttf)], check=True)
    # 9-slice box: blue border, black centre
    for side in ("n", "s"):
        solid(f"menu_{side}.png", (1, BORDER), BLUE)
    for side in ("w", "e"):
        solid(f"menu_{side}.png", (BORDER, 1), BLUE)
    for corner in ("nw", "ne", "sw", "se"):
        solid(f"menu_{corner}.png", (BORDER, BORDER), BLUE)
    solid("menu_c.png", (1, 1), BLACK)
    solid("select_c.png", (1, 1), BLUE)


def preview(out):
    """Rough mock using the same numbers as theme.txt (not pixel-exact GRUB)."""
    W, H = 2560, 1600
    img = Image.open(THEME / "background.png").convert("RGB").resize((W, H))
    d = ImageDraw.Draw(img)
    reg = lambda s: ImageFont.truetype(str(FONTS / "JetBrainsMonoNerdFont-Regular.ttf"), s)
    bold = ImageFont.truetype(str(FONTS / "JetBrainsMonoNerdFont-Bold.ttf"), 24)
    x, w, y, rows, rh = int(W * .32), int(W * .36), int(H * .34), 5, 40
    h = rows * rh + 2 * BORDER + 2 * 8
    d.text((x, y - 44), "boot", font=bold, fill=BLUE)
    d.text((x + w, y - 44), "5s", font=reg(24), fill=(0x6c, 0x73, 0x80), anchor="ra")
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=BLACK, outline=BLUE, width=BORDER)
    items = ["Ubuntu", "Advanced options for Ubuntu", "Memory test (memtest86+x64.efi)",
             "Memory test (memtest86+x64.efi, serial console)", "UEFI Firmware Settings"]
    for i, t in enumerate(items):
        top = y + BORDER + 8 + i * rh
        if i == 0:
            d.rectangle([x + BORDER, top, x + w - BORDER - 1, top + rh - 1], fill=BLUE)
        d.text((x + BORDER + 14, top + rh // 2), t, font=bold if i == 0 else reg(24),
               fill=(255, 255, 255) if i == 0 else (0xb8, 0xb8, 0xb8), anchor="lm")
    d.text((x, y + h + 16), "↑↓ select   enter boot   e edit   c console", font=reg(20), fill=(0x6c, 0x73, 0x80))
    img.save(out)


if __name__ == "__main__":
    build()
    if len(sys.argv) == 3 and sys.argv[1] == "--preview":
        preview(sys.argv[2])
