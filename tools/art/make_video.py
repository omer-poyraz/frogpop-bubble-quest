#!/usr/bin/env python3
"""usage: make_video.py out.mp4 music.wav fps W H music_gain clip.avi:dur [clip.avi:dur ...]
Crossfades (video xfade + audio acrossfade), mixes music under game SFX, normalises to -14 LUFS."""
import sys, subprocess
out, music, fps, W, H, gain = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]), float(sys.argv[6])
clips = [(a.rsplit(":", 1)[0], float(a.rsplit(":", 1)[1])) for a in sys.argv[7:]]
T = 0.30
n = len(clips)
inputs = []
for c, d in clips: inputs += ["-i", c]
inputs += ["-i", music]
f = []
for i, (c, d) in enumerate(clips):
    f.append(f"[{i}:v]trim=0:{d},setpts=PTS-STARTPTS,fps={fps},scale={W}:{H}:flags=lanczos,format=yuv420p[v{i}]")
    f.append(f"[{i}:a]atrim=0:{d},asetpts=PTS-STARTPTS,aresample=48000,aformat=channel_layouts=stereo[a{i}]")
vlast, alast = "v0", "a0"
acc = clips[0][1]
for i in range(1, n):
    off = acc - T
    f.append(f"[{vlast}][v{i}]xfade=transition=fade:duration={T}:offset={off:.3f}[xv{i}]")
    f.append(f"[{alast}][a{i}]acrossfade=d={T}[xa{i}]")
    vlast, alast = f"xv{i}", f"xa{i}"
    acc += clips[i][1] - T
total = acc
f.append(f"[{n}:a]atrim=0:{total:.3f},asetpts=PTS-STARTPTS,aresample=48000,aformat=channel_layouts=stereo,volume={gain},afade=t=in:d=0.2,afade=t=out:st={total-1.6:.3f}:d=1.6[mus]")
f.append(f"[{alast}]volume=1.4[sfx]")
f.append(f"[sfx][mus]amix=inputs=2:normalize=0:duration=first,loudnorm=I=-14:TP=-1.5:LRA=11[aout]")
cmd = ["ffmpeg", "-nostdin", "-y", "-loglevel", "error"] + inputs + ["-filter_complex", ";".join(f), "-map", f"[{vlast}]", "-map", "[aout]",
       "-c:v", "libx264", "-preset", "slow", "-crf", "17", "-pix_fmt", "yuv420p", "-r", str(fps), "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-movflags", "+faststart", "-t", f"{total:.3f}", out]
subprocess.run(cmd, check=True)
print("wrote", out, "%.1f s" % total)
