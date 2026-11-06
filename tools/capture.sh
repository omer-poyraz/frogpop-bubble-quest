#!/bin/bash
# usage: tools/capture.sh name frames fps res [godot user args...]  -> build/cap/name.avi
NAME=$1; FR=$2; FPS=$3; RES=$4; shift 4
cd "$(dirname "$0")/.."
source tools/lib_res.sh
mkdir -p build/cap
set_res $RES
/Applications/Godot.app/Contents/MacOS/Godot --path . --write-movie build/cap/$NAME.avi --fixed-fps $FPS --resolution $RES --quit-after $FR -- --fresh-save "$@" >/dev/null 2>&1 </dev/null
clear_res
