#!/bin/bash
# Real gameplay captures (Godot Movie Maker, 1080x1920, deterministic seeds) -> store/screenshots/{en,tr}
cd "$(dirname "$0")/.."
mkdir -p build/shots
for LANG in en tr; do
  i=0
  while read n w s sd think demo t; do
    i=$((i+1))
    tools/capture.sh sh_$n 620 30 1080x1920 --screen=game --mode=classic --autoplay --wave=$w --seed=$sd --lang=$LANG --skin=$s --bot-think=$think ${demo:+--demo=$demo}
    ffmpeg -nostdin -y -loglevel error -ss $t -i build/cap/sh_$n.avi -frames:v 1 build/shots/${LANG}_$i.png
  done <<LIST
1 1 royal 21 0.7 - 5
2 4 wizard 22 0.6 - 7.5
3 7 ninja 23 0.6 - 17.5
4 13 pirate 24 0.7 6:bomb,9:lightning,12:rainbow 5.5
LIST
  tools/capture.sh sh_shop 60 30 1080x1920 --screen=shop --lang=$LANG --skin=royal
  ffmpeg -nostdin -y -loglevel error -sseof -0.3 -i build/cap/sh_shop.avi -frames:v 1 build/shots/${LANG}_5.png
  tools/capture.sh sh_menu 90 30 1080x1920 --screen=menu --lang=$LANG --skin=wizard
  ffmpeg -nostdin -y -loglevel error -sseof -0.3 -i build/cap/sh_menu.avi -frames:v 1 build/shots/${LANG}_6.png
  .venv-tools/bin/python tools/art/store_shots.py $LANG build/shots/${LANG}_1.png build/shots/${LANG}_2.png build/shots/${LANG}_3.png build/shots/${LANG}_4.png build/shots/${LANG}_5.png build/shots/${LANG}_6.png
done
