extends ScreenBase

func _ready() -> void:
	build_base("modes_title")
	var infos: Array = [["classic", "mode_classic", "mode_classic_d", "green", "infinity"], ["time", "mode_time", "mode_time_d", "red", "p_slow"],
		["zen", "mode_zen", "mode_zen_d", "blue", "heart"], ["daily", "mode_daily", "mode_daily_d", "purple", "calendar"]]
	var dc: Dictionary = SaveManager.data["daily_challenge"]
	var today: String = ProgressionManager.date_str()
	for inf in infos:
		var c: PanelContainer = card(230)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 22)
		c.add_child(h)
		var ic: TextureRect = UI.icon_rect(inf[4] if inf[4] != "infinity" else "star", 110)
		h.add_child(ic)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 6)
		h.add_child(v)
		v.add_child(UI.label(inf[1], 54, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
		var d: LocLabel = UI.label(inf[2], 32, Color("a9b8ff"), HORIZONTAL_ALIGNMENT_LEFT)
		d.custom_minimum_size = Vector2(420, 0)
		v.add_child(d)
		if inf[0] == "daily":
			var done: bool = str(dc["date"]) == today and bool(dc["done"])
			var best: int = int(dc["best"]) if str(dc["date"]) == today else 0
			v.add_child(UI.label("daily_state", 30, Color("ffd23c") if not done else Color("7dffb0"), HORIZONTAL_ALIGNMENT_LEFT, [LocalizationManager.fmt_num(best), "OK" if done else "-"]))
		var b: FButton = FButton.create("btn_play", inf[3], Vector2(230, 120), "", 44)
		var m: String = inf[0]
		b.pressed.connect(func() -> void: GameManager.start_game(m))
		h.add_child(b)
		content.add_child(c)
