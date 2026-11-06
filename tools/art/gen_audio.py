import os, subprocess, wave
import numpy as np
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "assets", "audio"); TMP = os.path.join(ROOT, "build", "audio_tmp")
os.makedirs(OUT, exist_ok=True); os.makedirs(TMP, exist_ok=True)
SR = 44100
rng = np.random.default_rng(7)

def t_(d): return np.arange(int(SR * d)) / SR
def env(n, a=0.005, d=0.1, s=0.0, r=0.05):
    e = np.ones(n); na = max(int(a * SR), 1); nd = int(d * SR)
    e[:na] = np.linspace(0, 1, na)
    if nd > 0 and n > na:
        m = min(nd, n - na); e[na:na + m] = np.linspace(1, s, m); e[na + m:] = s
    nr = min(int(r * SR), n); e[n - nr:] *= np.linspace(1, 0, nr)
    return e
def expenv(n, k): return np.exp(-np.arange(n) / SR * k)
def sine(f, d, ph=0): return np.sin(2 * np.pi * np.cumsum(np.broadcast_to(f, (int(SR * d),))) / SR + ph) if np.ndim(f) else np.sin(2 * np.pi * f * t_(d) + ph)
def sweep(f0, f1, d, curve=1.0):
    n = int(SR * d); x = np.linspace(0, 1, n) ** curve
    f = f0 + (f1 - f0) * x
    return np.sin(2 * np.pi * np.cumsum(f) / SR)
def noise(d): return rng.uniform(-1, 1, int(SR * d))
def lp(x, a):  # one-pole lowpass
    y = np.zeros_like(x); acc = 0.0
    for i in range(len(x)):
        acc += a * (x[i] - acc); y[i] = acc
    return y
def lpf(x, cutoff):
    a = 1 - np.exp(-2 * np.pi * cutoff / SR)
    # vectorised via scipy-free approach: use FFT brickwall-ish smoothing
    X = np.fft.rfft(x); f = np.fft.rfftfreq(len(x), 1 / SR)
    X *= 1 / (1 + (f / cutoff) ** 4)
    return np.fft.irfft(X, len(x))
def norm(x, peak=0.9): m = np.max(np.abs(x)) + 1e-9; return x / m * peak
def save(name, x, music=False):
    x = np.clip(x, -1, 1)
    wavp = os.path.join(TMP, name + ".wav")
    with wave.open(wavp, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x * 32767).astype(np.int16).tobytes())
    if music:
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wavp, "-ar", "32000", "-ac", "2", "-c:a", "vorbis", "-strict", "-2", "-b:a", "96k", os.path.join(OUT, name + ".ogg")], check=True)
    else:
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wavp, "-ar", "32000", "-ac", "2", "-c:a", "vorbis", "-strict", "-2", "-b:a", "96k", os.path.join(OUT, name + ".ogg")], check=True)

def mix(*parts):
    n = max(len(p) for p in parts); out = np.zeros(n)
    for p in parts: out[:len(p)] += p
    return out
def delay(x, ms, gain): d = int(SR * ms / 1000); y = np.zeros(len(x) + d); y[:len(x)] += x; y[d:] += x * gain; return y

# ---------------- SFX ----------------
def sfx_shoot():
    n = int(SR * 0.16); a = sweep(720, 240, 0.16, 0.6) * expenv(n, 18)
    b = noise(0.16) * expenv(n, 60) * 0.25
    return norm(a + b + sweep(1400, 500, 0.16) * expenv(n, 30) * 0.2, 0.8)
def sfx_collide():
    n = int(SR * 0.14); return norm(sweep(380, 170, 0.14) * expenv(n, 26) + 0.3 * sweep(760, 300, 0.14) * expenv(n, 40), 0.8)
def sfx_pop():
    n = int(SR * 0.22)
    a = sweep(1100, 260, 0.22, 0.4) * expenv(n, 20)
    b = lpf(noise(0.22), 4500) * expenv(n, 38) * 0.6
    c = sweep(2300, 900, 0.22) * expenv(n, 50) * 0.3
    return norm(a + b + c, 0.9)
def chime(freqs, d=0.5, k=7, gap=0.07, harm=True):
    out = np.zeros(int(SR * (d + gap * len(freqs))))
    for i, f in enumerate(freqs):
        n = int(SR * d); tone = np.sin(2 * np.pi * f * t_(d)) + (0.35 * np.sin(2 * np.pi * 2 * f * t_(d)) + 0.15 * np.sin(2 * np.pi * 3.01 * f * t_(d)) if harm else 0)
        tone *= expenv(n, k) * env(n, 0.002, 0, 1, 0.02)
        s = int(i * gap * SR); out[s:s + n] += tone
    return out
def midi(m): return 440 * 2 ** ((m - 69) / 12)
def sfx_chain(): return norm(delay(chime([midi(m) for m in (72, 76, 79, 84, 88)], 0.35, 8, 0.055), 120, 0.3), 0.85)
def sfx_combo(): return norm(delay(chime([midi(m) for m in (76, 83, 88)], 0.45, 6, 0.09), 150, 0.35), 0.9)
def sfx_power():
    n = int(SR * 0.7); a = sweep(300, 1600, 0.7, 1.5) * env(n, 0.01, 0.4, 0.4, 0.2)
    sh = chime([midi(m) for m in (84, 88, 91)], 0.4, 6, 0.06) ; s = np.zeros(n + len(sh)); s[:n] += a * 0.5; s[int(0.25 * SR):int(0.25 * SR) + len(sh)] += sh * 0.7
    return norm(s, 0.85)
def sfx_click(): n = int(SR * 0.05); return norm(sweep(1500, 900, 0.05) * expenv(n, 70) + 0.2 * noise(0.05) * expenv(n, 200), 0.7)
def sfx_gameover():
    notes = [midi(m) for m in (67, 64, 60, 55)]; out = np.zeros(int(SR * 1.8))
    for i, f in enumerate(notes):
        n = int(SR * 0.6); tone = (np.sin(2 * np.pi * f * t_(0.6)) + 0.4 * np.sin(2 * np.pi * 2 * f * t_(0.6))) * expenv(n, 4) * env(n, 0.01, 0, 1, 0.1)
        s = int(i * 0.28 * SR); out[s:s + n] += tone
    return norm(out, 0.85)
def sfx_record():
    notes = [(72, 0), (76, 0.12), (79, 0.24), (84, 0.36), (79, 0.6), (84, 0.72), (88, 0.84)]; out = np.zeros(int(SR * 1.8))
    for m, st in notes:
        f = midi(m); n = int(SR * 0.5); tone = (np.sin(2 * np.pi * f * t_(0.5)) + 0.5 * np.sin(2 * np.pi * 2 * f * t_(0.5)) + 0.25 * np.sin(2 * np.pi * 3 * f * t_(0.5))) * expenv(n, 5) * env(n, 0.004, 0, 1, 0.1)
        s = int(st * SR); out[s:s + n] += tone
    return norm(delay(out, 160, 0.3), 0.9)
def sfx_world():
    n = int(SR * 1.2); a = lpf(noise(1.2), 2500) * env(n, 0.5, 0.2, 0.3, 0.4) * 0.5
    b = sweep(200, 1200, 1.2, 2.0) * env(n, 0.3, 0.3, 0.4, 0.4) * 0.4
    c = chime([midi(m) for m in (72, 79, 84)], 0.7, 4, 0.12)
    s = np.zeros(n + 2000); s[:n] += a + b; s[int(0.5 * SR):int(0.5 * SR) + len(c)] += c[:len(s) - int(0.5 * SR)] * 0.8
    return norm(s, 0.85)
def sfx_bomb():
    n = int(SR * 0.7); a = lpf(noise(0.7), 900) * expenv(n, 6); b = sweep(120, 35, 0.7, 0.5) * expenv(n, 5)
    return norm(a * 0.9 + b * 1.1 + lpf(noise(0.7), 6000) * expenv(n, 30) * 0.4, 0.95)
def sfx_lightning():
    n = int(SR * 0.6); crack = noise(0.6) * (rng.random(n) > 0.3) * expenv(n, 14)
    return norm(lpf(crack, 7000) * 0.8 + sweep(2400, 200, 0.6, 0.3) * expenv(n, 9) * 0.5 + lpf(noise(0.6), 700) * expenv(n, 5) * 0.6, 0.9)
def sfx_coin(): return norm(chime([midi(m) for m in (83, 88)], 0.35, 9, 0.07), 0.8)
def sfx_slow():
    n = int(SR * 0.8); return norm(sweep(900, 120, 0.8, 0.6) * env(n, 0.02, 0.5, 0.3, 0.2) * 0.8 + sweep(1800, 240, 0.8, 0.6) * 0.2 * env(n, 0.02, 0.5, 0.3, 0.2), 0.8)
def sfx_shield():
    n = int(SR * 0.9); return norm(chime([midi(m) for m in (67, 74, 79)], 0.8, 3, 0.1) * 0.8 + lpf(noise(0.9), 3000)[:n].mean() * 0, 0.8)
def sfx_rewind():
    n = int(SR * 0.9); x = sweep(150, 1400, 0.9, 2.0); x = x[::-1] if False else x
    return norm(x * env(n, 0.02, 0.3, 0.6, 0.2) * 0.8 + sweep(300, 2800, 0.9, 2.0) * 0.25 * env(n, 0.02, 0.3, 0.6, 0.2), 0.85)
def sfx_switch(): n = int(SR * 0.3); return norm(sweep(500, 1500, 0.3) * env(n, 0.005, 0.1, 0.5, 0.1) + sweep(1500, 500, 0.3) * 0.5 * env(n, 0.005, 0.1, 0.5, 0.1), 0.8)
def sfx_rainbow():
    return norm(delay(chime([midi(m) for m in (72, 74, 76, 79, 81, 84, 88)], 0.4, 6, 0.05), 100, 0.35), 0.9)
def sfx_warn(): n = int(SR * 0.4); return norm((np.sin(2 * np.pi * 440 * t_(0.4)) * (np.sin(2 * np.pi * 8 * t_(0.4)) > 0)) * env(n, 0.005, 0, 1, 0.05), 0.5)
def sfx_swap(): n = int(SR * 0.09); return norm(sweep(600, 1100, 0.09) * expenv(n, 30), 0.6)
def sfx_whoosh(): n = int(SR * 0.4); return norm(lpf(noise(0.4), 2500) * env(n, 0.15, 0.1, 0.5, 0.15), 0.6)
def sfx_win():
    notes = [(60, 0), (64, 0.1), (67, 0.2), (72, 0.3), (76, 0.5)]; out = np.zeros(int(SR * 1.6))
    for m, st in notes:
        f = midi(m); n = int(SR * 0.6); tone = (np.sin(2 * np.pi * f * t_(0.6)) + 0.3 * np.sin(4 * np.pi * f * t_(0.6))) * expenv(n, 4) * env(n, 0.004, 0, 1, 0.1)
        s = int(st * SR); out[s:s + n] += tone
    return norm(delay(out, 140, 0.25), 0.85)

sfx = {"shoot": sfx_shoot, "collide": sfx_collide, "pop": sfx_pop, "chain": sfx_chain, "combo": sfx_combo, "power": sfx_power, "click": sfx_click,
       "gameover": sfx_gameover, "record": sfx_record, "world": sfx_world, "bomb": sfx_bomb, "lightning": sfx_lightning, "coin": sfx_coin,
       "slow": sfx_slow, "shield": sfx_shield, "rewind": sfx_rewind, "switch": sfx_switch, "rainbow": sfx_rainbow, "warn": sfx_warn, "swap": sfx_swap,
       "whoosh": sfx_whoosh, "win": sfx_win}
for k, fn in sfx.items():
    save("sfx_" + k, fn())

# ---------------- Music ----------------
SCALES = {"major": [0, 2, 4, 5, 7, 9, 11], "minor": [0, 2, 3, 5, 7, 8, 10], "pent": [0, 2, 4, 7, 9], "dorian": [0, 2, 3, 5, 7, 9, 10], "lydian": [0, 2, 4, 6, 7, 9, 11], "phryg": [0, 1, 3, 5, 7, 8, 10], "mixo": [0, 2, 4, 5, 7, 9, 10]}
def note_tone(f, d, kind, vel=1.0):
    n = int(SR * d); t = np.arange(n) / SR
    if kind == "pluck":
        x = np.sin(2 * np.pi * f * t) + 0.5 * np.sin(4 * np.pi * f * t) * np.exp(-t * 14) + 0.25 * np.sin(6 * np.pi * f * t) * np.exp(-t * 20); e = np.exp(-t * 7)
    elif kind == "bell":
        x = np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 2.76 * t) * np.exp(-t * 6) + 0.3 * np.sin(2 * np.pi * f * 5.4 * t) * np.exp(-t * 10); e = np.exp(-t * 4)
    elif kind == "pad":
        x = sum(np.sin(2 * np.pi * f * (1 + dt) * t) for dt in (-0.004, 0, 0.004)) / 3 + 0.3 * np.sin(4 * np.pi * f * t); e = np.minimum(t / 0.3, 1) * np.exp(-t * 0.7)
    elif kind == "bass":
        x = np.sin(2 * np.pi * f * t) + 0.3 * np.sin(4 * np.pi * f * t); e = np.exp(-t * 5)
    elif kind == "marimba":
        x = np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 4 * t) * np.exp(-t * 20); e = np.exp(-t * 9)
    else:
        x = np.sin(2 * np.pi * f * t); e = np.exp(-t * 6)
    a = np.minimum(t / 0.004, 1)
    return x * e * a * vel
def render_track(bpm, root, scale, prog, lead, bass_kind, bars, seed, swing=0.0, density=0.6, perc=True, pad=True):
    r = np.random.default_rng(seed)
    beat = 60.0 / bpm; bar = beat * 4; total = bars * bar
    tail = 2.0; buf = np.zeros(int((total + tail) * SR))
    sc = SCALES[scale]
    def deg(d, oct_=0):
        o, i = divmod(d, len(sc)); return root + sc[i] + 12 * (o + oct_)
    def put(x, t0):
        s = int(t0 * SR); e = min(s + len(x), len(buf)); buf[s:e] += x[:e - s]
    for b in range(bars):
        chord_root = prog[b % len(prog)]
        t0 = b * bar
        if pad:
            for k in (0, 2, 4):
                put(note_tone(midi(deg(chord_root + k, 0) + 12), bar * 1.5, "pad", 0.10), t0)
        put(note_tone(midi(deg(chord_root, -2)), beat * 1.8, bass_kind, 0.45), t0)
        put(note_tone(midi(deg(chord_root + 4, -2)), beat * 1.5, bass_kind, 0.3), t0 + beat * 2.5)
        for s in range(8):
            tt = t0 + s * beat / 2 + (swing * beat / 2 if s % 2 else 0)
            if r.random() < density:
                step = int(r.integers(-2, 4)); 
                cd = chord_root + [0, 2, 4, 7, 9, 11][int(r.integers(0, 6))]
                put(note_tone(midi(deg(cd, 1)), beat * 1.2, lead, 0.20), tt)
        if perc:
            for q in range(4):
                tq = t0 + q * beat
                kick = sweep(110, 45, 0.18, 0.4) * np.exp(-np.arange(int(SR * 0.18)) / SR * 16) * 0.5
                if q % 2 == 0: put(kick, tq)
                hat = lpf(noise(0.05), 9000) * np.exp(-np.arange(int(SR * 0.05)) / SR * 70) * 0.10
                put(hat, tq + beat / 2); 
                if q % 2 == 1: put(lpf(noise(0.12), 3500) * np.exp(-np.arange(int(SR * 0.12)) / SR * 28) * 0.18, tq)
    # fold tail to loop seamlessly
    n_loop = int(total * SR); out = buf[:n_loop].copy(); tl = buf[n_loop:]; out[:len(tl)] += tl
    out = delay(out, 260, 0.22)[:n_loop] + 0  # tiny echo, truncated (tail dropped; negligible)
    return norm(out, 0.7)
THEMES = [
 dict(bpm=104, root=57, scale="major", prog=[0, 4, 5, 3], lead="pluck", bass_kind="bass", seed=1, swing=0.1),       # forest
 dict(bpm=118, root=60, scale="lydian", prog=[0, 3, 4, 1], lead="bell", bass_kind="marimba", seed=2, swing=0.2),    # candy
 dict(bpm=96, root=55, scale="pent", prog=[0, 2, 3, 0], lead="marimba", bass_kind="bass", seed=3, swing=0.0),       # ocean
 dict(bpm=88, root=59, scale="minor", prog=[0, 5, 3, 4], lead="bell", bass_kind="bass", seed=4, swing=0.0, density=0.45),  # ice
 dict(bpm=122, root=52, scale="phryg", prog=[0, 1, 0, 6], lead="pluck", bass_kind="bass", seed=5, swing=0.0, density=0.7), # volcano
 dict(bpm=92, root=62, scale="dorian", prog=[0, 3, 6, 4], lead="bell", bass_kind="marimba", seed=6, swing=0.0, density=0.5), # crystal
 dict(bpm=108, root=50, scale="minor", prog=[0, 6, 5, 6], lead="marimba", bass_kind="bass", seed=7, swing=0.05),     # temple
 dict(bpm=112, root=58, scale="mixo", prog=[0, 3, 0, 4], lead="pluck", bass_kind="marimba", seed=8, swing=0.15),    # mushroom
 dict(bpm=100, root=53, scale="phryg", prog=[0, 6, 3, 0], lead="marimba", bass_kind="bass", seed=9, swing=0.0),     # desert
 dict(bpm=84, root=64, scale="lydian", prog=[0, 4, 1, 3], lead="bell", bass_kind="bass", seed=10, swing=0.0, density=0.4)]  # galaxy
for i, p in enumerate(THEMES):
    p = dict(p); p["bars"] = 8
    save(f"theme_{i}", render_track(**p), music=True)
# menu music
save("music_menu", render_track(bpm=96, root=60, scale="major", prog=[0, 5, 3, 4], lead="bell", bass_kind="marimba", bars=8, seed=21, swing=0.1, density=0.55, perc=False), music=True)
print("audio done")
