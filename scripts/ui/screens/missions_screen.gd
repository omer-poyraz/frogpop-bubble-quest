extends ScreenBase

var tab: String = "daily"
var tabs_row: HBoxContainer

func _ready() -> void:
	build_base("missions_title")
	tabs_row = HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation", 12)
	tabs_row.alignment = BoxContainer.ALIGNMENT_CENTER
	content.get_parent().get_parent().add_child(tabs_row)
	content.get_parent().get_parent().move_child(tabs_row, 1)
	for t in ["daily", "weekly", "ach"]:
		var b: FButton = FButton.create("tab_" + t, "blue", Vector2(300, 90), "", 36)
		b.name = "tab_" + t
		b.pressed.connect(func() -> void:
			tab = t
			_rebuild())
		tabs_row.add_child(b)
	_rebuild()

func _rebuild() -> void:
	for t in ["daily", "weekly", "ach"]:
		(tabs_row.get_node("tab_" + t) as FButton).set_style("yellow" if t == tab else "blue")
	clear_content()
	ProgressionManager.ensure_missions()
	if tab == "ach":
		_achievements()
		return
	var weekly: bool = tab == "weekly"
	var list: Array = SaveManager.data["missions"]["weekly" if weekly else "list"]
	for i in list.size():
		content.add_child(_mission_row(list[i], weekly, i))

func _mission_row(m: Dictionary, weekly: bool, idx: int) -> Control:
	var c: PanelContainer = card(190)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	c.add_child(v)
	var h := HBoxContainer.new()
	v.add_child(h)
	var l: LocLabel = UI.label(str(m["key"]), 38, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, [m["target"]])
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(UI.value_pill("coin", str(m["coins"]), 34))
	var pb := ProgressBar.new()
	pb.custom_minimum_size = Vector2(0, 34)
	pb.show_percentage = false
	pb.max_value = float(m["target"])
	pb.value = minf(float(m["progress"]), float(m["target"]))
	pb.add_theme_stylebox_override("background", UI.box(Color(0, 0, 0, 0.4), Color(1, 1, 1, 0.2), 16, 2, 0))
	pb.add_theme_stylebox_override("fill", UI.box(Color("3fd96a"), Color("1c8f45"), 16, 2, 0))
	v.add_child(pb)
	var h2 := HBoxContainer.new()
	v.add_child(h2)
	var pl: Label = UI.raw_label("%d / %d" % [mini(int(m["progress"]), int(m["target"])), int(m["target"])], 30, Color("a9b8ff"), HORIZONTAL_ALIGNMENT_LEFT)
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h2.add_child(pl)
	var done: bool = int(m["progress"]) >= int(m["target"])
	var b: FButton = FButton.create("claimed" if m["claimed"] else "claim", "gray" if m["claimed"] else ("green" if done else "dark"), Vector2(240, 80), "", 34)
	b.disabled = (not done) or bool(m["claimed"])
	b.pressed.connect(func() -> void:
		if ProgressionManager.claim_mission(weekly, idx):
			AudioManager.play("coin")
			_rebuild())
	h2.add_child(b)
	return c

func _achievements() -> void:
	var got: Dictionary = SaveManager.data["achievements"]
	for a in ProgressionManager.achievements:
		var c: PanelContainer = card(150)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 18)
		c.add_child(h)
		var done: bool = got.has(a["id"])
		var ic: TextureRect = UI.icon_rect("check" if done else "lock", 70)
		ic.modulate = Color("7dffb0") if done else Color(1, 1, 1, 0.55)
		h.add_child(ic)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label(str(a["id"]), 36, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
		var prog: float = ProgressionManager.achievement_progress(a)
		var pb := ProgressBar.new()
		pb.custom_minimum_size = Vector2(0, 22)
		pb.show_percentage = false
		pb.max_value = 1.0
		pb.value = prog
		pb.add_theme_stylebox_override("background", UI.box(Color(0, 0, 0, 0.4), Color(1, 1, 1, 0.2), 11, 2, 0))
		pb.add_theme_stylebox_override("fill", UI.box(Color("ffd23c"), Color("c98a0a"), 11, 2, 0))
		v.add_child(pb)
		h.add_child(UI.value_pill("coin", str(a["coins"]), 32))
		content.add_child(c)
