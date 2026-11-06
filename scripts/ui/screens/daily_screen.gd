extends ScreenBase

var claim_btn: FButton
var grid: GridContainer
var info_label: LocLabel

func _ready() -> void:
	build_base("daily_title")
	_rebuild()

func _rebuild() -> void:
	clear_content()
	var info: Dictionary = ProgressionManager.daily_info()
	content.add_child(UI.label("daily_streak", 48, Color("ffd23c"), HORIZONTAL_ALIGNMENT_CENTER, [info["streak"]]))
	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 16)
	var cc := CenterContainer.new()
	cc.add_child(grid)
	content.add_child(cc)
	var cur: int = int(info["day"])
	var claimed_today: bool = info["claimed_today"]
	for i in 7:
		var p: PanelContainer = UI.panel(Color(0.1, 0.16, 0.38, 0.95), Color("4a62d6"), 30)
		p.custom_minimum_size = Vector2(205, 250)
		var rw: Dictionary = ProgressionManager.DAILY_TABLE[i]
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 6)
		p.add_child(v)
		v.add_child(UI.label("daily_day", 30, Color("a9b8ff"), HORIZONTAL_ALIGNMENT_CENTER, [i + 1]))
		if rw.has("coins"):
			v.add_child(UI.icon_rect("coin", 84))
			v.add_child(UI.raw_label(str(rw["coins"] * (1.5 if ProgressionManager.is_pro() else 1.0)).get_slice(".", 0), 40, Color("ffd23c")))
		if rw.has("power"):
			v.add_child(UI.icon_rect("p_" + str(rw["power"]), 84))
			v.add_child(UI.label("power_" + str(rw["power"]), 24, Color.WHITE))
		var done: bool = i + 1 < cur or (i + 1 == cur and claimed_today)
		if done:
			var ck: TextureRect = UI.icon_rect("check", 60)
			ck.modulate = Color("7dffb0")
			v.add_child(ck)
		elif i + 1 == cur:
			p.add_theme_stylebox_override("panel", UI.box(Color(0.2, 0.3, 0.7, 0.98), Color("ffd23c"), 30, 6, 16))
		grid.add_child(p)
	claim_btn = FButton.create("daily_claim", "green", Vector2(700, 140), "gift", 56)
	claim_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	claim_btn.disabled = not info["can_claim"]
	claim_btn.pressed.connect(_claim)
	content.add_child(claim_btn)
	if info["rolled_back"]:
		content.add_child(UI.wrap_label("daily_clock", 34, Color("ff9a9a"), 900))
	elif claimed_today:
		content.add_child(UI.wrap_label("daily_come_back", 36, Color("a9b8ff"), 900))
	if ProgressionManager.is_pro():
		content.add_child(UI.label("daily_pro_bonus", 32, Color("ff7ac8")))

func _claim() -> void:
	var r: Dictionary = ProgressionManager.claim_daily()
	if r.is_empty():
		return
	AudioManager.play("power")
	var parts: Array[String] = []
	if r.has("coins"):
		parts.append("+%d" % int(r["coins"]))
	if r.has("power"):
		parts.append(LocalizationManager.t("power_" + str(r["power"])))
	GameManager.toast("daily_got", [" / ".join(parts)])
	_rebuild()
