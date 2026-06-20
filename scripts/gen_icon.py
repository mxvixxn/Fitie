#!/usr/bin/env python3
"""Generate the Fitie app icon: soft pastel gradient + a completion ring + check."""
import math
from PIL import Image, ImageDraw

SS = 2048          # supersample, downscale to 1024 for smooth edges
OUT = "Fitie/Assets.xcassets/AppIcon.appiconset/icon_1024.png"

def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))

# --- pastel diagonal background -------------------------------------------
c1 = (232, 235, 249)  # lavender
c2 = (230, 243, 237)  # mint
c3 = (247, 238, 233)  # peach

def bg_color(s):  # s = (x + y) normalized 0..1
    if s < 0.5:
        return lerp(c1, c2, s / 0.5)
    return lerp(c2, c3, (s - 0.5) / 0.5)

# precompute per-diagonal color, then fill via putdata (fast)
table = [bg_color(d / (2 * (SS - 1))) for d in range(2 * SS - 1)]
data = [table[x + y] for y in range(SS) for x in range(SS)]
img = Image.new("RGB", (SS, SS))
img.putdata(data)
draw = ImageDraw.Draw(img)

# --- completion ring (angular gradient via segments) ----------------------
cx = cy = SS / 2
R = SS * 0.33
W = int(SS * 0.072)
stops = [(142, 138, 214), (85, 185, 140), (224, 138, 110), (142, 138, 214)]  # lavender->mint->coral->lavender

def ring_color(t):  # t 0..1 around the circle
    seg = t * (len(stops) - 1)
    i = min(int(seg), len(stops) - 2)
    return lerp(stops[i], stops[i + 1], seg - i)

box = [cx - R, cy - R, cx + R, cy + R]
steps = 360
for k in range(steps):
    a0 = -90 + (k / steps) * 360
    a1 = -90 + ((k + 1.5) / steps) * 360  # slight overlap to avoid seams
    draw.arc(box, a0, a1, fill=ring_color(k / steps), width=W)

# --- centered check mark --------------------------------------------------
check = (74, 74, 140)  # deep indigo
lw = int(SS * 0.052)
p1 = (cx - SS * 0.115, cy + SS * 0.01)
p2 = (cx - SS * 0.02, cy + SS * 0.105)
p3 = (cx + SS * 0.145, cy - SS * 0.10)
draw.line([p1, p2, p3], fill=check, width=lw, joint="curve")
for p in (p1, p2, p3):
    r = lw / 2
    draw.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=check)

# --- downscale for anti-aliasing -----------------------------------------
img = img.resize((1024, 1024), Image.LANCZOS)
img.save(OUT)
print("wrote", OUT)
