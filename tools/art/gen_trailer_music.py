import os, wave, subprocess
import numpy as np
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "build", "video_audio"); os.makedirs(OUT, exist_ok=True)
SR = 44100
rng = np.random.default_rng(11)
def midi(m): return 440 * 2 ** ((m - 69) / 12)
def lpf(x, cutoff):
    X = np.fft.rfft(x); f = np.fft.rfftfreq(len(x), 1 / SR); X *= 1 / (1 + (f / cutoff) ** 4); return np.fft.irfft(X, len(x))
def sweep(f0, f1, d, curve=1.0):
    n = int(SR * d); x = np.linspace(0, 1, n) ** curve; return np.sin(2 * np.pi * np.cumsum(f0 + (f1 - f0) * x) / SR)
def tone(f, d, kind, vel=1.0):
    n = int(SR * d); t = np.arange(n) / SR
    if kind == "pluck": x = np.sin(2*np.pi*f*t) + .5*np.sin(4*np.pi*f*t)*np.exp(-t*14) + .25*np.sin(6*np.pi*f*t)*np.exp(-t*20); e = np.exp(-t*8)
    elif kind == "bell": x = np.sin(2*np.pi*f*t) + .5*np.sin(2*np.pi*f*2.76*t)*np.exp(-t*6) + .3*np.sin(2*np.pi*f*5.4*t)*np.exp(-t*10); e = np.exp(-t*4)
    elif kind == "pad": x = sum(np.sin(2*np.pi*f*(1+dt)*t) for dt in (-.004, 0, .004))/3 + .3*np.sin(4*np.pi*f*t); e = np.minimum(t/.25, 1)*np.exp(-t*.6)
    elif kind == "bass": x = np.sin(2*np.pi*f*t) + .35*np.sin(4*np.pi*f*t) + .15*np.sin(6*np.pi*f*t); e = np.exp(-t*4.5)
    else: x = np.sin(2*np.pi*f*t); e = np.exp(-t*6)
    return x * e * np.minimum(t/.004, 1) * vel
BPM = 124; BEAT = 60 / BPM; BAR = BEAT * 4; BARS = 36
total = BARS * BAR; buf = np.zeros(int((total + 3) * SR))
def put(x, t0, g=1.0):
    s = int(t0 * SR); e = min(s + len(x), len(buf)); 
    if s < len(buf): buf[s:e] += x[:e - s] * g
ROOT_N = 57  # A
MIN = [0, 2, 3, 5, 7, 8, 10]
def deg(d, o=0): oc, i = divmod(d, 7); return ROOT_N + MIN[i] + 12 * (oc + o)
PROG = [0, 5, 3, 6]  # i VI iv VII-ish degrees
kick = sweep(150, 42, .2, .4) * np.exp(-np.arange(int(SR*.2))/SR*14) * .9
snare = (lpf(rng.uniform(-1, 1, int(SR*.18)), 5000) * np.exp(-np.arange(int(SR*.18))/SR*22) * .5 + np.sin(2*np.pi*190*np.arange(int(SR*.18))/SR) * np.exp(-np.arange(int(SR*.18))/SR*30) * .35)
hat = lpf(rng.uniform(-1, 1, int(SR*.05)), 9000) * np.exp(-np.arange(int(SR*.05))/SR*80) * .16
clap = lpf(rng.uniform(-1, 1, int(SR*.12)), 4000) * np.exp(-np.arange(int(SR*.12))/SR*30) * .4
sections = [(0, 4, "intro"), (4, 16, "main"), (16, 20, "break"), (20, 32, "main2"), (32, 36, "finale")]
def sec(b):
    for a, z, n in sections:
        if a <= b < z: return n
for b in range(BARS):
    s = sec(b); t0 = b * BAR; ch = PROG[b % 4]
    drums = s in ("main", "main2", "finale") or (s == "intro" and b >= 2)
    if s != "break":
        for q in range(4):
            tq = t0 + q * BEAT
            if drums or s == "intro": put(kick, tq, 1.0 if (q % 2 == 0 or s != "intro") else .0)
            if drums and q % 2 == 1: put(snare, tq, .9); put(clap, tq, .6)
            if drums:
                put(hat, tq + BEAT / 2, 1.0); 
                if s != "main" or b % 2: put(hat, tq + BEAT / 4, .6); put(hat, tq + 3 * BEAT / 4, .6)
    for k in (0, 2, 4): put(tone(midi(deg(ch + k, 0) + 12), BAR * 1.4, "pad", .11), t0)
    if s != "intro":
        for q in range(8):
            put(tone(midi(deg(ch, -2)), BEAT * .9, "bass", .5 if q % 2 == 0 else .35), t0 + q * BEAT / 2)
    # arpeggio / lead
    arp = [0, 2, 4, 7, 4, 2, 0, 2] if s in ("intro", "break") else [0, 4, 7, 9, 7, 4, 2, 4]
    for i in range(8 if s != "main" or b % 2 else 8):
        kind = "bell" if s in ("intro", "break") else "pluck"
        put(tone(midi(deg(ch + arp[i], 1)), BEAT * .7, kind, .22 if s != "finale" else .28), t0 + i * BEAT / 2)
    if s in ("main2", "finale"):
        mel = [4, 4, 5, 7, 7, 5, 4, 2]
        for i, m in enumerate(mel):
            put(tone(midi(deg(ch + m, 2)), BEAT * .95, "bell", .18), t0 + i * BEAT)
# riser before finale and final hit
n = int(SR * BAR); riser = (lpf(rng.uniform(-1, 1, n), 7000) * np.linspace(0, 1, n) ** 2 * .35 + sweep(200, 2400, BAR, 2.0) * np.linspace(0, 1, n) ** 2 * .2)
put(riser, 31 * BAR)
put(riser, 15 * BAR, .8)
put(sweep(140, 35, 1.2, .4) * np.exp(-np.arange(int(SR*1.2))/SR*3) * 1.0, 35.5 * BAR - .1)
out = buf[:int(total * SR)]
out = out / (np.max(np.abs(out)) + 1e-9) * .9
# echo
d = int(SR * .24); y = np.zeros(len(out) + d); y[:len(out)] += out; y[d:] += out * .18; out = y[:len(out)]
path = os.path.join(OUT, "trailer_music.wav")
with wave.open(path, "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((np.clip(out, -1, 1) * 32767).astype(np.int16).tobytes())
print("music", total, "s")
