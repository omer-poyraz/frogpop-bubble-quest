import os, subprocess, math
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "assets", "ui"); SV = os.path.join(ROOT, "build", "svg_ui")
os.makedirs(OUT, exist_ok=True); os.makedirs(SV, exist_ok=True)
W = '#ffffff'; D = '#2a3550'
def star(cx, cy, r, fill, stroke, sw=3):
    pts = []
    for i in range(10):
        a = -math.pi/2 + i*math.pi/5; rr = r if i % 2 == 0 else r*0.47
        pts.append(f"{cx+rr*math.cos(a):.1f},{cy+rr*math.sin(a):.1f}")
    return f'<polygon points="{" ".join(pts)}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round"/>'
GR = '<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff3a6"/><stop offset="0.5" stop-color="#ffcf3a"/><stop offset="1" stop-color="#d98a12"/></linearGradient><linearGradient id="b" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9fd4ff"/><stop offset="1" stop-color="#3d8bff"/></linearGradient><linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ff8a8a"/><stop offset="1" stop-color="#e0334e"/></linearGradient><linearGradient id="y" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff59a"/><stop offset="1" stop-color="#ffb020"/></linearGradient><linearGradient id="p" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#d6a8ff"/><stop offset="1" stop-color="#7a3fe0"/></linearGradient><linearGradient id="gn" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#a6f77c"/><stop offset="1" stop-color="#2fb24f"/></linearGradient></defs>'
icons = {
 "pause": f'<rect x="34" y="28" width="20" height="72" rx="8" fill="{W}"/><rect x="74" y="28" width="20" height="72" rx="8" fill="{W}"/>',
 "play": f'<path d="M 42 26 L 100 64 L 42 102 Z" fill="{W}" stroke="{W}" stroke-width="10" stroke-linejoin="round"/>',
 "gear": f'<g fill="{W}"><circle cx="64" cy="64" r="30"/>' + ''.join(f'<rect x="56" y="10" width="16" height="24" rx="5" transform="rotate({a} 64 64)"/>' for a in range(0,360,45)) + f'</g><circle cx="64" cy="64" r="14" fill="{D}"/>',
 "coin": f'{GR}<circle cx="64" cy="64" r="48" fill="url(#g)" stroke="#a8620a" stroke-width="7"/><circle cx="64" cy="64" r="34" fill="none" stroke="#fff3a6" stroke-width="5" opacity="0.8"/><path d="M 64 40 L 64 88 M 50 52 Q 64 40 78 52 Q 50 64 78 76 Q 64 90 50 76" fill="none" stroke="#a8620a" stroke-width="7" stroke-linecap="round" opacity="0.75"/>',
 "crown": f'{GR}<path d="M 18 94 L 12 38 L 44 62 L 64 24 L 84 62 L 116 38 L 110 94 Z" fill="url(#g)" stroke="#a8620a" stroke-width="7" stroke-linejoin="round"/><rect x="18" y="94" width="92" height="14" rx="6" fill="url(#g)" stroke="#a8620a" stroke-width="6"/><circle cx="64" cy="70" r="8" fill="#ff3a5e"/>',
 "star": f'{GR}' + star(64, 66, 54, "url(#g)", "#a8620a", 6),
 "star_empty": star(64, 66, 54, "#3a4566", "#7f8bb0", 6),
 "lock": f'<rect x="26" y="54" width="76" height="58" rx="14" fill="{W}"/><path d="M 40 54 L 40 40 Q 40 18 64 18 Q 88 18 88 40 L 88 54" fill="none" stroke="{W}" stroke-width="12" stroke-linecap="round"/><circle cx="64" cy="82" r="9" fill="{D}"/>',
 "check": f'<path d="M 24 68 L 52 94 L 104 36" fill="none" stroke="{W}" stroke-width="16" stroke-linecap="round" stroke-linejoin="round"/>',
 "close": f'<path d="M 30 30 L 98 98 M 98 30 L 30 98" stroke="{W}" stroke-width="16" stroke-linecap="round"/>',
 "back": f'<path d="M 82 24 L 38 64 L 82 104" fill="none" stroke="{W}" stroke-width="16" stroke-linecap="round" stroke-linejoin="round"/>',
 "home": f'<path d="M 14 62 L 64 18 L 114 62" fill="none" stroke="{W}" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/><path d="M 28 58 L 28 110 L 52 110 L 52 78 L 76 78 L 76 110 L 100 110 L 100 58 L 64 28 Z" fill="{W}"/>',
 "replay": f'<path d="M 100 64 A 36 36 0 1 1 82 33" fill="none" stroke="{W}" stroke-width="14" stroke-linecap="round"/><path d="M 76 12 L 100 36 L 66 44 Z" fill="{W}" stroke="{W}" stroke-width="4" stroke-linejoin="round"/>',
 "gift": f'<rect x="20" y="52" width="88" height="58" rx="8" fill="{W}"/><rect x="14" y="38" width="100" height="24" rx="8" fill="{W}"/><rect x="56" y="38" width="16" height="72" fill="#ff5a7a"/><path d="M 64 38 Q 40 6 30 24 Q 26 38 64 38 Q 102 38 98 24 Q 88 6 64 38" fill="none" stroke="#ff5a7a" stroke-width="9" stroke-linejoin="round"/>',
 "shop": f'<path d="M 24 44 L 104 44 L 98 112 L 30 112 Z" fill="{W}"/><path d="M 44 54 L 44 36 Q 44 16 64 16 Q 84 16 84 36 L 84 54" fill="none" stroke="{W}" stroke-width="10" stroke-linecap="round"/><circle cx="52" cy="74" r="6" fill="{D}"/><circle cx="76" cy="74" r="6" fill="{D}"/>',
 "trophy": f'{GR}<path d="M 34 18 L 94 18 L 90 64 Q 84 86 64 88 Q 44 86 38 64 Z" fill="url(#g)" stroke="#a8620a" stroke-width="6" stroke-linejoin="round"/><path d="M 34 28 Q 8 28 14 52 Q 20 66 40 64 M 94 28 Q 120 28 114 52 Q 108 66 88 64" fill="none" stroke="#d98a12" stroke-width="8" stroke-linecap="round"/><rect x="54" y="86" width="20" height="18" fill="#d98a12"/><rect x="36" y="102" width="56" height="12" rx="5" fill="url(#g)" stroke="#a8620a" stroke-width="5"/>',
 "sound": f'<path d="M 20 48 L 44 48 L 74 22 L 74 106 L 44 80 L 20 80 Z" fill="{W}" stroke="{W}" stroke-width="6" stroke-linejoin="round"/><path d="M 92 44 Q 106 64 92 84 M 104 30 Q 126 64 104 98" fill="none" stroke="{W}" stroke-width="9" stroke-linecap="round"/>',
 "mute": f'<path d="M 20 48 L 44 48 L 74 22 L 74 106 L 44 80 L 20 80 Z" fill="{W}" stroke="{W}" stroke-width="6" stroke-linejoin="round"/><path d="M 92 48 L 120 80 M 120 48 L 92 80" stroke="#ff7a8a" stroke-width="10" stroke-linecap="round"/>',
 "music": f'<path d="M 46 90 L 46 22 L 104 12 L 104 78" fill="none" stroke="{W}" stroke-width="11" stroke-linejoin="round"/><ellipse cx="34" cy="92" rx="18" ry="14" fill="{W}"/><ellipse cx="92" cy="80" rx="18" ry="14" fill="{W}"/><path d="M 46 40 L 104 30" stroke="{W}" stroke-width="10"/>',
 "vibrate": f'<rect x="42" y="14" width="44" height="100" rx="10" fill="{W}"/><rect x="50" y="26" width="28" height="64" rx="4" fill="{D}"/><path d="M 22 40 L 22 88 M 106 40 L 106 88 M 8 52 L 8 76 M 120 52 L 120 76" stroke="{W}" stroke-width="8" stroke-linecap="round"/>',
 "ad": f'<rect x="12" y="26" width="104" height="70" rx="12" fill="{W}"/><path d="M 52 44 L 84 61 L 52 78 Z" fill="{D}"/><rect x="34" y="104" width="60" height="10" rx="5" fill="{W}"/>',
 "info": f'<circle cx="64" cy="64" r="52" fill="{W}"/><rect x="57" y="54" width="14" height="40" rx="6" fill="{D}"/><circle cx="64" cy="38" r="8" fill="{D}"/>',
 "calendar": f'<rect x="16" y="24" width="96" height="88" rx="14" fill="{W}"/><rect x="16" y="24" width="96" height="26" rx="12" fill="#ff5a7a"/><rect x="34" y="10" width="12" height="26" rx="6" fill="{W}"/><rect x="82" y="10" width="12" height="26" rx="6" fill="{W}"/>' + ''.join(f'<circle cx="{40+i*24}" cy="{72+j*22}" r="6" fill="{D}"/>' for i in range(3) for j in range(2)),
 "chart": f'<rect x="20" y="64" width="22" height="48" rx="5" fill="{W}"/><rect x="53" y="36" width="22" height="76" rx="5" fill="{W}"/><rect x="86" y="14" width="22" height="98" rx="5" fill="{W}"/>',
 "frog": f'<ellipse cx="64" cy="80" rx="44" ry="32" fill="{W}"/><circle cx="38" cy="46" r="22" fill="{W}"/><circle cx="90" cy="46" r="22" fill="{W}"/><circle cx="40" cy="48" r="9" fill="{D}"/><circle cx="88" cy="48" r="9" fill="{D}"/><path d="M 40 86 Q 64 104 88 86" stroke="{D}" stroke-width="7" fill="none" stroke-linecap="round"/>',
 "globe": f'<circle cx="64" cy="64" r="48" fill="none" stroke="{W}" stroke-width="9"/><ellipse cx="64" cy="64" rx="22" ry="48" fill="none" stroke="{W}" stroke-width="8"/><path d="M 16 64 L 112 64 M 24 38 L 104 38 M 24 90 L 104 90" stroke="{W}" stroke-width="7"/>',
 "eye": f'<path d="M 10 64 Q 64 8 118 64 Q 64 120 10 64 Z" fill="{W}"/><circle cx="64" cy="64" r="20" fill="{D}"/><circle cx="58" cy="58" r="6" fill="{W}"/>',
 "heart": f'<path d="M 64 108 Q 10 70 14 42 Q 18 14 44 16 Q 58 18 64 34 Q 70 18 84 16 Q 110 14 114 42 Q 118 70 64 108 Z" fill="#ff5a7a" stroke="#b01a3a" stroke-width="6"/>',
 # power-ups (colourful)
 "p_rainbow": f'<path d="M 12 98 A 52 52 0 0 1 116 98" fill="none" stroke="#ff4a5e" stroke-width="13"/><path d="M 26 98 A 38 38 0 0 1 102 98" fill="none" stroke="#ffd23c" stroke-width="13"/><path d="M 40 98 A 24 24 0 0 1 88 98" fill="none" stroke="#3d8bff" stroke-width="13"/><circle cx="64" cy="100" r="6" fill="#fff"/>',
 "p_bomb": f'<circle cx="60" cy="74" r="40" fill="#2a2f45" stroke="#0c0e18" stroke-width="6"/><ellipse cx="46" cy="58" rx="12" ry="7" fill="#fff" opacity="0.6" transform="rotate(-35 46 58)"/><path d="M 78 38 Q 92 22 104 28" fill="none" stroke="#c9a06a" stroke-width="8" stroke-linecap="round"/><circle cx="108" cy="26" r="10" fill="#ffb020"/><circle cx="108" cy="26" r="5" fill="#fff6c0"/>',
 "p_slow": f'<circle cx="64" cy="68" r="48" fill="#bfe6ff" stroke="#3d8bff" stroke-width="9"/><path d="M 64 36 L 64 68 L 86 82" fill="none" stroke="#2a4a8a" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/><path d="M 40 10 L 88 10" stroke="#3d8bff" stroke-width="10" stroke-linecap="round"/>',
 "p_switch": f'<path d="M 24 46 L 86 46 L 86 28 L 116 56 L 86 84 L 86 66 L 24 66 Z" fill="#ffd23c" stroke="#a8620a" stroke-width="5" stroke-linejoin="round" transform="translate(0,-8)"/><path d="M 104 84 L 42 84 L 42 66 L 12 94 L 42 122 L 42 104 L 104 104 Z" fill="#27d6d0" stroke="#0a6a72" stroke-width="5" stroke-linejoin="round" transform="translate(0,-14)"/>',
 "p_lightning": f'<path d="M 74 8 L 28 70 L 58 70 L 46 120 L 100 52 L 68 52 Z" fill="#ffe14a" stroke="#c98a00" stroke-width="7" stroke-linejoin="round"/>',
 "p_shield": f'<path d="M 64 10 L 112 28 Q 112 82 64 118 Q 16 82 16 28 Z" fill="#3d8bff" stroke="#16397f" stroke-width="8" stroke-linejoin="round"/><path d="M 64 22 L 100 36 Q 100 76 64 104 Z" fill="#7fb6ff"/><path d="M 64 40 L 70 56 L 86 56 L 73 66 L 78 82 L 64 72 L 50 82 L 55 66 L 42 56 L 58 56 Z" fill="#fff"/>',
 "p_backward": f'<path d="M 60 24 L 14 64 L 60 104 L 60 82 L 112 82 L 112 46 L 60 46 Z" fill="#a65bff" stroke="#4a2aa8" stroke-width="7" stroke-linejoin="round"/>',
}
for name, body in icons.items():
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">{GR}{body}</svg>'
    p = os.path.join(SV, name + ".svg"); open(p, "w").write(svg)
    subprocess.run(["rsvg-convert", "-w", "128", "-h", "128", p, "-o", os.path.join(OUT, name + ".png")], check=True)
print("icons", len(icons))
