#!/usr/bin/env python3
"""Layered original frog mascot. Each part is rendered as its own 512x576 PNG, all sharing one origin,
so the game can stack/animate them (frog coordinates are shifted +64 in y to leave room for hats)."""
import os, subprocess, sys
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "characters")
SVGDIR = os.path.join(os.path.dirname(__file__), "..", "..", "build", "svg")
os.makedirs(OUT, exist_ok=True); os.makedirs(SVGDIR, exist_ok=True)
W, H = 512, 576
OL = "#1c5e2e"  # outline

DEFS = f"""
<defs>
 <radialGradient id="skin" cx="38%" cy="28%" r="85%"><stop offset="0" stop-color="#a6f77c"/><stop offset="0.45" stop-color="#52d24f"/><stop offset="1" stop-color="#23963f"/></radialGradient>
 <radialGradient id="skin2" cx="40%" cy="25%" r="90%"><stop offset="0" stop-color="#8eec6c"/><stop offset="0.55" stop-color="#3fc04b"/><stop offset="1" stop-color="#1f8a3b"/></radialGradient>
 <radialGradient id="belly" cx="45%" cy="30%" r="80%"><stop offset="0" stop-color="#fbffd6"/><stop offset="0.6" stop-color="#e3fb9c"/><stop offset="1" stop-color="#b9ea70"/></radialGradient>
 <radialGradient id="eyew" cx="40%" cy="35%" r="80%"><stop offset="0" stop-color="#ffffff"/><stop offset="0.75" stop-color="#f4f8ff"/><stop offset="1" stop-color="#c9d6ee"/></radialGradient>
 <radialGradient id="pupil" cx="40%" cy="35%" r="75%"><stop offset="0" stop-color="#3c4f7a"/><stop offset="0.5" stop-color="#1d2748"/><stop offset="1" stop-color="#0b1022"/></radialGradient>
 <radialGradient id="cheek" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#ff7aa0" stop-opacity="0.95"/><stop offset="1" stop-color="#ff7aa0" stop-opacity="0"/></radialGradient>
 <linearGradient id="tongue" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ff8fb0"/><stop offset="1" stop-color="#e5436f"/></linearGradient>
 <radialGradient id="mouthin" cx="50%" cy="30%" r="80%"><stop offset="0" stop-color="#a83453"/><stop offset="1" stop-color="#5b1230"/></radialGradient>
 <linearGradient id="gold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff3a6"/><stop offset="0.5" stop-color="#ffcf3a"/><stop offset="1" stop-color="#d98a12"/></linearGradient>
 <linearGradient id="purple" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9b6bff"/><stop offset="1" stop-color="#4a2aa8"/></linearGradient>
 <linearGradient id="dark" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4a4f66"/><stop offset="1" stop-color="#1a1d2c"/></linearGradient>
 <linearGradient id="red" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ff6a6a"/><stop offset="1" stop-color="#c21f3a"/></linearGradient>
 <linearGradient id="cosmic" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#2d1b7a"/><stop offset="0.5" stop-color="#6a35d8"/><stop offset="1" stop-color="#1fa5e8"/></linearGradient>
 <radialGradient id="glass" cx="35%" cy="28%" r="75%"><stop offset="0" stop-color="#ffffff" stop-opacity="0.55"/><stop offset="0.5" stop-color="#bfe6ff" stop-opacity="0.10"/><stop offset="1" stop-color="#7fc8ff" stop-opacity="0.22"/></radialGradient>
 <filter id="blur4"><feGaussianBlur stdDeviation="4"/></filter>
 <filter id="blur10"><feGaussianBlur stdDeviation="10"/></filter>
</defs>"""

def svg(body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{DEFS}<g transform="translate(0,64)">{body}</g></svg>'

def hl(cx, cy, rx, ry, rot=-25, op=0.7):
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" transform="rotate({rot} {cx} {cy})" fill="#fff" opacity="{op}"/>'

parts = {}

parts["shadow"] = '<ellipse cx="256" cy="470" rx="190" ry="34" fill="#000" opacity="0.28" filter="url(#blur10)"/>'

def leg(sx):
    # thigh + webbed foot, mirrored by sx (-1 left, 1 right) around x=256
    def X(x): return 256 + sx*(x-256)
    return f"""
<g>
 <ellipse cx="{X(372)}" cy="392" rx="78" ry="62" fill="url(#skin2)" stroke="{OL}" stroke-width="7"/>
 <path d="M {X(330)} 440 q {sx*40} 46 {sx*98} 22 q {sx*26} -10 {sx*30} -28 q -20 -14 {-sx*18} -4 q -10 -26 {-sx*30} -6 q -14 -22 {-sx*34} -2 q -12 -22 {-sx*28} 4 q -14 14 {-sx*18} 14 z"
       fill="url(#skin)" stroke="{OL}" stroke-width="7" stroke-linejoin="round"/>
 {hl(X(380), 372, 28, 12, -20*sx, 0.45)}
</g>"""
parts["leg_l"] = leg(-1)
parts["leg_r"] = leg(1)

parts["body"] = f"""
<ellipse cx="256" cy="345" rx="148" ry="120" fill="url(#skin)" stroke="{OL}" stroke-width="8"/>
{hl(190, 290, 44, 20, -30, 0.5)}
"""
parts["belly"] = f"""
<ellipse cx="256" cy="372" rx="98" ry="82" fill="url(#belly)" stroke="#9fd25f" stroke-width="4"/>
<ellipse cx="256" cy="392" rx="64" ry="40" fill="#ffffff" opacity="0.22"/>
"""

def arm(sx):
    def X(x): return 256 + sx*(x-256)
    return f"""
<g>
 <path d="M {X(372)} 318 q {sx*38} 28 {sx*10} 82 q -16 22 {-sx*8} 20 q -26 -4 {-sx*16} -40 q -4 -40 {-sx*8} -62 z" fill="url(#skin)" stroke="{OL}" stroke-width="7" stroke-linejoin="round"/>
 <ellipse cx="{X(392)}" cy="420" rx="34" ry="22" fill="url(#skin)" stroke="{OL}" stroke-width="7"/>
 <circle cx="{X(372)}" cy="436" r="11" fill="url(#skin)" stroke="{OL}" stroke-width="6"/>
 <circle cx="{X(396)}" cy="442" r="11" fill="url(#skin)" stroke="{OL}" stroke-width="6"/>
 <circle cx="{X(418)}" cy="432" r="11" fill="url(#skin)" stroke="{OL}" stroke-width="6"/>
</g>"""
parts["arm_l"] = arm(-1)
parts["arm_r"] = arm(1)

parts["head"] = f"""
<ellipse cx="190" cy="152" rx="76" ry="72" fill="url(#skin)" stroke="{OL}" stroke-width="8"/>
<ellipse cx="322" cy="152" rx="76" ry="72" fill="url(#skin)" stroke="{OL}" stroke-width="8"/>
<ellipse cx="256" cy="238" rx="188" ry="118" fill="url(#skin)" stroke="{OL}" stroke-width="8"/>
<ellipse cx="190" cy="152" rx="70" ry="66" fill="url(#skin)"/>
<ellipse cx="322" cy="152" rx="70" ry="66" fill="url(#skin)"/>
{hl(206, 262, 70, 18, -4, 0.22)}
<ellipse cx="236" cy="222" rx="6" ry="9" fill="{OL}" opacity="0.7"/>
<ellipse cx="276" cy="222" rx="6" ry="9" fill="{OL}" opacity="0.7"/>
"""
parts["cheek_l"] = '<ellipse cx="130" cy="262" rx="40" ry="26" fill="url(#cheek)"/>'
parts["cheek_r"] = '<ellipse cx="382" cy="262" rx="40" ry="26" fill="url(#cheek)"/>'

def eye_white(cx):
    return f'<ellipse cx="{cx}" cy="150" rx="58" ry="56" fill="url(#eyew)" stroke="#223" stroke-width="5"/>'
parts["eye_l"] = eye_white(190)
parts["eye_r"] = eye_white(322)

def pupil(cx):
    return f"""<circle cx="{cx}" cy="150" r="31" fill="url(#pupil)"/>
<circle cx="{cx-10}" cy="138" r="11" fill="#fff"/><circle cx="{cx+11}" cy="162" r="5.5" fill="#fff" opacity="0.9"/>"""
parts["pupil_l"] = pupil(190)
parts["pupil_r"] = pupil(322)

def lid(cx):
    # closed eyelid: skin-coloured cap covering the eye white, with lash line
    return f"""<ellipse cx="{cx}" cy="150" rx="62" ry="60" fill="url(#skin)" stroke="{OL}" stroke-width="7"/>
<path d="M {cx-44} 160 q 44 22 88 0" fill="none" stroke="{OL}" stroke-width="7" stroke-linecap="round"/>"""
parts["lid_l"] = lid(190)
parts["lid_r"] = lid(322)

def happy_eye(cx):
    return f"""<ellipse cx="{cx}" cy="150" rx="62" ry="60" fill="url(#skin)" stroke="{OL}" stroke-width="7"/>
<path d="M {cx-38} 168 q 38 -62 76 0" fill="none" stroke="#17331f" stroke-width="12" stroke-linecap="round"/>"""
parts["happy_l"] = happy_eye(190)
parts["happy_r"] = happy_eye(322)

parts["mouth_smile"] = f"""
<path d="M 160 270 q 96 70 192 0" fill="none" stroke="#17331f" stroke-width="9" stroke-linecap="round"/>
<path d="M 154 262 q 4 12 12 18 M 358 262 q -4 12 -12 18" fill="none" stroke="#17331f" stroke-width="7" stroke-linecap="round"/>
"""
parts["mouth_open"] = f"""
<path d="M 168 262 q 88 -14 176 0 q 8 70 -88 84 q -96 -14 -88 -84 z" fill="url(#mouthin)" stroke="#17331f" stroke-width="8" stroke-linejoin="round"/>
<ellipse cx="256" cy="326" rx="52" ry="22" fill="#e5436f" opacity="0.85"/>
"""
parts["mouth_o"] = f"""
<ellipse cx="256" cy="296" rx="34" ry="40" fill="url(#mouthin)" stroke="#17331f" stroke-width="8"/>
<ellipse cx="256" cy="312" rx="20" ry="14" fill="#e5436f" opacity="0.85"/>
"""
parts["mouth_sad"] = f"""
<path d="M 180 308 q 76 -50 152 0" fill="none" stroke="#17331f" stroke-width="9" stroke-linecap="round"/>
<path d="M 360 214 q 10 26 -2 38 q -14 -8 -8 -34 z" fill="#7fd6ff" stroke="#3a8fc4" stroke-width="3"/>
"""
parts["tongue"] = f"""
<path d="M 232 300 q 0 -14 24 -14 q 24 0 24 14 l 0 70 q 0 24 -24 24 q -24 0 -24 -24 z" fill="url(#tongue)" stroke="#9e2447" stroke-width="6"/>
<path d="M 256 296 l 0 80" stroke="#b02a52" stroke-width="4" opacity="0.5"/>
"""
parts["aura"] = f"""
<circle cx="256" cy="280" r="230" fill="#ffe27a" opacity="0.25" filter="url(#blur10)"/>
<circle cx="256" cy="280" r="170" fill="#fff6c0" opacity="0.25" filter="url(#blur10)"/>
"""

def star(cx, cy, r, fill="url(#gold)", stroke="#a8620a", sw=4):
    import math
    pts=[]
    for i in range(10):
        a = -math.pi/2 + i*math.pi/5
        rr = r if i%2==0 else r*0.45
        pts.append(f"{cx+rr*math.cos(a):.1f},{cy+rr*math.sin(a):.1f}")
    return f'<polygon points="{" ".join(pts)}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round"/>'

# ---- costumes ----
costumes = {}
# royal
costumes["royal"] = {
 "back": f'<path d="M 120 330 Q 256 470 392 330 L 420 470 Q 256 520 92 470 Z" fill="url(#red)" stroke="#7a1226" stroke-width="7"/>',
 "body": f"""<path d="M 120 318 Q 256 392 392 318 Q 396 352 360 372 Q 256 408 152 372 Q 116 352 120 318 Z" fill="#fff" stroke="#bcc3d6" stroke-width="5"/>
{''.join(f'<ellipse cx="{x}" cy="{y}" rx="5" ry="9" fill="#222" transform="rotate({r} {x} {y})"/>' for x,y,r in [(160,348,-20),(200,370,-8),(256,382,0),(312,370,8),(352,348,20)])}""",
 "head": f"""<path d="M 176 118 L 160 40 L 212 84 L 256 22 L 300 84 L 352 40 L 336 118 Q 256 140 176 118 Z" fill="url(#gold)" stroke="#a8620a" stroke-width="7" stroke-linejoin="round"/>
<circle cx="256" cy="86" r="14" fill="#ff3a5e" stroke="#7a1226" stroke-width="4"/><circle cx="208" cy="104" r="8" fill="#3d8bff" stroke="#123a8a" stroke-width="3"/><circle cx="304" cy="104" r="8" fill="#3fd96a" stroke="#0f6a2a" stroke-width="3"/>
{star(160,38,9)} {star(352,38,9)} {star(256,18,10)}"""}
# wizard
costumes["wizard"] = {
 "back": "",
 "body": f"""<path d="M 140 330 Q 256 410 372 330 L 392 420 Q 256 470 120 420 Z" fill="url(#purple)" stroke="#2a1470" stroke-width="7"/>
{star(190,392,16,'#ffe27a','#a8620a',3)}{star(320,404,12,'#ffe27a','#a8620a',3)}{star(256,372,10,'#fff','#a8a8c8',3)}""",
 "head": f"""<ellipse cx="256" cy="108" rx="196" ry="38" fill="url(#purple)" stroke="#2a1470" stroke-width="8"/>
<path d="M 160 100 Q 190 20 262 -30 Q 258 20 336 100 Q 256 128 160 100 Z" fill="url(#purple)" stroke="#2a1470" stroke-width="8" stroke-linejoin="round"/>
<path d="M 166 98 Q 256 130 332 98 L 338 112 Q 256 144 160 112 Z" fill="#ffcf3a" stroke="#a8620a" stroke-width="4"/>
{star(240,48,16)} <circle cx="288" cy="62" r="5" fill="#ffe27a"/><circle cx="214" cy="80" r="4" fill="#ffe27a"/>"""}
# ninja
costumes["ninja"] = {
 "back": f"""<path d="M 140 300 L 40 250 L 60 300 L 24 330 L 118 350 Z" fill="url(#dark)" stroke="#0c0e18" stroke-width="5" opacity="0"/>""",
 "body": f"""<path d="M 110 326 Q 256 420 402 326 L 410 352 Q 256 452 102 352 Z" fill="url(#dark)" stroke="#0c0e18" stroke-width="6"/>
<polygon points="256,372 270,398 298,404 276,422 282,450 256,436 230,450 236,422 214,404 242,398" fill="#d8dcea" stroke="#5a6078" stroke-width="3"/>""",
 "head": f"""<g transform="translate(0,-64)"><path d="M 70 196 Q 256 140 442 196 L 442 236 Q 256 184 70 236 Z" fill="url(#red)" stroke="#7a1226" stroke-width="7"/>
<rect x="216" y="168" width="80" height="48" rx="10" fill="#c9cfe0" stroke="#4a5068" stroke-width="5" transform="rotate(-3 256 192)"/>
{star(256,192,15,'#6a7088','#2a2f48',3)}
<path d="M 442 206 Q 488 190 500 150 Q 470 168 440 176 Z" fill="url(#red)" stroke="#7a1226" stroke-width="5"/>
<path d="M 442 214 Q 492 224 504 262 Q 470 244 440 232 Z" fill="url(#red)" stroke="#7a1226" stroke-width="5"/>
<path d="M 130 118 Q 150 96 190 92 M 382 118 Q 362 96 322 92" fill="none" stroke="#17331f" stroke-width="10" stroke-linecap="round" opacity="0.0"/></g>"""}
# pirate
costumes["pirate"] = {
 "back": "",
 "body": f"""<path d="M 130 336 Q 256 410 382 336 L 396 380 Q 256 450 116 380 Z" fill="#f4f0e6" stroke="#8a7a58" stroke-width="5"/>
<path d="M 130 336 Q 256 410 382 336 L 388 352 Q 256 428 124 352 Z" fill="url(#red)" stroke="#7a1226" stroke-width="5"/>
{''.join(f'<path d="M {x} 370 l 14 14 M {x+14} 370 l -14 14" stroke="#7a1226" stroke-width="4"/>' for x in (180, 240, 300))}""",
 "head": f"""<path d="M 76 108 Q 256 -34 436 108 Q 420 142 256 124 Q 92 142 76 108 Z" fill="url(#dark)" stroke="#0c0e18" stroke-width="8" stroke-linejoin="round"/>
<path d="M 76 108 Q 256 150 436 108 L 436 120 Q 256 164 76 120 Z" fill="#ffcf3a" stroke="#a8620a" stroke-width="4"/>
<ellipse cx="256" cy="66" rx="30" ry="26" fill="#f4f0e6" stroke="#8a8a9a" stroke-width="4"/>
<circle cx="244" cy="62" r="7" fill="#222"/><circle cx="268" cy="62" r="7" fill="#222"/><path d="M 256 70 l -5 12 h 10 z" fill="#222"/>
<path d="M 232 94 l 48 -22 M 280 94 l -48 -22" stroke="#f4f0e6" stroke-width="6" stroke-linecap="round" opacity="0"/>
<path d="M 122 128 L 372 176" stroke="#111" stroke-width="8" stroke-linecap="round"/>
<ellipse cx="190" cy="152" rx="54" ry="48" fill="#15151f" stroke="#000" stroke-width="5" transform="rotate(-10 190 152)"/>
<ellipse cx="186" cy="142" rx="22" ry="10" fill="#fff" opacity="0.14" transform="rotate(-10 186 142)"/>
<circle cx="80" cy="288" r="16" fill="none" stroke="url(#gold)" stroke-width="7"/>"""}
# galaxy
costumes["galaxy"] = {
 "back": f"""<ellipse cx="256" cy="300" rx="236" ry="226" fill="#6a35d8" opacity="0.22" filter="url(#blur10)"/>""",
 "body": f"""<path d="M 124 328 Q 256 400 388 328 Q 410 392 360 430 Q 256 470 152 430 Q 102 392 124 328 Z" fill="url(#cosmic)" stroke="#1a0f55" stroke-width="7"/>
{star(190,386,10,'#fff','#bcd',2)}{star(300,410,8,'#fff','#bcd',2)}{star(256,372,6,'#ffe27a','#a8620a',2)}{star(334,372,7,'#fff','#bcd',2)}{star(176,420,6,'#8ae8ff','#2a6a9a',2)}""",
 "head": f"""<circle cx="256" cy="215" r="236" fill="url(#glass)" stroke="#bfe8ff" stroke-width="7" opacity="0.95"/>
<path d="M 100 130 Q 150 40 270 28" fill="none" stroke="#fff" stroke-width="12" stroke-linecap="round" opacity="0.55"/>
<path d="M 256 -20 L 256 -52" stroke="#bfe8ff" stroke-width="7"/>{star(256,-62,20,'url(#gold)','#a8620a',4)}
<circle cx="120" cy="40" r="4" fill="#fff"/><circle cx="410" cy="60" r="3" fill="#fff"/><circle cx="440" cy="340" r="4" fill="#8ae8ff"/>"""}

# ---- extra visuals ----
parts["pad_back"] = f"""<ellipse cx="256" cy="440" rx="240" ry="70" fill="#1f7a3a" stroke="#14532a" stroke-width="8"/>
<ellipse cx="256" cy="430" rx="226" ry="58" fill="#34b457"/>
<path d="M 256 430 L 470 392 A 226 58 0 0 1 482 430 Z" fill="#000" opacity="0"/>
<ellipse cx="256" cy="426" rx="150" ry="34" fill="#4fd673" opacity="0.5"/>"""

def render(name, body):
    p = os.path.join(SVGDIR, name + ".svg")
    open(p, "w").write(svg(body))
    out = os.path.join(OUT, name + ".png")
    subprocess.run(["rsvg-convert", "-w", str(W), "-h", str(H), p, "-o", out], check=True)

for n, b in parts.items():
    render("frog_" + n, b)
for cn, d in costumes.items():
    for layer in ("back", "body", "head"):
        render(f"costume_{cn}_{layer}", d[layer] or "")
print("frog parts:", len(parts), "costumes:", len(costumes))
