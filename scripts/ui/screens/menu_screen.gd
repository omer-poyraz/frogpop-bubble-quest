extends ScreenBase
## Main menu: animated frog, logo, play, daily reward, costumes, missions, settings, record, PRO.

var frog: Frog
var frog_holder: Node2D
var logo: TextureRect
var column: VBoxContainer
var daily_badge: Control
var _tap_t: float = 0.0

func _ready() -> void:
	build_base("menu_title", false, false)
	# replace default header (menu has its own) -> hide children of base column except spacer
	var col: VBoxContainer = content
	for c in col.get_children():
		c.queue_free()
	var idx: int = int(SaveManager.data["selected_theme"])
	bg.apply_theme(idx if idx >= 0 else int(Time.get_unix_time_from_system() / 86400) % 10, int(Time.get_ticks_msec() / 1000) % 3)
	AudioManager.play_music("music_menu")
	# top bar
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	var pill: PanelContainer = UI.pill()
	var vp: HBoxContainer = UI.value_pill("coin", LocalizationManager.fmt_num(ProgressionManager.coins()), 40)
	pill.add_child(vp)
	top.add_child(pill)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	var pro: FButton = FButton.create("pro_short", "yellow", Vector2(210, 100), "crown", 38)
	pro.pressed.connect(func() -> void: GameManager.go("pro"))
	if ProgressionManager.is_pro():
		pro.set_style("purple")
	top.add_child(pro)
	var set_btn: FButton = FButton.create("", "dark", Vector2(100, 100), "gear")
	set_btn.pressed.connect(func() -> void: GameManager.go("settings"))
	top.add_child(set_btn)
	col.add_child(top)
	# logo
	logo = TextureRect.new()
	logo.texture = load("res://assets/branding/wordmark.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(900, 330)
	logo.pivot_offset = Vector2(450, 165)
	col.add_child(logo)
	var lt: Tween = logo.create_tween().set_loops()
	lt.tween_property(logo, "scale", Vector2(1.03, 1.03), 1.4).set_trans(Tween.TRANS_SINE)
	lt.tween_property(logo, "scale", Vector2.ONE, 1.4).set_trans(Tween.TRANS_SINE)
	# frog area
	var area := Control.new()
	area.custom_minimum_size = Vector2(0, 520)
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.name = "frog_area"
	col.add_child(area)
	frog_holder = Node2D.new()
	area.add_child(frog_holder)
	var pad := Sprite2D.new()
	pad.texture = load("res://assets/characters/frog_pad_back.png")
	pad.scale = Vector2(0.95, 0.95)
	pad.modulate = Color(0.6, 0.95, 0.7)
	pad.position = Vector2(0, 90)
	frog_holder.add_child(pad)
	frog = Frog.new()
	frog.base_scale = 0.95
	frog_holder.add_child(frog)
	frog.build(ProgressionManager.selected_skin())
	area.resized.connect(func() -> void: frog_holder.position = Vector2(area.size.x * 0.5, area.size.y * 0.5 + 20))
	frog_holder.position = Vector2(540, 260)
	var frog_btn := Button.new()
	frog_btn.flat = true
	frog_btn.focus_mode = Control.FOCUS_NONE
	frog_btn.custom_minimum_size = Vector2(440, 440)
	frog_btn.position = Vector2(320, 40)
	frog_btn.modulate.a = 0.0
	frog_btn.pressed.connect(_on_frog_tap)
	area.add_child(frog_btn)
	# best
	var best: LocLabel = UI.label("menu_best", 44, Color("ffd23c"), HORIZONTAL_ALIGNMENT_CENTER, [LocalizationManager.fmt_num(int(SaveManager.data["high_score"]))])
	col.add_child(best)
	# play
	var play: FButton = FButton.create("btn_play", "green", Vector2(760, 170), "play", 76)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(func() -> void: GameManager.start_game("classic"))
	col.add_child(play)
	var pt: Tween = play.create_tween().set_loops()
	pt.tween_property(play, "modulate", Color(1.15, 1.15, 1.15), 0.8).set_trans(Tween.TRANS_SINE)
	pt.tween_property(play, "modulate", Color.WHITE, 0.8).set_trans(Tween.TRANS_SINE)
	var modes: FButton = FButton.create("btn_modes", "blue", Vector2(760, 110), "star", 46)
	modes.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	modes.pressed.connect(func() -> void: GameManager.go("modes"))
	col.add_child(modes)
	# row of round buttons
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	col.add_child(row)
	var defs: Array = [["gift", "daily", "pink", "btn_daily"], ["frog", "shop", "purple", "btn_costumes"], ["trophy", "missions", "yellow", "btn_missions"], ["chart", "stats", "blue", "btn_stats"]]
	for d in defs:
		var holder := VBoxContainer.new()
		holder.add_theme_constant_override("separation", 4)
		var b: FButton = FButton.create("", d[2], Vector2(190, 150), d[0])
		var dest: String = d[1]
		b.pressed.connect(func() -> void: GameManager.go(dest))
		holder.add_child(b)
		var l: LocLabel = UI.label(d[3], 28, Color.WHITE)
		holder.add_child(l)
		row.add_child(holder)
		if d[1] == "daily" and ProgressionManager.daily_info()["can_claim"]:
			var dot := Panel.new()
			dot.add_theme_stylebox_override("panel", UI.box(Color("ff3a5e"), Color.WHITE, 24, 4, 0))
			dot.custom_minimum_size = Vector2(48, 48)
			dot.position = Vector2(140, -6)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(dot)
			var bang: Label = UI.raw_label("!", 34)
			bang.position = Vector2(0, 0)
			bang.size = Vector2(48, 48)
			dot.add_child(bang)
			var dt: Tween = dot.create_tween().set_loops()
			dt.tween_property(dot, "scale", Vector2(1.2, 1.2), 0.5)
			dt.tween_property(dot, "scale", Vector2.ONE, 0.5)
			daily_badge = dot
	col.add_child(UI.spacer(10))

func _process(delta: float) -> void:
	if frog != null and frog.nodes.size() > 0:
		var mp: Vector2 = get_global_mouse_position()
		frog.look_at_point(mp)
	_tap_t -= delta

func _on_frog_tap() -> void:
	if _tap_t > 0.0:
		return
	_tap_t = 0.6
	AudioManager.play("coin", 1.2, -6.0)
	var r: float = randf()
	if r < 0.4:
		frog.play("happy")
	elif r < 0.7:
		frog.play("tongue")
	elif r < 0.9:
		frog.play("combo")
	else:
		frog.play("special")
