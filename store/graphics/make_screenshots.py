"""Frame raw device screenshots with a caption on the brand background.

Produces Play-ready phone screenshots (1080x2400) in store/graphics/screenshots/.
Run:  python make_screenshots.py
"""
import os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(__file__)
RAW = os.path.join(HERE, "raw")
OUT = os.path.join(HERE, "screenshots")
os.makedirs(OUT, exist_ok=True)

W, H = 1080, 2400
BG = (24, 24, 29)        # #18181D
BORDER = (44, 44, 54)    # subtle separation since app bg == frame bg
TITLE = (240, 240, 246)

CAP_TOP = 96             # caption baseline area
SHOT_TOP = 300
SHOT_BOTTOM_MARGIN = 40

SHOTS = [
    ("01-live-matrix.png", "Live DDP, in real time",
     "Watch incoming pixels render instantly"),
    ("02-color-order.png", "Match your LEDs' color order",
     "RGB, GRB, BGR, RBG, GBR or BRG"),
    ("03-matrix-48x32.png", "Any matrix size, pixel-perfect",
     "Configure the grid right in the app"),
]


def font(names, size):
    for n in names:
        try:
            return ImageFont.truetype(n, size)
        except OSError:
            continue
    return ImageFont.load_default()


TITLE_F = font(["C:/Windows/Fonts/segoeuib.ttf", "C:/Windows/Fonts/arialbd.ttf"], 60)
SUB_F = font(["C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/arial.ttf"], 38)


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, img.size[0] - 1, img.size[1] - 1], radius=radius, fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0))
    out.putalpha(mask)
    return out


for fname, title, sub in SHOTS:
    canvas = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(canvas)

    # Caption (centered).
    tw = draw.textlength(title, font=TITLE_F)
    draw.text(((W - tw) / 2, CAP_TOP), title, font=TITLE_F, fill=TITLE)
    sw = draw.textlength(sub, font=SUB_F)
    draw.text(((W - sw) / 2, CAP_TOP + 84), sub, font=SUB_F, fill=(150, 150, 162))

    # Screenshot scaled to fit remaining height, centered.
    shot = Image.open(os.path.join(RAW, fname)).convert("RGB")
    avail_h = H - SHOT_TOP - SHOT_BOTTOM_MARGIN
    scale = avail_h / shot.height
    new_w = int(shot.width * scale)
    new_h = int(shot.height * scale)
    shot = shot.resize((new_w, new_h), Image.LANCZOS)
    shot = rounded(shot, 36)

    x = (W - new_w) // 2
    # Subtle border to lift the panel off the same-colored background.
    draw.rounded_rectangle([x - 2, SHOT_TOP - 2, x + new_w + 1, SHOT_TOP + new_h + 1],
                           radius=38, outline=BORDER, width=3)
    canvas.paste(shot, (x, SHOT_TOP), shot)

    out_path = os.path.join(OUT, fname)
    canvas.save(out_path)
    print("wrote", out_path)
