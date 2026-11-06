#!/bin/bash
# usage: tools/clip.sh name seconds fps WxH [director args...]  -> build/clips/name.avi
NAME=$1; SEC=$2; FPS=$3; RES=$4; shift 4
cd "$(dirname "$0")/.."
source tools/lib_res.sh
mkdir -p build/clips
FR=$(python3 -c "print(int($SEC*$FPS))")
set_res $RES
/Applications/Godot.app/Contents/MacOS/Godot --path . res://tools/trailer_director.tscn --write-movie build/clips/$NAME.avi --fixed-fps $FPS --resolution $RES --quit-after $FR -- --fresh-save "$@" >build/clips/$NAME.log 2>&1 </dev/null
clear_res
