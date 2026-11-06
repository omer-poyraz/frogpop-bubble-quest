#!/usr/bin/env python3
"""Compose store screenshots: real Godot gameplay frames + headline on a themed gradient."""
import os, sys, subprocess
from PIL import Image, ImageDraw, ImageFont, ImageFilter
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
FONT = os.path.join(ROOT, "assets", "fonts", "Fredoka.ttf")
def font(size):
    f = ImageFont.truetype(FONT, size)
    try: f.set_variation_by_axes([700])
    except Exception: pass
    return f
HEADS = {
 "en": ["Aim. Shoot. POP!", "Chain reactions & big combos", "10 magical worlds, endless fun", "7 super power-ups", "Collect cute frog costumes", "Play offline, anywhere"],
 "tr": ["Nişan al. At. PATLAT!", "Zincir reaksiyonlar ve dev kombolar", "10 büyülü dünya, sonsuz eğlence", "7 süper güçlendirici", "Sevimli kurbağa kostümleri topla", "Çevrim dışı, her yerde oyna"]}
BGS = [((40, 150, 110), (10, 60, 70)), ((255, 140, 190), (120, 60, 150)), ((30, 160, 200), (10, 50, 110)), ((230, 110, 40), (80, 20, 30)), ((110, 80, 200), (30, 20, 90)), ((70, 200, 170), (14, 70, 96))]
def rounded(im, r):
    m = Image.new("L", im.size, 0); ImageDraw.Draw(m).rounded_rectangle([0, 0, im.width, im.height], radius=r, fill=255)
    out = im.convert("RGBA"); out.putalpha(m); return out
def compose(src, head, bg, out):
    W, H = 1080, 1920
    c0, c1 = bg
    canvas = Image.new("RGB", (W, H))
    px = canvas.load()
    for y in range(H):
        t = y / H
        col = tuple(int(c0[i] * (1 - t) + c1[i] * t) for i in range(3))
        for x in range(W): px[x, y] = col
    canvas = canvas.convert("RGBA")
    d = ImageDraw.Draw(canvas)
    f = font(96)
    # wrap headline into <= 2 lines
    words = head.split(); lines = [head]
    if d.textlength(head, font=f) > W - 120:
        best = None
        for i in range(1, len(words)):
            a = " ".join(words[:i]); b = " ".join(words[i:])
            w = max(d.textlength(a, font=f), d.textlength(b, font=f))
            if best is None or w < best[0]: best = (w, [a, b])
        lines = best[1]
    y = 70
    for ln in lines:
        d.text((W / 2, y + 60), ln, font=f, fill=(22, 34, 82, 255), anchor="mm", stroke_width=14, stroke_fill=(22, 34, 82, 255))
        d.text((W / 2, y + 60), ln, font=f, fill=(255, 255, 255, 255), anchor="mm", stroke_width=0)
        y += 112
    shot = Image.open(src).convert("RGB")
    tw = 930; th = int(tw * shot.height / shot.width)
    shot = shot.resize((tw, th), Image.LANCZOS)
    r = rounded(shot, 56)
    top = 330
    shadow = Image.new("RGBA", (tw + 80, th + 80), (0, 0, 0, 0)); ImageDraw.Draw(shadow).rounded_rectangle([40, 50, tw + 40, th + 50], radius=56, fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    canvas.alpha_composite(shadow, ((W - tw) // 2 - 40, top - 40))
    border = Image.new("RGBA", (tw + 16, th + 16), (255, 255, 255, 255)); border = rounded(border.convert("RGB"), 62)
    canvas.alpha_composite(border, ((W - tw) // 2 - 8, top - 8))
    canvas.alpha_composite(r, ((W - tw) // 2, top))
    canvas.convert("RGB").save(out)
if __name__ == "__main__":
    lang = sys.argv[1]
    frames = sys.argv[2:]   # 6 source pngs
    outdir = os.path.join(ROOT, "store", "screenshots", lang); os.makedirs(outdir, exist_ok=True)
    for i, src in enumerate(frames):
        compose(src, HEADS[lang][i], BGS[i], os.path.join(outdir, f"shot_{i+1}.png"))
    print("ok", lang)
