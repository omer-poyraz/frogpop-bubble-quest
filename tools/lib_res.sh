# source: set_res WxH  -> writes override.cfg (window size used by Godot Movie Maker); clear_res removes it
set_res() {
  local W=${1%x*} H=${1#*x}
  printf '[display]\n\nwindow/size/window_width_override=%s\nwindow/size/window_height_override=%s\n' "$W" "$H" > override.cfg
}
clear_res() { rm -f override.cfg; }
