#!/bin/bash
# Renders every promo clip from the game itself (Godot Movie Maker) and cuts the YouTube trailers / shorts.
# usage: tools/make_videos.sh [long|short] [en|tr]    (default: everything)
cd "$(dirname "$0")/.."
MODE=${1:-all}; LANGS=${2:-"en tr"}
mkdir -p build/clips store/video
PY=.venv-tools/bin/python
$PY tools/art/gen_trailer_music.py >/dev/null
for L in $LANGS; do
  if [ "$MODE" = all ] || [ "$MODE" = long ]; then
    R=1920x1080; F=60; P=""
    tools/clip.sh L_hook_$L 4.2 $F $R --clip=hook --lang=$L --wave=1 --seed=3 $P
    tools/clip.sh L_logo_$L 4.8 $F $R --clip=logo --lang=$L --skin=royal
    tools/clip.sh L_playA_$L 9.5 $F $R --clip=play --lang=$L --wave=3 --seed=5 --think=0.5 --skin=wizard --preroll=3
    tools/clip.sh L_playB_$L 8.5 $F $R --clip=play --lang=$L --wave=4 --seed=12 --think=0.45 --skin=ninja --preroll=3
    for w in 7 10 13 16 19 22 25 28; do
      tools/clip.sh L_w${w}_$L 2.4 $F $R --clip=worlds --lang=$L --wave=$w --seed=$((w+30)) --preroll=4 --skin=$(echo royal wizard ninja pirate galaxy | tr ' ' '\n' | sed -n "$(( (w % 5) + 1 ))p")
    done
    tools/clip.sh L_powers_$L 10.5 $F $R --clip=powers --lang=$L --wave=13 --seed=24 --skin=pirate --preroll=3 --demo=0.8:bomb,3.0:lightning,5.2:slow,7.4:rainbow,9.2:shield
    tools/clip.sh L_costumes_$L 6.3 $F $R --clip=costumes --lang=$L
    tools/clip.sh L_modes_$L 5.2 $F $R --clip=modes --lang=$L
    tools/clip.sh L_cta_$L 6.8 $F $R --clip=cta --lang=$L
    SPEC="L_hook_$L:4.2 L_logo_$L:4.8 L_playA_$L:9.5 L_playB_$L:8.5"
    for w in 7 10 13 16 19 22 25 28; do SPEC="$SPEC L_w${w}_$L:2.4"; done
    SPEC="$SPEC L_powers_$L:10.5 L_costumes_$L:6.3 L_modes_$L:5.2 L_cta_$L:6.8"
    ARGS=""; for s in $SPEC; do ARGS="$ARGS build/clips/${s%%:*}.avi:${s##*:}"; done
    $PY tools/art/make_video.py store/video/frogpop_trailer_16x9_$L.mp4 build/video_audio/trailer_music.wav 60 1920 1080 0.55 $ARGS
  fi
  if [ "$MODE" = all ] || [ "$MODE" = short ]; then
    R=1080x1920; F=60
    tools/clip.sh S_hook_$L 3.2 $F $R --clip=hook --portrait --lang=$L --wave=1 --seed=3
    tools/clip.sh S_play_$L 8.5 $F $R --clip=play --portrait --lang=$L --wave=4 --seed=12 --think=0.4 --skin=wizard --preroll=3
    for w in 7 13 28 10; do
      tools/clip.sh S_w${w}_$L 2.0 $F $R --clip=worlds --portrait --lang=$L --wave=$w --seed=$((w+30)) --preroll=4 --skin=$(echo royal wizard ninja pirate galaxy | tr ' ' '\n' | sed -n "$(( (w % 5) + 1 ))p")
    done
    tools/clip.sh S_powers_$L 7.2 $F $R --clip=powers --portrait --lang=$L --wave=13 --seed=24 --skin=pirate --preroll=3 --demo=0.7:bomb,2.4:lightning,4.0:slow,5.6:rainbow
    tools/clip.sh S_costumes_$L 6.3 $F $R --clip=costumes --portrait --lang=$L
    tools/clip.sh S_cta_$L 4.6 $F $R --clip=cta --portrait --lang=$L
    tools/clip.sh S_pre_$L 1.6 $F $R --clip=pre --portrait --lang=$L --wave=1 --seed=3
    SPEC="S_hook_$L:3.2 S_play_$L:8.5 S_w7_$L:2.0 S_w13_$L:2.0 S_w28_$L:2.0 S_w10_$L:2.0 S_powers_$L:7.2 S_costumes_$L:6.3 S_cta_$L:4.6 S_pre_$L:1.6"
    ARGS=""; for s in $SPEC; do ARGS="$ARGS build/clips/${s%%:*}.avi:${s##*:}"; done
    $PY tools/art/make_video.py store/video/frogpop_short_9x16_$L.mp4 build/video_audio/trailer_music.wav 60 1080 1920 0.6 $ARGS
  fi
done
