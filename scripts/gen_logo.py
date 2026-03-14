"""
NeuralKB Logo Generator
Design: Neural network "N" lettermark — 3 glowing nodes connected by lines
forming a stylised N shape, on a deep dark background, in violet/purple.
"""
import math
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
OUT_DIR = "assets/icon"

# ── Palette ──────────────────────────────────────────────────────────────────
BG        = (9,   9,  16, 255)   # #090910
NODE_1    = (167, 139, 250, 255)  # violet-400  #A78BFA
NODE_2    = (124,  58, 237, 255)  # violet-600  #7C3AED
GLOW_COL  = (124,  58, 237, 120)  # glow layer
LINE_COL  = (167, 139, 250, 200)  # connecting lines
WHITE     = (255, 255, 255, 255)

# ── Helper: draw a filled circle on an RGBA layer ────────────────────────────
def draw_circle(draw, cx, cy, r, fill):
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill)


def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(4))


def gradient_line(layer, x1, y1, x2, y2, col1, col2, width=12):
    """Draw a gradient line by stepping along it."""
    steps = max(int(math.hypot(x2 - x1, y2 - y1)), 1)
    draw = ImageDraw.Draw(layer)
    for i in range(steps + 1):
        t = i / steps
        x = x1 + (x2 - x1) * t
        y = y1 + (y2 - y1) * t
        col = lerp_color(col1, col2, t)
        r = width // 2
        draw.ellipse([x - r, y - r, x + r, y + r], fill=col)


# ── Build icon ───────────────────────────────────────────────────────────────
def make_icon(size=SIZE):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # 1. Background — rounded square
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)
    radius = int(size * 0.22)
    bg_draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=BG)

    # 2. Subtle radial centre glow on background
    glow_bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow_bg)
    for step in range(20, 0, -1):
        r = int(size * 0.48 * step / 20)
        alpha = int(18 * (1 - step / 20))
        gd.ellipse(
            [size // 2 - r, size // 2 - r, size // 2 + r, size // 2 + r],
            fill=(124, 58, 237, alpha),
        )
    glow_bg = glow_bg.filter(ImageFilter.GaussianBlur(radius=size * 0.08))
    bg = Image.alpha_composite(bg, glow_bg)

    # Mask glow to rounded rect
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size - 1, size - 1], radius=radius, fill=255
    )
    bg.putalpha(mask)
    img = Image.alpha_composite(img, bg)

    # ── Neural-N layout ──────────────────────────────────────────────────────
    # Three primary nodes:
    #   TL (top-left)  TR (top-right)  BL (bottom-left)  BR (bottom-right)
    # The letter N uses: TL → BL (left stroke), TL → BR (diagonal), TR → BR (right stroke)
    pad   = size * 0.22
    mid_y = size * 0.50

    tl = (pad,              pad)
    tr = (size - pad,       pad)
    bl = (pad,              size - pad)
    br = (size - pad,       size - pad)

    # ── Glow halos behind lines (blurred) ────────────────────────────────────
    halo = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gradient_line(halo, *tl, *bl, (124,58,237,120), (167,139,250,120), width=40)
    gradient_line(halo, *tl, *br, (124,58,237,100), (167,139,250,100), width=36)
    gradient_line(halo, *tr, *br, (167,139,250,120), (124,58,237,120), width=40)
    halo = halo.filter(ImageFilter.GaussianBlur(radius=size * 0.04))
    img = Image.alpha_composite(img, halo)

    # ── Lines ────────────────────────────────────────────────────────────────
    lines = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gradient_line(lines, *tl, *bl, NODE_1, NODE_2, width=14)
    gradient_line(lines, *tl, *br, NODE_1, NODE_2, width=14)
    gradient_line(lines, *tr, *br, NODE_2, NODE_1, width=14)
    img = Image.alpha_composite(img, lines)

    # ── Node glow halos ───────────────────────────────────────────────────────
    nh = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    nd = ImageDraw.Draw(nh)
    node_glow_r = int(size * 0.085)
    for nx, ny in [tl, tr, bl, br]:
        draw_circle(nd, nx, ny, node_glow_r, (167, 139, 250, 60))
    nh = nh.filter(ImageFilter.GaussianBlur(radius=size * 0.045))
    img = Image.alpha_composite(img, nh)

    # ── Nodes (filled circles) ────────────────────────────────────────────────
    nodes = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    nd2 = ImageDraw.Draw(nodes)
    outer_r = int(size * 0.055)
    inner_r = int(size * 0.032)
    for i, (nx, ny) in enumerate([tl, tr, bl, br]):
        # Outer ring in NODE_2
        draw_circle(nd2, nx, ny, outer_r, NODE_2)
        # Inner bright fill
        draw_circle(nd2, nx, ny, inner_r, NODE_1)
        # Tiny white highlight
        draw_circle(nd2, int(nx - inner_r * 0.3), int(ny - inner_r * 0.3),
                    int(inner_r * 0.28), (255, 255, 255, 200))
    img = Image.alpha_composite(img, nodes)

    # ── Re-apply rounded-rect mask so nothing bleeds outside ─────────────────
    final_mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(final_mask).rounded_rectangle(
        [0, 0, size - 1, size - 1], radius=radius, fill=255
    )
    img.putalpha(final_mask)

    return img


# ── Foreground layer (transparent bg, for adaptive icons) ────────────────────
def make_foreground(size=SIZE):
    """Same design but on transparent background, centred in a 108dp safe zone."""
    # Adaptive icon foreground: content should be in centre 66% (safe zone)
    # We shrink the neural-N to ~60% and centre it
    inner = make_icon(int(size * 0.60))
    fg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    offset = (size - int(size * 0.60)) // 2
    fg.paste(inner, (offset, offset), inner)
    # Remove the rounded-rect bg so only the artwork remains
    # Re-render without background
    return fg


if __name__ == "__main__":
    import os
    os.makedirs(OUT_DIR, exist_ok=True)

    print("Generating app_icon.png …")
    icon = make_icon(SIZE)
    icon.save(f"{OUT_DIR}/app_icon.png")
    print(f"  Saved {OUT_DIR}/app_icon.png  ({SIZE}×{SIZE})")

    # Also save a smaller preview
    icon.resize((512, 512), Image.LANCZOS).save(f"{OUT_DIR}/app_icon_512.png")

    print("Done.")
