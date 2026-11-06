#!/bin/bash
# usage: tools/shot.sh out.png frames [godot user args...]   (renders offscreen via movie maker, 540x960 default)
OUT=$1; FR=$2; shift 2
RES=${RES:-540x960}
G=/Applications/Godot.app/Contents/MacOS/Godot
cd "$(dirname "$0")/.."
source tools/lib_res.sh
rm -f build/_shot.avi
set_res $RES
$G --path . --write-movie build/_shot.avi --fixed-fps 30 --resolution $RES --quit-after $FR -- --fresh-save "$@" >/dev/null 2>&1
clear_res
ffmpeg -y -loglevel error -sseof -0.2 -i build/_shot.avi -frames:v 1 -update 1 "$OUT"
