#!/usr/bin/env python3
"""Generate the Fitie app icon: deep-indigo gradient + multi-color activity rings.

Concept "C1 clean" — three concentric partial rings (magenta / violet / indigo)
in the brand indigo family, each behind a dark "track" for its unfilled portion
(the Apple Fitness idiom). Kept deliberately clean (no baked-in gloss) so the
same layers can later drive an iOS 26 Liquid Glass `.icon` via Icon Composer.

Run from the repo root:  python3 scripts/gen_icon.py [--glass]
  (default)  writes the canonical 1024 PNG into the asset catalog
  --glass    additionally writes a static glass-sheen preview to docs/ (not shipped)
"""
import math
import os
import sys
from PIL import Image, ImageDraw, ImageFilter

SS = 4                              # supersample factor, downscaled for smooth edges
SIZE = 1024
OUT = "Fitie/Assets.xcassets/AppIcon.appiconset/icon_1024.png"
GLASS_OUT = "docs/app-icon-glass.png"

# --- palette (brand indigo family) -----------------------------------------
RING_INNER  = (108, 116, 250)       # indigo   #6C74FA
RING_MIDDLE = (168, 120, 250)       # violet   #A878FA
RING_OUTER  = (240, 116, 196)       # magenta  #F074C4
BG_TL = (58, 50, 138)               # deep indigo, top-left     #3A328A
BG_BR = (22, 20, 60)                # darker indigo, bottom-right #16143C

# --- geometry (fractions of the canvas) ------------------------------------
STROKE_FRAC = 0.093
GAP_FACTOR  = 1.34
OUTER_R_FRAC = 0.335
# (radius, color, sweep degrees) — outermost first
RING_SPECS = [
    ("outer",  RING_OUTER,  306),
    ("middle", RING_MIDDLE, 330),
    ("inner",  RING_INNER,  288),
]


def diagonal_gradient(size, top_left, bottom_right):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            px[x, y] = tuple(
                int(top_left[i] + (bottom_right[i] - top_left[i]) * t) for i in range(3)
            )
    return img


def draw_track(draw, cx, cy, r, w, base):
    """Full dark ring behind a partial ring — the unfilled portion."""
    draw.ellipse([cx - r, cy - r, cx + r, cy + r],
                 outline=tuple(int(c * 0.42) for c in base), width=w)


def draw_arc_rounded(draw, cx, cy, r, w, start_deg, sweep_deg, color):
    """Arc with rounded caps. 0deg = 12 o'clock, clockwise positive."""
    a0 = start_deg - 90
    a1 = a0 + sweep_deg
    draw.arc([cx - r, cy - r, cx + r, cy + r], a0, a1, fill=color, width=w)
    for a in (a0, a1):
        rad = math.radians(a)
        ex, ey = cx + r * math.cos(rad), cy + r * math.sin(rad)
        cr = w / 2
        draw.ellipse([ex - cr, ey - cr, ex + cr, ey + cr], fill=color)


def render_rings(img):
    s = img.size[0]
    draw = ImageDraw.Draw(img)
    cx = cy = s / 2
    w = int(s * STROKE_FRAC)
    gap = int(w * GAP_FACTOR)
    radii = [s * OUTER_R_FRAC - i * gap for i in range(len(RING_SPECS))]

    for r, (_, color, _) in zip(radii, RING_SPECS):
        draw_track(draw, cx, cy, r, w, color)
    for r, (_, color, sweep) in zip(radii, RING_SPECS):
        draw_arc_rounded(draw, cx, cy, r, w, 0, sweep, color)
    return img


def apply_glass(img):
    """Static Liquid-Glass-style sheen for the marketing preview (not shipped)."""
    s = img.size[0]
    img = img.convert("RGBA")

    highlight = Image.new("L", (s, s), 0)
    ImageDraw.Draw(highlight).ellipse(
        [-s * 0.35, -s * 0.45, s * 0.75, s * 0.55], fill=90)
    highlight = highlight.filter(ImageFilter.GaussianBlur(s * 0.10))
    over = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    over.paste((255, 255, 255, 255), (0, 0), highlight)
    img = Image.alpha_composite(img, over)

    gloss = Image.new("L", (s, s), 0)
    ImageDraw.Draw(gloss).ellipse([s * 0.02, -s * 0.5, s * 0.98, s * 0.30], fill=60)
    gloss = gloss.filter(ImageFilter.GaussianBlur(s * 0.06))
    over = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    over.paste((255, 255, 255, 255), (0, 0), gloss)
    img = Image.alpha_composite(img, over)

    rim = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(rim).arc([s * 0.06, s * 0.05, s * 0.94, s * 0.95],
                            200, 340, fill=(255, 255, 255, 70), width=int(s * 0.012))
    rim = rim.filter(ImageFilter.GaussianBlur(s * 0.006))
    img = Image.alpha_composite(img, rim)
    return img.convert("RGB")


def build():
    s = SIZE * SS
    img = diagonal_gradient(s, BG_TL, BG_BR)
    img = render_rings(img)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    icon = build()
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    icon.save(OUT)
    print("wrote", OUT)

    if "--glass" in sys.argv:
        os.makedirs(os.path.dirname(GLASS_OUT), exist_ok=True)
        apply_glass(icon).save(GLASS_OUT)
        print("wrote", GLASS_OUT)


if __name__ == "__main__":
    main()
