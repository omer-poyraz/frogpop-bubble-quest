import os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "assets", "bubbles")
PART = os.path.join(ROOT, "assets", "particles")
os.makedirs(OUT, exist_ok=True); os.makedirs(PART, exist_ok=True)
S = 192; SS = 2
COLORS = ["#ff4a5e", "#3d8bff", "#ffd23c", "#3fd96a", "#a65bff", "#ff8a2a", "#ff7ac8", "#27d6d0"]

def hex2rgb(h): h = h.lstrip("#"); return np.array([int(h[i:i+2], 16) / 255 for i in (0, 2, 4)])
def smooth(a, b, x): t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)

def sphere(col, kind="jelly"):
    n = S * SS
    y, x = np.mgrid[0:n, 0:n]
    u = (x + 0.5) / n * 2 - 1; v = (y + 0.5) / n * 2 - 1
    r = np.sqrt(u * u + v * v)
    z = np.sqrt(np.clip(1 - r * r, 0, 1))
    L = np.array([-0.38, -0.5, 0.78]); L /= np.linalg.norm(L)
    diff = np.clip(u * L[0] + v * L[1] + z * L[2], 0, 1)
    C = col
    base = C[None, None, :] * (0.50 + 0.62 * diff[..., None])
    # deeper saturated shadow side
    shade = smooth(-0.2, 0.9, (u * 0.5 + v * 0.8))
    base = base * (1 - 0.30 * shade[..., None]) + (C * 0.45)[None, None, :] * (0.30 * shade[..., None])
    # inner glow ring (jelly): light colour just inside the edge
    fres = np.power(1 - z, 2.4)
    light = C * 0.45 + 0.55
    base = base + light[None, None, :] * (0.55 * fres[..., None])
    # bounce light bottom right
    bl = np.exp(-(((u - 0.28) ** 2) + ((v - 0.55) ** 2)) / 0.05)
    base = base + (np.clip(C * 1.3, 0, 1))[None, None, :] * (0.35 * bl[..., None])
    # soft core glow
    core = np.exp(-((u + 0.05) ** 2 + (v + 0.05) ** 2) / 0.35)
    base = base + light[None, None, :] * (0.10 * core[..., None])
    # specular highlights
    def ell(cx, cy, rx, ry, rot):
        c, s = math.cos(rot), math.sin(rot)
        du, dv = u - cx, v - cy
        a = (du * c + dv * s) / rx; b = (-du * s + dv * c) / ry
        return np.clip(1 - np.sqrt(a * a + b * b), 0, 1)
    h1 = smooth(0.0, 0.35, ell(-0.36, -0.44, 0.34, 0.17, -0.65))
    h2 = smooth(0.0, 0.6, ell(0.40, 0.36, 0.10, 0.06, -0.6))
    h3 = smooth(0.0, 0.5, ell(-0.12, -0.66, 0.10, 0.05, -0.2))
    base = base + (0.92 * h1 + 0.5 * h2 + 0.55 * h3)[..., None]
    # dark outline ring
    edge = smooth(0.86, 0.97, r)
    base = base * (1 - 0.55 * edge[..., None]) + (C * 0.35)[None, None, :] * (0.55 * edge[..., None])
    alpha = 1 - smooth(0.955, 0.985, r)
    rgba = np.dstack([np.clip(base, 0, 1), alpha])
    im = Image.fromarray((rgba * 255).astype(np.uint8), "RGBA").resize((S, S), Image.LANCZOS)
    return im

def symbol_img(idx):
    n = S * 4
    im = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = n / 2; R = n * 0.24
    def poly(pts, **k): d.polygon(pts, **k)
    shapes = idx % 8
    fill = (255, 255, 255, 235); outl = (20, 20, 40, 200)
    def draw(fn):
        # outline pass then fill pass
        fn(outl, True); fn(fill, False)
    if shapes == 0:   # ring
        def f(col, o): d.ellipse([c-R-(8 if o else 0), c-R-(8 if o else 0), c+R+(8 if o else 0), c+R+(8 if o else 0)], fill=col)
        draw(f); d.ellipse([c-R*0.5, c-R*0.5, c+R*0.5, c+R*0.5], fill=(0, 0, 0, 0))
        # punch hole by redrawing transparent
        im2 = im.copy(); mask = Image.new("L", (n, n), 0); md = ImageDraw.Draw(mask); md.ellipse([c-R*0.5, c-R*0.5, c+R*0.5, c+R*0.5], fill=255)
        im.paste((0, 0, 0, 0), mask=mask)
    elif shapes == 1:  # triangle
        pts = [(c, c - R * 1.1), (c + R * 1.05, c + R * 0.8), (c - R * 1.05, c + R * 0.8)]
        def f(col, o): poly(pts, fill=col, outline=col, width=16 if o else 0)
        draw(f)
    elif shapes == 2:  # square
        def f(col, o): d.rounded_rectangle([c-R-(8 if o else 0), c-R-(8 if o else 0), c+R+(8 if o else 0), c+R+(8 if o else 0)], radius=18, fill=col)
        draw(f)
    elif shapes == 3:  # diamond
        pts = [(c, c - R * 1.25), (c + R * 1.0, c), (c, c + R * 1.25), (c - R * 1.0, c)]
        def f(col, o): poly(pts, fill=col, outline=col, width=16 if o else 0)
        draw(f)
    elif shapes == 4:  # star
        pts = []
        for i in range(10):
            a = -math.pi / 2 + i * math.pi / 5; rr = R * 1.25 if i % 2 == 0 else R * 0.55
            pts.append((c + rr * math.cos(a), c + rr * math.sin(a)))
        def f(col, o): poly(pts, fill=col, outline=col, width=14 if o else 0)
        draw(f)
    elif shapes == 5:  # plus
        def f(col, o):
            e = 8 if o else 0
            d.rounded_rectangle([c-R*1.1-e, c-R*0.38-e, c+R*1.1+e, c+R*0.38+e], radius=10, fill=col)
            d.rounded_rectangle([c-R*0.38-e, c-R*1.1-e, c+R*0.38+e, c+R*1.1+e], radius=10, fill=col)
        draw(f)
    elif shapes == 6:  # heart
        def f(col, o):
            e = 8 if o else 0
            d.ellipse([c-R*1.15-e, c-R*0.95-e, c+R*0.05+e, c+R*0.25+e], fill=col)
            d.ellipse([c-R*0.05-e, c-R*0.95-e, c+R*1.15+e, c+R*0.25+e], fill=col)
            poly([(c-R*1.12-e, c-R*0.2), (c+R*1.12+e, c-R*0.2), (c, c+R*1.15+e)], fill=col)
        draw(f)
    else:  # crescent
        def f(col, o): d.ellipse([c-R-(8 if o else 0), c-R-(8 if o else 0), c+R+(8 if o else 0), c+R+(8 if o else 0)], fill=col)
        draw(f)
        mask = Image.new("L", (n, n), 0); md = ImageDraw.Draw(mask); md.ellipse([c-R*0.55+R*0.55, c-R*0.85, c+R*1.5, c+R*0.85], fill=255)
        im.paste((0, 0, 0, 0), mask=mask)
    return im.resize((S, S), Image.LANCZOS)

for i, h in enumerate(COLORS):
    sphere(hex2rgb(h)).save(os.path.join(OUT, f"ball_{i}.png"))
    symbol_img(i).save(os.path.join(OUT, f"sym_{i}.png"))

# rainbow ball
def rainbow():
    n = S * SS
    y, x = np.mgrid[0:n, 0:n]
    u = (x + 0.5) / n * 2 - 1; v = (y + 0.5) / n * 2 - 1
    ang = (np.arctan2(v, u) / (2 * math.pi)) % 1.0
    import colorsys
    h = ang
    # hsv->rgb vectorised
    i = np.floor(h * 6).astype(int) % 6; f = h * 6 - np.floor(h * 6)
    q = 1 - f; t = f
    r = np.choose(i, [np.ones_like(f), q, np.zeros_like(f), np.zeros_like(f), t, np.ones_like(f)])
    g = np.choose(i, [t, np.ones_like(f), np.ones_like(f), q, np.zeros_like(f), np.zeros_like(f)])
    b = np.choose(i, [np.zeros_like(f), np.zeros_like(f), t, np.ones_like(f), np.ones_like(f), q])
    col = np.dstack([r, g, b]) * 0.85 + 0.1
    rr = np.sqrt(u * u + v * v); z = np.sqrt(np.clip(1 - rr * rr, 0, 1))
    L = np.array([-0.38, -0.5, 0.78]); L /= np.linalg.norm(L)
    diff = np.clip(u * L[0] + v * L[1] + z * L[2], 0, 1)
    col = col * (0.55 + 0.6 * diff[..., None]) + (np.power(1 - z, 2.4) * 0.5)[..., None]
    def ell(cx, cy, rx, ry, rot):
        c_, s_ = math.cos(rot), math.sin(rot)
        du, dv = u - cx, v - cy
        a = (du * c_ + dv * s_) / rx; b2 = (-du * s_ + dv * c_) / ry
        return np.clip(1 - np.sqrt(a * a + b2 * b2), 0, 1)
    col += (0.9 * smooth(0, 0.35, ell(-0.36, -0.44, 0.34, 0.17, -0.65)))[..., None]
    edge = smooth(0.86, 0.97, rr)
    col = col * (1 - 0.5 * edge[..., None])
    alpha = 1 - smooth(0.955, 0.985, rr)
    Image.fromarray((np.dstack([np.clip(col, 0, 1), alpha]) * 255).astype(np.uint8), "RGBA").resize((S, S), Image.LANCZOS).save(os.path.join(OUT, "ball_rainbow.png"))
rainbow()

def sphere_gray(base_rgb, noise=0.0, seed=1):
    n = S * SS
    y, x = np.mgrid[0:n, 0:n]
    u = (x + 0.5) / n * 2 - 1; v = (y + 0.5) / n * 2 - 1
    r = np.sqrt(u * u + v * v); z = np.sqrt(np.clip(1 - r * r, 0, 1))
    L = np.array([-0.38, -0.5, 0.78]); L /= np.linalg.norm(L)
    diff = np.clip(u * L[0] + v * L[1] + z * L[2], 0, 1)
    rng = np.random.default_rng(seed)
    nz = rng.random((24, 24)); nz = np.array(Image.fromarray((nz * 255).astype(np.uint8)).resize((n, n), Image.BICUBIC)) / 255.0
    col = np.array(base_rgb)[None, None, :] * (0.45 + 0.65 * diff[..., None]) * (1 + noise * (nz[..., None] - 0.5))
    col = col + (np.power(1 - z, 2.6) * 0.25)[..., None]
    return u, v, r, z, col

# bomb
u, v, r, z, col = sphere_gray([0.16, 0.17, 0.22])
def ell(cx, cy, rx, ry, rot):
    c_, s_ = math.cos(rot), math.sin(rot)
    du, dv = u - cx, v - cy
    a = (du * c_ + dv * s_) / rx; b = (-du * s_ + dv * c_) / ry
    return np.clip(1 - np.sqrt(a * a + b * b), 0, 1)
col = col + (0.85 * smooth(0, 0.35, ell(-0.34, -0.42, 0.30, 0.15, -0.65)))[..., None]
col = col * (1 - 0.4 * smooth(0.86, 0.97, r)[..., None])
alpha = 1 - smooth(0.955, 0.985, r)
im = Image.fromarray((np.dstack([np.clip(col, 0, 1), alpha]) * 255).astype(np.uint8), "RGBA").resize((S, S), Image.LANCZOS)
d = ImageDraw.Draw(im)
d.arc([S*0.50, S*0.0, S*0.95, S*0.45], 180, 270, fill=(190, 150, 90, 255), width=7)
d.ellipse([S*0.78, S*0.02, S*0.92, S*0.16], fill=(255, 190, 60, 255)); d.ellipse([S*0.82, S*0.06, S*0.88, S*0.12], fill=(255, 255, 220, 255))
# skull-ish danger mark: red band
d.ellipse([S*0.37, S*0.45, S*0.63, S*0.71], fill=(255, 70, 70, 255)); d.ellipse([S*0.43, S*0.50, S*0.57, S*0.62], fill=(255, 220, 220, 255))
im.save(os.path.join(OUT, "ball_bomb.png"))

# stone (2 states)
for name, cracks in (("ball_stone", 0), ("ball_stone_cracked", 1)):
    u, v, r, z, col = sphere_gray([0.52, 0.52, 0.56], noise=0.55, seed=4)
    alpha = 1 - smooth(0.955, 0.985, r)
    col = col * (1 - 0.4 * smooth(0.86, 0.97, r)[..., None])
    im = Image.fromarray((np.dstack([np.clip(col, 0, 1), alpha]) * 255).astype(np.uint8), "RGBA").resize((S, S), Image.LANCZOS)
    d = ImageDraw.Draw(im)
    if cracks:
        d.line([(S*0.52, S*0.12), (S*0.45, S*0.32), (S*0.58, S*0.46), (S*0.48, S*0.66), (S*0.56, S*0.88)], fill=(30, 28, 36, 255), width=6)
        d.line([(S*0.45, S*0.32), (S*0.28, S*0.40)], fill=(30, 28, 36, 255), width=4)
        d.line([(S*0.58, S*0.46), (S*0.76, S*0.52)], fill=(30, 28, 36, 255), width=4)
    else:
        d.line([(S*0.30, S*0.30), (S*0.42, S*0.38)], fill=(60, 58, 66, 255), width=4)
    im.save(os.path.join(OUT, name + ".png"))

# ---- particles ----
def glow(size, power=2.2, color=(255, 255, 255)):
    n = size
    y, x = np.mgrid[0:n, 0:n]
    r = np.sqrt(((x + .5) / n * 2 - 1) ** 2 + ((y + .5) / n * 2 - 1) ** 2)
    a = np.clip(1 - r, 0, 1) ** power
    rgba = np.dstack([np.ones((n, n)) * color[0] / 255, np.ones((n, n)) * color[1] / 255, np.ones((n, n)) * color[2] / 255, a])
    return Image.fromarray((rgba * 255).astype(np.uint8), "RGBA")
glow(128, 2.0).save(os.path.join(PART, "glow.png"))
glow(64, 3.0).save(os.path.join(PART, "spark.png"))

def star_tex(size=96, points=5, inner=0.45, soft=True):
    n = size * 4
    im = Image.new("RGBA", (n, n), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    pts = []
    for i in range(points * 2):
        a = -math.pi / 2 + i * math.pi / points; rr = n * 0.46 if i % 2 == 0 else n * 0.46 * inner
        pts.append((n / 2 + rr * math.cos(a), n / 2 + rr * math.sin(a)))
    d.polygon(pts, fill=(255, 255, 255, 255))
    im = im.filter(ImageFilter.GaussianBlur(3)).resize((size, size), Image.LANCZOS)
    return im
star_tex(96, 5, 0.45).save(os.path.join(PART, "star.png"))
star_tex(96, 4, 0.22).save(os.path.join(PART, "sparkle.png"))

def ring_tex(size=192):
    n = size * 2
    y, x = np.mgrid[0:n, 0:n]
    r = np.sqrt(((x + .5) / n * 2 - 1) ** 2 + ((y + .5) / n * 2 - 1) ** 2)
    a = smooth(0.72, 0.86, r) * (1 - smooth(0.9, 1.0, r))
    rgba = np.dstack([np.ones((n, n)), np.ones((n, n)), np.ones((n, n)), a])
    return Image.fromarray((rgba * 255).astype(np.uint8), "RGBA").resize((size, size), Image.LANCZOS)
ring_tex().save(os.path.join(PART, "ring.png"))

# shard (small rounded triangle)
n = 128; im = Image.new("RGBA", (n, n), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
d.polygon([(n*0.5, n*0.1), (n*0.9, n*0.85), (n*0.1, n*0.85)], fill=(255, 255, 255, 255)); im = im.filter(ImageFilter.GaussianBlur(2)).resize((48, 48), Image.LANCZOS); im.save(os.path.join(PART, "shard.png"))
# white disc for shader-driven sprites
n = 128; y, x = np.mgrid[0:n, 0:n]; r = np.sqrt(((x + .5) / n * 2 - 1) ** 2 + ((y + .5) / n * 2 - 1) ** 2)
a = 1 - smooth(0.96, 1.0, r)
Image.fromarray((np.dstack([np.ones((n, n)), np.ones((n, n)), np.ones((n, n)), a]) * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "disc.png"))
# golden ring overlay
n = 256; y, x = np.mgrid[0:n, 0:n]; r = np.sqrt(((x + .5) / n * 2 - 1) ** 2 + ((y + .5) / n * 2 - 1) ** 2)
a = smooth(0.62, 0.9, r) * (1 - smooth(0.92, 1.0, r))
col = np.dstack([np.ones((n, n)) * 1.0, np.ones((n, n)) * 0.85, np.ones((n, n)) * 0.3, a * 0.95])
Image.fromarray((col * 255).astype(np.uint8), "RGBA").resize((S, S), Image.LANCZOS).save(os.path.join(OUT, "gold_ring.png"))
print("bubbles ok")
