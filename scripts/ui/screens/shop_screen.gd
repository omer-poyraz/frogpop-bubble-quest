extends ScreenBase

var tab: String = "skins"
var tabs_row: HBoxContainer

func _ready() -> void:
	build_base("shop_title")
	tabs_row = HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation", 12)
	tabs_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var col: Node = content.get_parent().get_parent()
	col.add_child(tabs_row)
	col.move_child(tabs_row, 1)
	for t in ["skins", "worlds", "powers"]:
		var b: FButton = FButton.create("tab_" + t, "blue", Vector2(300, 90), "", 36)
		b.name = "tab_" + t
		b.pressed.connect(func() -> void:
			tab = t
			_rebuild())
		tabs_row.add_child(b)
	tab = str(params.get("tab", "skins"))
	_rebuild()

func _rebuild() -> void:
	for t in ["skins", "worlds", "powers"]:
		(tabs_row.get_node("tab_" + t) as FButton).set_style("yellow" if t == tab else "blue")
	clear_content()
	match tab:
		"skins": _skins()
		"worlds": _worlds()
		"powers": _powers()

func _skins() -> void:
	var sel: String = ProgressionManager.selected_skin()
	for s in ProgressionManager.skins:
		var id: String = s["id"]
		var c: PanelContainer = card(260)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 22)
		c.add_child(h)
		var tr := TextureRect.new()
		tr.texture = load("res://assets/characters/preview_%s.png" % id)
		tr.custom_minimum_size = Vector2(220, 248)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(tr)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 10)
		h.add_child(v)
		v.add_child(UI.label(str(s["name_key"]), 50, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
		var unlocked: bool = ProgressionManager.is_skin_unlocked(id)
		var b: FButton
		if id == sel:
			b = FButton.create("selected", "gray", Vector2(360, 100), "check", 38)
			b.disabled = true
		elif unlocked:
			b = FButton.create("select", "green", Vector2(360, 100), "", 40)
			b.pressed.connect(func() -> void:
				ProgressionManager.select_skin(id)
				_rebuild())
		elif s["unlock"] == "coins":
			b = FButton.create("", "yellow", Vector2(360, 100), "coin", 40)
			b.text = LocalizationManager.fmt_num(int(s["price"]))
			b.pressed.connect(func() -> void:
				if ProgressionManager.buy_skin(id):
					AudioManager.play("coin")
					ProgressionManager.select_skin(id)
					_rebuild()
				else:
					GameManager.toast("toast_need_coins", [int(s["price"])]))
		elif s["unlock"] == "pro":
			b = FButton.create("pro_only", "purple", Vector2(360, 100), "crown", 36)
			b.pressed.connect(func() -> void: GameManager.go("pro"))
		else:
			b = FButton.create("unlock_by_ach", "gray", Vector2(360, 100), "lock", 30)
			b.disabled = true
			v.add_child(UI.label(str(s.get("achievement", "")), 28, Color("a9b8ff"), HORIZONTAL_ALIGNMENT_LEFT))
		v.add_child(b)
		content.add_child(c)

func _worlds() -> void:
	var sel: int = int(SaveManager.data["selected_theme"])
	var unlocked: Array = SaveManager.data["unlocked_themes"]
	var auto_c: PanelContainer = card(130)
	var ah := HBoxContainer.new()
	auto_c.add_child(ah)
	var al: LocLabel = UI.label("world_auto", 44, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	al.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ah.add_child(al)
	var ab: FButton = FButton.create("selected" if sel < 0 else "select", "gray" if sel < 0 else "green", Vector2(300, 90), "", 34)
	ab.disabled = sel < 0
	ab.pressed.connect(func() -> void:
		ProgressionManager.select_theme(-1)
		_rebuild())
	ah.add_child(ab)
	content.add_child(auto_c)
	for i in ThemeManager.count():
		var th: Dictionary = ThemeManager.get_theme(i)
		var c: PanelContainer = card(150)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 18)
		c.add_child(h)
		var sw := ColorRect.new()
		sw.custom_minimum_size = Vector2(130, 110)
		var grad := GradientTexture2D.new()
		var g := Gradient.new()
		g.set_color(0, Color(str(th["sky"][0])))
		g.set_color(1, Color(str(th["sky"][2])))
		grad.gradient = g
		grad.fill_from = Vector2(0.5, 0)
		grad.fill_to = Vector2(0.5, 1)
		var tr := TextureRect.new()
		tr.texture = grad
		tr.custom_minimum_size = Vector2(130, 110)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.add_child(tr)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label("world_%d" % i, 42, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
		var is_unlocked: bool = unlocked.has(i)
		var pro_only: bool = th.get("pro_only", false)
		var b: FButton
		if sel == i:
			b = FButton.create("selected", "gray", Vector2(260, 90), "check", 32)
			b.disabled = true
		elif pro_only and not ProgressionManager.is_pro():
			b = FButton.create("pro_only", "purple", Vector2(260, 90), "crown", 30)
			b.pressed.connect(func() -> void: GameManager.go("pro"))
		elif is_unlocked:
			b = FButton.create("select", "green", Vector2(260, 90), "", 34)
			b.pressed.connect(func() -> void:
				ProgressionManager.select_theme(i)
				_rebuild())
		else:
			b = FButton.create("world_locked", "gray", Vector2(260, 90), "lock", 28)
			b.disabled = true
		h.add_child(b)
		content.add_child(c)

func _powers() -> void:
	for p in K.POWERS:
		var c: PanelContainer = card(170)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 18)
		c.add_child(h)
		h.add_child(UI.icon_rect("p_" + p, 110))
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label("power_" + p, 42, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
		var d: LocLabel = UI.label("power_%s_d" % p, 26, Color("a9b8ff"), HORIZONTAL_ALIGNMENT_LEFT)
		d.custom_minimum_size = Vector2(380, 0)
		v.add_child(d)
		v.add_child(UI.label("shop_owned", 28, Color("ffd23c"), HORIZONTAL_ALIGNMENT_LEFT, [ProgressionManager.power_count(p)]))
		var b: FButton = FButton.create("", "yellow", Vector2(240, 96), "coin", 38)
		b.text = str(K.POWER_PRICE[p])
		b.pressed.connect(func() -> void:
			if ProgressionManager.buy_power(p):
				AudioManager.play("coin")
				_rebuild()
			else:
				GameManager.toast("toast_need_coins", [K.POWER_PRICE[p]]))
		h.add_child(b)
		content.add_child(c)
