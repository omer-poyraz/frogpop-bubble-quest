extends ScreenBase

func _ready() -> void:
	build_base("stats_title")
	var d: Dictionary = SaveManager.data
	var rows: Array = [["st_high", LocalizationManager.fmt_num(int(d["high_score"]))], ["st_total", LocalizationManager.fmt_num(int(d["total_score"]))],
		["st_games", str(d["games_played"])], ["st_time", _fmt_time(float(d["play_time"]))], ["st_balls", LocalizationManager.fmt_num(int(d["balls_popped"]))],
		["st_best_wave", str(d["best_wave"])], ["st_best_combo", str(d["best_combo"])], ["st_best_chain", str(d["best_chain"])], ["st_powers", str(d["powers_used"])],
		["st_achievements", "%d / %d" % [(d["achievements"] as Dictionary).size(), ProgressionManager.achievements.size()]]]
	var c: PanelContainer = card(200)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	c.add_child(v)
	for r in rows:
		var h := HBoxContainer.new()
		var l: LocLabel = UI.label(r[0], 40, Color("a9b8ff"), HORIZONTAL_ALIGNMENT_LEFT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		h.add_child(UI.raw_label(r[1], 44, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT))
		v.add_child(h)
	content.add_child(c)

func _fmt_time(s: float) -> String:
	var m: int = int(s / 60.0)
	return "%dh %02dm" % [m / 60, m % 60] if m >= 60 else "%d min" % m
