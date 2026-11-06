import os, sys, random, math
sys.path.insert(0, os.path.dirname(__file__))
import gen_branding as B   # reuses helpers (also regenerates branding; harmless)
from PIL import Image, ImageDraw, ImageFont, ImageFilter
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "store", "video"); os.makedirs(OUT, exist_ok=True)
TEXT = {"en": ("ENDLESS", "BUBBLE FUN!"), "tr": ("SONSUZ", "BALON KEYFİ!")}
for lang, (l1, l2) in TEXT.items():
    W, H = 1280, 720
    bg = B.radial_bg((W, H), (255, 214, 90), (230, 90, 40), 0.72, 0.45) if False else B.radial_bg((W, H), (90, 225, 190), (14, 64, 110), 0.7, 0.42)
    d = ImageDraw.Draw(bg)
    ov = Image.new("RGBA", (W, H), (0, 0, 0, 0)); od = ImageDraw.Draw(ov)
    for k in range(18):
        a0 = k * math.tau / 18; a1 = a0 + math.tau / 36
        od.polygon([(W * 0.7, H * 0.45), (W * 0.7 + W * math.cos(a0), H * 0.45 + W * math.sin(a0)), (W * 0.7 + W * math.cos(a1), H * 0.45 + W * math.sin(a1))], fill=(255, 255, 255, 22))
    bg.alpha_composite(ov)
    random.seed(9)
    B.bubbles_scatter(bg, 18, (0, 0, W, H), (50, 150), seed=7, alpha=0.95)
    fr = B.compose("royal", "open"); fh = 640; fw = int(fh * 512 / 576)
    fr = fr.resize((fw, fh), Image.LANCZOS)
    bg.alpha_composite(B.shadowed(fr, (0, 12), 16, 130), (20, 80))
    dd = ImageDraw.Draw(bg)
    def fit(t, maxw, start=200):
        sz = start
        while sz > 40:
            ff = B.font(sz)
            if dd.textlength(t, font=ff) <= maxw: return ff
            sz -= 6
        return B.font(40)
    for i, t in enumerate((l1, l2)):
        f = fit(t, 700, 190 if i == 0 else 150)
        y = 190 + i * 200
        tmp = Image.new("RGBA", (W, H), (0, 0, 0, 0)); td = ImageDraw.Draw(tmp)
        td.text((W * 0.68, y), t, font=f, fill=(255, 255, 255, 255), anchor="mm", stroke_width=22, stroke_fill=(22, 34, 82, 255))
        bg.alpha_composite(B.shadowed(tmp, (0, 10), 8, 150))
        td2 = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d2 = ImageDraw.Draw(td2)
        col = (255, 226, 70, 255) if i == 0 else (255, 255, 255, 255)
        d2.text((W * 0.68, y), t, font=f, fill=col, anchor="mm")
        bg.alpha_composite(td2)
    rb = B.ribbon("FROGPOP", 70)
    bg.alpha_composite(rb, (int(W * 0.67 - rb.width / 2), 540))
    B.sparkle(bg, W * 0.9, 120, 40); B.sparkle(bg, W * 0.45, 90, 26)
    bg.convert("RGB").save(os.path.join(OUT, f"thumbnail_1280x720_{lang}.png"), optimize=True)
print("thumbs ok")
