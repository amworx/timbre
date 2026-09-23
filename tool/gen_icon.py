"""Generates the Timbre launcher icon assets (run once, then delete)."""
from PIL import Image, ImageDraw

SIZE = 1024
TOP = (67, 56, 202)     # indigo 700
BOTTOM = (109, 40, 217) # violet 700
WHITE = (255, 255, 255)


def gradient_bg():
    img = Image.new("RGB", (SIZE, SIZE), TOP)
    d = ImageDraw.Draw(img)
    for y in range(SIZE):
        t = y / (SIZE - 1)
        c = tuple(round(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3))
        d.line([(0, y), (SIZE, y)], fill=c)
    return img


def waves(w, h, color):
    """Transparent layer with five vertical white bars (heights form a wave)."""
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    heights = [0.30, 0.55, 0.78, 0.55, 0.30]
    bw = 0.09            # bar width, fraction of min side
    gap = 0.075          # gap between bars
    total = len(heights) * bw + (len(heights) - 1) * gap
    side = min(w, h)
    start = (side - side * total) / 2
    for i, f in enumerate(heights):
        bw_px = side * bw
        x0 = start + i * (bw_px + side * gap)
        bh = side * f
        x1 = x0 + bw_px
        y0 = (h - bh) / 2
        y1 = (h + bh) / 2
        r = bw_px / 2
        d.rounded_rectangle([x0, y0, x1, y1], radius=r, fill=color)
    return layer


base = gradient_bg().convert("RGBA")
base.alpha_composite(waves(SIZE, SIZE, WHITE + (255,)))
base.save("timbre_icon.png")

# Monochrome layer for Android 13+ themed icons.
Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0)).save("_blank.png")
waves(SIZE, SIZE, WHITE + (255,)).save("timbre_icon_mono.png")
print("icon assets written")
