#!/usr/bin/env python3
"""Generate the Fitie app icon: indigo gradient + a white completion ring + check."""
from PIL import Image, ImageDraw

SS = 2048          # supersample, downscale to 1024 for smooth edges
OUT = "Fitie/Assets.xcassets/AppIcon.appiconset/icon_1024.png"

def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))

# --- indigo diagonal background (system indigo family) ---------------------
c1 = (110, 108, 236)  # lighter indigo (top-left)
c2 = (88, 86, 214)    # system indigo
c3 = (68, 64, 182)    # deep indigo (bottom-right)

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

# --- completion ring (matches the in-app BrandMark) ------------------------
cx = cy = SS / 2
R = SS * 0.33
W = int(SS * 0.072)
white = (255, 255, 255)
draw.ellipse([cx - R - W / 2, cy - R - W / 2, cx + R + W / 2, cy + R + W / 2], fill=white)
inner = bg_color(0.5)
draw.ellipse([cx - R + W / 2, cy - R + W / 2, cx + R - W / 2, cy + R - W / 2], fill=inner)

# refill the ring's interior with the background gradient so it stays seamless
hole = Image.new("L", (SS, SS), 0)
hdraw = ImageDraw.Draw(hole)
hdraw.ellipse([cx - R + W / 2, cy - R + W / 2, cx + R - W / 2, cy + R - W / 2], fill=255)
bg = Image.new("RGB", (SS, SS))
bg.putdata(data)
img.paste(bg, (0, 0), hole)

# --- centered check mark ----------------------------------------------------
lw = int(SS * 0.052)
p1 = (cx - SS * 0.115, cy + SS * 0.01)
p2 = (cx - SS * 0.02, cy + SS * 0.105)
p3 = (cx + SS * 0.145, cy - SS * 0.10)
draw.line([p1, p2, p3], fill=white, width=lw, joint="curve")
for p in (p1, p2, p3):
    r = lw / 2
    draw.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=white)

# --- downscale for anti-aliasing -------------------------------------------
img = img.resize((1024, 1024), Image.LANCZOS)
img.save(OUT)
print("wrote", OUT)
