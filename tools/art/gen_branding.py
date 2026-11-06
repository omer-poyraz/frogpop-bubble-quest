import os, math, random, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
sys.path.insert(0, os.path.dirname(__file__))
from compose_frog import compose
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
BR = os.path.join(ROOT, "assets", "branding"); os.makedirs(BR, exist_ok=True)
FONT = os.path.join(ROOT, "assets", "fonts", "Fredoka.ttf")
BUB = os.path.join(ROOT, "assets", "bubbles")
random.seed(5)

def font(size, wght=700):
    f = ImageFont.truetype(FONT, size)
    try: f.set_variation_by_axes([100, wght] if False else [wght])
    except Exception:
        try: f.set_variation_by_name("Bold")
        except Exception: pass
    return f

def vgrad(size, c0, c1):
    w, h = size
    a = np.linspace(0, 1, h)[:, None, None]
    c0 = np.array(c0)[None, None, :]; c1 = np.array(c1)[None, None, :]
    arr = (c0 * (1 - a) + c1 * a) * np.ones((h, w, 1))
    return Image.fromarray(arr.astype(np.uint8), "RGB").convert("RGBA")

def radial_bg(size, inner, outer, cx=0.5, cy=0.42):
    w, h = size
    y, x = np.mgrid[0:h, 0:w]
    d = np.sqrt(((x / w - cx) * (w / max(w, h))) ** 2 + ((y / h - cy) * (h / max(w, h))) ** 2) * 1.6
    d = np.clip(d, 0, 1)[..., None]
    arr = np.array(inner)[None, None, :] * (1 - d) + np.array(outer)[None, None, :] * d
    return Image.fromarray(arr.astype(np.uint8), "RGB").convert("RGBA")

def ball(i, size):
    return Image.open(os.path.join(BUB, f"ball_{i}.png")).convert("RGBA").resize((size, size), Image.LANCZOS)

def paste_c(dst, im, cx, cy, rot=0):
    if rot: im = im.rotate(rot, resample=Image.BICUBIC, expand=True)
    dst.alpha_composite(im, (int(cx - im.width / 2), int(cy - im.height / 2)))

def shadowed(im, off=(0, 10), blur=14, alpha=110):
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    a = im.split()[3].point(lambda v: v * alpha // 255)
    sh.putalpha(a); sh = sh.filter(ImageFilter.GaussianBlur(blur))
    out = Image.new("RGBA", im.size, (0, 0, 0, 0)); out.alpha_composite(sh, off); out.alpha_composite(im)
    return out

LETTER_COLS = [((255, 120, 130), (222, 40, 70)), ((255, 235, 120), (255, 170, 30)), ((120, 235, 140), (30, 170, 70)), ((120, 190, 255), (50, 110, 230)),
               ((205, 150, 255), (140, 70, 230)), ((255, 170, 90), (240, 100, 20)), ((255, 150, 210), (230, 70, 160))]

def logo_text(text="FROGPOP", size=300, spacing=-10):
    f = font(size, 700)
    # measure
    widths = [f.getbbox(ch)[2] - f.getbbox(ch)[0] for ch in text]
    adv = [f.getlength(ch) for ch in text]
    total = int(sum(adv) + spacing * (len(text) - 1)) + 120
    h = int(size * 1.5)
    canvas = Image.new("RGBA", (total, h), (0, 0, 0, 0))
    x = 60
    for i, ch in enumerate(text):
        mask = Image.new("L", (total, h), 0); ImageDraw.Draw(mask).text((x, 40 + (i % 2) * -8), ch, font=f, fill=255)
        outline = mask.filter(ImageFilter.MaxFilter(25))
        c0, c1 = LETTER_COLS[i % len(LETTER_COLS)]
        fill = vgrad((total, h), c0, c1)
        # outline dark navy
        ol = Image.new("RGBA", (total, h), (22, 34, 82, 255)); ol.putalpha(outline)
        # thick white rim just outside fill
        rim_mask = mask.filter(ImageFilter.MaxFilter(9))
        rim = Image.new("RGBA", (total, h), (255, 255, 255, 255)); rim.putalpha(rim_mask)
        canvas.alpha_composite(shadowed(ol, (0, 14), 10, 150))
        canvas.alpha_composite(rim)
        fl = fill.copy(); fl.putalpha(mask); canvas.alpha_composite(fl)
        # gloss: upper highlight band
        gloss = Image.new("RGBA", (total, h), (255, 255, 255, 0)); gd = ImageDraw.Draw(gloss)
        gd.ellipse([x - 20, 40 - size * 0.25, x + adv[i] + 20, 40 + size * 0.62], fill=(255, 255, 255, 90))
        gm = ImageChops.multiply(gloss.split()[3], mask); gloss.putalpha(gm); canvas.alpha_composite(gloss)
        # small specular dot
        sp = Image.new("RGBA", (total, h), (0, 0, 0, 0)); ImageDraw.Draw(sp).ellipse([x + adv[i] * 0.18, 40 + size * 0.2, x + adv[i] * 0.34, 40 + size * 0.34], fill=(255, 255, 255, 190))
        sp.putalpha(ImageChops.multiply(sp.split()[3], mask)); canvas.alpha_composite(sp)
        x += adv[i] + spacing
    return canvas

def crop_alpha(im, pad=10):
    bb = im.split()[3].getbbox()
    return im.crop((max(bb[0] - pad, 0), max(bb[1] - pad, 0), min(bb[2] + pad, im.width), min(bb[3] + pad, im.height)))

def ribbon(text, size=96, w=None):
    f = font(size, 700)
    tw = f.getlength(text); w = w or int(tw + 160); h = int(size * 1.7)
    im = Image.new("RGBA", (w + 80, h + 30), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rounded_rectangle([40, 12, w + 40, h], radius=int(h * 0.42), fill=(22, 34, 82, 255))
    d.rounded_rectangle([50, 22, w + 30, h - 12], radius=int(h * 0.36), fill=(255, 197, 48, 255))
    d.rounded_rectangle([50, 22, w + 30, h * 0.5], radius=int(h * 0.36), fill=(255, 226, 110, 255))
    d.text((40 + w / 2, h / 2 + 4), text, font=f, fill=(22, 34, 82, 255), anchor="mm")
    return shadowed(im, (0, 8), 8, 120)

def bubbles_scatter(img, n, region, sizes, seed=1, alpha=1.0):
    r = random.Random(seed)
    for _ in range(n):
        s = r.randint(*sizes); x = r.randint(region[0], region[2]); y = r.randint(region[1], region[3])
        b = ball(r.randint(0, 7), s)
        if alpha < 1: b.putalpha(b.split()[3].point(lambda v: int(v * alpha)))
        paste_c(img, b, x, y)

def sparkle(img, cx, cy, s, color=(255, 255, 255, 230)):
    d = ImageDraw.Draw(img)
    d.polygon([(cx, cy - s), (cx + s * 0.18, cy - s * 0.18), (cx + s, cy), (cx + s * 0.18, cy + s * 0.18), (cx, cy + s), (cx - s * 0.18, cy + s * 0.18), (cx - s, cy), (cx - s * 0.18, cy - s * 0.18)], fill=color)

# ---------- logo ----------
lt = crop_alpha(logo_text("FROGPOP", 300, -14), 20)
rb = ribbon("BUBBLE QUEST", 96)
frog = compose("royal", "open")
fw = 600
frog_s = frog.resize((fw, int(fw * 576 / 512)), Image.LANCZOS)
logo = Image.new("RGBA", (lt.width + 160, int(frog_s.height * 0.66) + lt.height + rb.height + 20), (0, 0, 0, 0))
logo.alpha_composite(shadowed(frog_s, (0, 10), 18, 120), (logo.width // 2 - frog_s.width // 2, 0))
logo.alpha_composite(lt, (logo.width // 2 - lt.width // 2, int(frog_s.height * 0.66)))
logo.alpha_composite(rb, (logo.width // 2 - rb.width // 2, int(frog_s.height * 0.66) + lt.height - 20))
for (cx, cy, s, i) in [(60, 300, 120, 1), (logo.width - 70, 330, 140, 5), (110, 160, 70, 3), (logo.width - 120, 150, 80, 0)]:
    paste_c(logo, ball(i, s), cx, cy)
logo = crop_alpha(logo, 10)
logo.save(os.path.join(BR, "logo.png"))
logo_wide = crop_alpha(Image.alpha_composite(Image.new("RGBA", (lt.width + 40, lt.height + rb.height), (0, 0, 0, 0)), Image.new("RGBA", (1, 1))), 0) if False else None

# wordmark-only (for in-game menu next to animated frog)
word = Image.new("RGBA", (lt.width + 40, lt.height + rb.height - 10), (0, 0, 0, 0))
word.alpha_composite(lt, (20, 0)); word.alpha_composite(rb, (word.width // 2 - rb.width // 2, lt.height - 30))
word = crop_alpha(word, 6); word.save(os.path.join(BR, "wordmark.png"))

# ---------- mascot ----------
m = compose("royal", "open"); m = m.resize((1024, 1152), Image.LANCZOS); m.save(os.path.join(BR, "mascot.png"))

# ---------- icon ----------
def make_icon(size=1024, rounded=False):
    bg = radial_bg((size, size), (70, 220, 190), (12, 80, 90), 0.5, 0.40)
    d = ImageDraw.Draw(bg)
    # rays
    ov = Image.new("RGBA", (size, size), (0, 0, 0, 0)); od = ImageDraw.Draw(ov)
    for k in range(16):
        a0 = k * math.tau / 16; a1 = a0 + math.tau / 32
        od.polygon([(size / 2, size * 0.45), (size / 2 + size * math.cos(a0), size * 0.45 + size * math.sin(a0)), (size / 2 + size * math.cos(a1), size * 0.45 + size * math.sin(a1))], fill=(255, 255, 255, 18))
    bg.alpha_composite(ov)
    for (cx, cy, s, i) in [(0.14, 0.78, 0.22, 0), (0.86, 0.74, 0.25, 1), (0.2, 0.2, 0.15, 2), (0.84, 0.2, 0.17, 4), (0.5, 0.93, 0.18, 5), (0.07, 0.48, 0.1, 6), (0.93, 0.47, 0.1, 7)]:
        paste_c(bg, ball(i, int(size * s)), size * cx, size * cy)
    fr = compose("royal", "open").crop((20, 10, 492, 520)) if False else compose("royal", "open")
    fh = int(size * 0.98); fwid = int(fh * 512 / 576)
    fr = fr.resize((fwid, fh), Image.LANCZOS)
    bg.alpha_composite(shadowed(fr, (0, 12), 16, 120), (size // 2 - fwid // 2, int(size * 0.07)))
    sparkle(bg, size * 0.77, size * 0.38, size * 0.07); sparkle(bg, size * 0.22, size * 0.52, size * 0.04)
    if rounded:
        mask = Image.new("L", (size, size), 0); ImageDraw.Draw(mask).rounded_rectangle([0, 0, size, size], radius=int(size * 0.22), fill=255)
        bg.putalpha(mask)
    return bg
icon = make_icon(1024); icon.convert("RGB").save(os.path.join(BR, "icon_1024_opaque.png"))
make_icon(1024, True).save(os.path.join(BR, "icon.png"))
icon.convert("RGB").resize((512, 512), Image.LANCZOS).save(os.path.join(BR, "play_store_icon_512.png"))
# android adaptive
fg = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
fr = compose("royal", "open"); fh = 300; fwid = int(fh * 512 / 576); fr = fr.resize((fwid, fh), Image.LANCZOS)
fg.alpha_composite(fr, (216 - fwid // 2, 66))
fg.save(os.path.join(BR, "adaptive_fg_432.png"))
radial_bg((432, 432), (70, 220, 190), (12, 80, 90), 0.5, 0.4).save(os.path.join(BR, "adaptive_bg_432.png"))
for s in (192, 144, 96, 72, 48, 36):
    icon.convert("RGBA").resize((s, s), Image.LANCZOS).save(os.path.join(BR, f"android_{s}.png"))
# ios
ios_dir = os.path.join(BR, "ios_appicon"); os.makedirs(ios_dir, exist_ok=True)
for s in (1024, 180, 167, 152, 120, 87, 80, 76, 60, 58, 40, 29, 20):
    icon.convert("RGB").resize((s, s), Image.LANCZOS).save(os.path.join(ios_dir, f"AppIcon_{s}.png"))

# ---------- feature graphic 1024x500 ----------
def make_feature(w=1024, h=500, title_big=True):
    bg = radial_bg((w, h), (80, 215, 190), (14, 70, 96), 0.7, 0.4)
    bubbles_scatter(bg, 16, (0, 0, w, h), (40, 110), seed=4, alpha=0.92)
    fr = compose("royal", "open"); fh = int(h * 1.08); fwid = int(fh * 512 / 576); fr = fr.resize((fwid, fh), Image.LANCZOS)
    bg.alpha_composite(shadowed(fr, (0, 10), 14, 120), (int(w * 0.04), int(h * 0.0)))
    t = crop_alpha(logo_text("FROGPOP", 190, -8), 10); t = t.resize((int(w * 0.58), int(t.height * (w * 0.58) / t.width)), Image.LANCZOS)
    r = ribbon("BUBBLE QUEST", 64); r = r.resize((int(w * 0.40), int(r.height * (w * 0.40) / r.width)), Image.LANCZOS)
    bg.alpha_composite(t, (int(w * 0.38), int(h * 0.22))); bg.alpha_composite(r, (int(w * 0.47), int(h * 0.22) + t.height - 6))
    sparkle(bg, w * 0.34, h * 0.2, 26); sparkle(bg, w * 0.95, h * 0.13, 20)
    return bg
make_feature().convert("RGB").save(os.path.join(BR, "feature_graphic.png"))

# ---------- splash 1080x1920 ----------
def make_splash(w=1080, h=1920):
    bg = radial_bg((w, h), (66, 205, 175), (10, 50, 80), 0.5, 0.42)
    bubbles_scatter(bg, 26, (0, 0, w, h), (50, 160), seed=11, alpha=0.9)
    lg = crop_alpha(logo, 0); lg = lg.resize((int(w * 0.9), int(lg.height * (w * 0.9) / lg.width)), Image.LANCZOS)
    bg.alpha_composite(shadowed(lg, (0, 16), 22, 130), (w // 2 - lg.width // 2, int(h * 0.30)))
    f = font(54, 600)
    ImageDraw.Draw(bg).text((w // 2, int(h * 0.90)), "Poyraz Yazılım", font=f, fill=(255, 255, 255, 230), anchor="mm")
    return bg
make_splash().convert("RGB").save(os.path.join(BR, "splash.png"))
print("branding ok")
