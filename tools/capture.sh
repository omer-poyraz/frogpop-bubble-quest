#!/bin/bash
# usage: tools/capture.sh name frames fps res [godot user args...]  -> build/cap/name.avi
NAME=$1; FR=$2; FPS=$3; RES=$4; shift 4
cd "$(dirname "$0")/.."
mkdir -p build/cap
/Applications/Godot.app/Contents/MacOS/Godot --path . --write-movie build/cap/$NAME.avi --fixed-fps $FPS --resolution $RES --quit-after $FR -- "$@" >/dev/null 2>&1 </dev/null
