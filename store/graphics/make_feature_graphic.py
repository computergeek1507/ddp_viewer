"""Generate the Google Play feature graphic (1024x500, no alpha) for DDP Viewer.

Recreates the app's glowing rainbow LED-grid motif on the brand background and
sets the title + tagline beside it. Run:  python make_feature_graphic.py
"""
import colorsys
import os
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

W, H = 1024, 500
BG = (24, 24, 29)  # #18181D brand background
OUT = os.path.join(os.path.dirname(__file__), "feature-graphic.png")

# ---- LED grid (echoes assets/icon/icon.png) --------------------------------
COLS, ROWS = 5, 5
CELL, GAP, RADIUS = 52, 22, 13
grid_w = COLS * CELL + (COLS - 1) * GAP
grid_h = ROWS * CELL + (ROWS - 1) * GAP
GX, GY = 84, (H - grid_h) // 2


def hue_for(c, r):
    # Diagonal rainbow sweep, matching the icon's feel.
    h = ((c + r) / (COLS + ROWS - 2)) * 0.92
    return colorsys.hsv_to_rgb(h, 0.82, 1.0)


def draw_cells(img, inset, scale):
    d = ImageDraw.Draw(img)
    for r in range(ROWS):
        for c in range(COLS):
            x0 = GX + c * (CELL + GAP) + inset
            y0 = GY + r * (CELL + GAP) + inset
            x1 = x0 + CELL - 2 * inset
            y1 = y0 + CELL - 2 * inset
            rf, gf, bf = hue_for(c, r)
            col = (int(rf * scale), int(gf * scale), int(bf * scale))
            d.rounded_rectangle([x0, y0, x1, y1], radius=RADIUS, fill=col)


def load_font(names, size):
    for n in names:
        try:
            return ImageFont.truetype(n, size)
        except OSError:
            continue
    return ImageFont.load_default()


base = Image.new("RGB", (W, H), BG)

# Glow: blurred full-bright cells, screen-blended so the dark bg shows through.
glow = Image.new("RGB", (W, H), (0, 0, 0))
draw_cells(glow, inset=-3, scale=235)
glow = glow.filter(ImageFilter.GaussianBlur(17))
base = ImageChops.screen(base, glow)

# Sharp cells on top.
draw_cells(base, inset=0, scale=255)

# ---- Text ------------------------------------------------------------------
draw = ImageDraw.Draw(base)
title_font = load_font(
    ["C:/Windows/Fonts/segoeuib.ttf", "C:/Windows/Fonts/arialbd.ttf"], 84)
tag_font = load_font(
    ["C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/arial.ttf"], 31)
sub_font = load_font(
    ["C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/arial.ttf"], 25)

# Center each line horizontally within the open region to the right of the grid.
region_l = GX + grid_w + 40
region_r = W - 40
center = (region_l + region_r) / 2


def centered(text, font, y, fill):
    w = draw.textlength(text, font=font)
    draw.text((center - w / 2, y), text, font=font, fill=fill)


centered("DDP Viewer", title_font, 170, (245, 245, 250))
centered("Live DDP pixel data on your screen", tag_font, 272, (178, 178, 188))
centered("Virtual LEDs for xLights, FPP & pixel mappers", sub_font, 314,
         (120, 120, 132))

base.save(OUT)
print("wrote", OUT, base.size)
