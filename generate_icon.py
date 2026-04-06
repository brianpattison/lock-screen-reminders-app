#!/usr/bin/env python3
"""
Lock Screen Reminders — App Icon
Design Philosophy: Luminous Threshold

Three luminous lines emerge from deep indigo darkness,
each glowing with warm amber light — an abstract notation
of three thoughts held at the threshold of attention.
"""

import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

if len(sys.argv) != 2:
    print("Usage: python3 generate_icon.py <output_path>")
    sys.exit(1)

SIZE = 1024
OUTPUT = sys.argv[1]

# =============================================================
# 1. BACKGROUND: Deep indigo radial gradient
# =============================================================

y_grid, x_grid = np.mgrid[0:SIZE, 0:SIZE].astype(np.float64)
cx, cy = SIZE / 2.0, SIZE / 2.0

dist = np.sqrt((x_grid - cx) ** 2 + (y_grid - cy) ** 2)
max_dist = SIZE * 0.72
t = np.clip(dist / max_dist, 0.0, 1.0) ** 1.8  # Smooth easing

# Center: rich deep blue | Edge: near black
c0 = np.array([16.0, 34.0, 66.0])   # #102242  — slightly deeper
c1 = np.array([4.0, 8.0, 18.0])     # #040812  — darker edge for contrast

r_bg = (c0[0] * (1 - t) + c1[0] * t)
g_bg = (c0[1] * (1 - t) + c1[1] * t)
b_bg = (c0[2] * (1 - t) + c1[2] * t)

# =============================================================
# 2. SUBTLE NOISE TEXTURE (barely perceptible grain)
# =============================================================

noise = np.random.normal(0.0, 2.0, (SIZE, SIZE))

r_final = np.clip(r_bg + noise, 0, 255).astype(np.uint8)
g_final = np.clip(g_bg + noise * 0.8, 0, 255).astype(np.uint8)
b_final = np.clip(b_bg + noise * 0.6, 0, 255).astype(np.uint8)
a_full = np.full((SIZE, SIZE), 255, dtype=np.uint8)

bg_arr = np.stack([r_final, g_final, b_final, a_full], axis=-1)
img = Image.fromarray(bg_arr, "RGBA")

# =============================================================
# 3. WARM ZONE: rich atmospheric glow behind the line area
# =============================================================

warm = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
warm_draw = ImageDraw.Draw(warm)
warm_draw.ellipse(
    [SIZE // 2 - 440, SIZE // 2 - 260, SIZE // 2 + 440, SIZE // 2 + 260],
    fill=(55, 40, 15, 70),
)
warm = warm.filter(ImageFilter.GaussianBlur(radius=140))
img = Image.alpha_composite(img, warm)

# Second warm pass: tighter, warmer
warm2 = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
warm2_draw = ImageDraw.Draw(warm2)
warm2_draw.ellipse(
    [SIZE // 2 - 320, SIZE // 2 - 140, SIZE // 2 + 320, SIZE // 2 + 140],
    fill=(65, 45, 12, 45),
)
warm2 = warm2.filter(ImageFilter.GaussianBlur(radius=90))
img = Image.alpha_composite(img, warm2)

# =============================================================
# 4. LINE & CIRCLE PARAMETERS
# =============================================================

line_h = 36       # Thicker for small icon visibility
line_r = 18       # Perfect pill ends
line_widths = [280, 390, 500]  # Shorter lines, easier to read small
line_gap = 134    # Between centers — wider for bigger elements

# Circle parameters (unfilled outline circles)
circle_d = 90       # Bigger circles for small icon visibility
circle_stroke = 10  # Thicker outline to match line weight
circle_gap = 30     # Between circle right edge and line left edge

# Layout — left-aligned lines with circles, group centered
max_line_w = max(line_widths)
group_w = circle_d + circle_gap + max_line_w
group_left = (SIZE - group_w) // 2

circle_cx = group_left + circle_d // 2
line_left = group_left + circle_d + circle_gap

# Centered vertically
center_y = SIZE // 2
line_centers_y = [center_y - line_gap, center_y, center_y + line_gap]

# Refined gold palette
amber = (225, 175, 68)         # Rich warm gold
amber_bright = (250, 215, 125) # Luminous center

# =============================================================
# 5. GLOW PASS 1: Ultra-wide atmosphere (blur 120)
# =============================================================

g0 = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
g0d = ImageDraw.Draw(g0)
pad = 20
for i, w in enumerate(line_widths):
    yc = line_centers_y[i]
    y0 = yc - line_h // 2
    g0d.rounded_rectangle(
        [line_left - pad, y0 - pad, line_left + w + pad, y0 + line_h + pad],
        radius=line_r + pad,
        fill=(*amber, 70),
    )
    cr = circle_d // 2 + pad
    g0d.ellipse(
        [circle_cx - cr, yc - cr, circle_cx + cr, yc + cr],
        outline=(*amber, 70),
        width=circle_stroke + pad,
    )
g0 = g0.filter(ImageFilter.GaussianBlur(radius=120))
img = Image.alpha_composite(img, g0)

# =============================================================
# 6. GLOW PASS 2: Wide ambient (blur 60)
# =============================================================

g1 = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
g1d = ImageDraw.Draw(g1)
pad = 10
for i, w in enumerate(line_widths):
    yc = line_centers_y[i]
    y0 = yc - line_h // 2
    g1d.rounded_rectangle(
        [line_left - pad, y0 - pad, line_left + w + pad, y0 + line_h + pad],
        radius=line_r + pad,
        fill=(*amber, 120),
    )
    cr = circle_d // 2 + pad
    g1d.ellipse(
        [circle_cx - cr, yc - cr, circle_cx + cr, yc + cr],
        outline=(*amber, 120),
        width=circle_stroke + pad,
    )
g1 = g1.filter(ImageFilter.GaussianBlur(radius=60))
img = Image.alpha_composite(img, g1)

# =============================================================
# 7. GLOW PASS 3: Medium proximity (blur 28)
# =============================================================

g2 = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
g2d = ImageDraw.Draw(g2)
pad = 4
for i, w in enumerate(line_widths):
    yc = line_centers_y[i]
    y0 = yc - line_h // 2
    g2d.rounded_rectangle(
        [line_left - pad, y0 - pad, line_left + w + pad, y0 + line_h + pad],
        radius=line_r + pad,
        fill=(*amber_bright, 160),
    )
    cr = circle_d // 2 + pad
    g2d.ellipse(
        [circle_cx - cr, yc - cr, circle_cx + cr, yc + cr],
        outline=(*amber_bright, 160),
        width=circle_stroke + pad,
    )
g2 = g2.filter(ImageFilter.GaussianBlur(radius=28))
img = Image.alpha_composite(img, g2)

# =============================================================
# 8. GLOW PASS 4: Tight halo (blur 10)
# =============================================================

g3 = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
g3d = ImageDraw.Draw(g3)
pad = 1
for i, w in enumerate(line_widths):
    yc = line_centers_y[i]
    y0 = yc - line_h // 2
    g3d.rounded_rectangle(
        [line_left - pad, y0 - pad, line_left + w + pad, y0 + line_h + pad],
        radius=line_r + pad,
        fill=(*amber_bright, 210),
    )
    cr = circle_d // 2 + pad
    g3d.ellipse(
        [circle_cx - cr, yc - cr, circle_cx + cr, yc + cr],
        outline=(*amber_bright, 210),
        width=circle_stroke + pad,
    )
g3 = g3.filter(ImageFilter.GaussianBlur(radius=10))
img = Image.alpha_composite(img, g3)

# =============================================================
# 9. SHARP LINES & CIRCLES: The core forms
# =============================================================

lines = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
lines_draw = ImageDraw.Draw(lines)
for i, w in enumerate(line_widths):
    yc = line_centers_y[i]
    y0 = yc - line_h // 2
    # Line
    lines_draw.rounded_rectangle(
        [line_left, y0, line_left + w, y0 + line_h],
        radius=line_r,
        fill=(*amber, 255),
    )
    # Unfilled circle
    cr = circle_d // 2
    lines_draw.ellipse(
        [circle_cx - cr, yc - cr, circle_cx + cr, yc + cr],
        outline=(*amber, 255),
        width=circle_stroke,
    )
img = Image.alpha_composite(img, lines)

# =============================================================
# 10. LINE HIGHLIGHTS: Bright core for luminous center
# =============================================================

highlights = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
hl_draw = ImageDraw.Draw(highlights)
hl_h = max(line_h - 6, 4)
hl_r = max(hl_h // 2, 2)
for i, w in enumerate(line_widths):
    hl_w = int(w * 0.65)
    x0 = line_left + (w - hl_w) // 2
    yc = line_centers_y[i]
    y0 = yc - hl_h // 2
    hl_draw.rounded_rectangle(
        [x0, y0, x0 + hl_w, y0 + hl_h],
        radius=hl_r,
        fill=(255, 240, 185, 120),
    )
highlights = highlights.filter(ImageFilter.GaussianBlur(radius=6))
img = Image.alpha_composite(img, highlights)

# =============================================================
# 11. EDGE VIGNETTE: Darken corners for depth
# =============================================================

vignette = np.clip(dist / (SIZE * 0.55), 0.0, 1.0) ** 2.5
vig_alpha = (vignette * 60).astype(np.uint8)
vig_arr = np.stack([
    np.zeros((SIZE, SIZE), dtype=np.uint8),
    np.zeros((SIZE, SIZE), dtype=np.uint8),
    np.zeros((SIZE, SIZE), dtype=np.uint8),
    vig_alpha,
], axis=-1)
vig_img = Image.fromarray(vig_arr, "RGBA")
img = Image.alpha_composite(img, vig_img)

# =============================================================
# 10. SAVE
# =============================================================

final = img.convert("RGB")
final.save(OUTPUT, "PNG")
print(f"Saved: {OUTPUT} ({final.size[0]}x{final.size[1]})")
