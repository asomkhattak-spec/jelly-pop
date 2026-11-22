#!/usr/bin/env python3
"""Generate Android launcher icons (all mipmap densities) with Pillow.

Draws the game's mascot: a pink jelly blob with a face on a purple gradient.
Run after `flutter create`:  python3 tool/gen_icons.py
"""
import os

from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), "..", "android", "app", "src", "main", "res")
DENSITIES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def make_icon(size):
    S = 512
    img = Image.new("RGB", (S, S))
    d = ImageDraw.Draw(img)
    top, bottom = (91, 77, 255), (155, 92, 255)
    for y in range(S):
        d.line([(0, y), (S, y)], fill=lerp(top, bottom, y / S))

    cx, cy, r = S / 2, S / 2 + 18, 168
    # shadow
    d.ellipse([cx - r, cy - r + 16, cx + r, cy + r + 16], fill=(40, 30, 90))
    # body: radial-ish gradient via concentric ellipses
    base = (255, 93, 143)
    light = lerp(base, (255, 255, 255), 0.4)
    dark = lerp(base, (0, 0, 0), 0.25)
    steps = 40
    for i in range(steps, 0, -1):
        t = i / steps
        rr = r * t
        col = lerp(light, dark, t)
        ox, oy = -r * 0.22 * (1 - t), -r * 0.28 * (1 - t)
        d.ellipse([cx - rr + ox, cy - rr + oy, cx + rr + ox, cy + rr + oy], fill=col)
    # gloss
    d.ellipse([cx - r * 0.62, cy - r * 0.72, cx - r * 0.12, cy - r * 0.38],
              fill=lerp(base, (255, 255, 255), 0.65))
    # eyes
    er = 20
    ex, ey = r * 0.34, r * 0.12
    for sx in (-1, 1):
        d.ellipse([cx + sx * ex - er, cy - ey - er, cx + sx * ex + er, cy - ey + er],
                  fill=(38, 35, 58))
        d.ellipse([cx + sx * ex - 6 + 5, cy - ey - 6 - 5, cx + sx * ex + 6 + 5, cy - ey + 6 - 5],
                  fill=(255, 255, 255))
    # smile
    d.arc([cx - r * 0.32, cy + r * 0.02, cx + r * 0.32, cy + r * 0.5],
          start=15, end=165, fill=(38, 35, 58), width=14)
    # blush
    for sx in (-1, 1):
        d.ellipse([cx + sx * r * 0.62 - 18, cy + r * 0.12 - 12,
                   cx + sx * r * 0.62 + 18, cy + r * 0.12 + 12],
                  fill=lerp(base, (255, 255, 255), 0.45))
    return img.resize((size, size), Image.LANCZOS)


def main():
    if not os.path.isdir(ROOT):
        raise SystemExit("android/ not found — run `flutter create` first")
    for density, size in DENSITIES.items():
        folder = os.path.join(ROOT, f"mipmap-{density}")
        os.makedirs(folder, exist_ok=True)
        icon = make_icon(size)
        icon.save(os.path.join(folder, "ic_launcher.png"))
        print(f"  mipmap-{density}/ic_launcher.png ({size}x{size})")
    print("Done.")


if __name__ == "__main__":
    main()
