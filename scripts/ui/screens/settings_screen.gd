extends ScreenBase

func _ready() -> void:
	build_base("settings_title", false)
	var c: PanelContainer = card(200)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	c.add_child(v)
	v.add_child(_slider("set_music", "music", "music"))
	v.add_child(_slider("set_sfx", "sfx", "sound"))
	v.add_child(_toggle("set_mute", "mute", "mute"))
	v.add_child(_toggle("set_vibration", "vibration", "vibrate"))
	v.add_child(_toggle("set_colorblind", "colorblind", "eye"))
	v.add_child(_toggle("set_aimline", "aim_line", "play"))
	content.add_child(c)
	# quality
	var qc: PanelContainer = card(200)
	var qv := VBoxContainer.new()
	qv.add_theme_constant_override("separation", 14)
	qc.add_child(qv)
	qv.add_child(UI.label("set_quality", 42, Color("ffd23c")))
	var qrow := HBoxContainer.new()
	qrow.alignment = BoxContainer.ALIGNMENT_CENTER
	qrow.add_theme_constant_override("separation", 14)
	qv.add_child(qrow)
	var qbs: Array[FButton] = []
	for i in 3:
		var qb: FButton = FButton.create(["q_low", "q_med", "q_high"][i], "yellow" if SettingsManager.quality == i else "blue", Vector2(280, 100), "", 38)
		qbs.append(qb)
		qb.pressed.connect(func() -> void:
			SettingsManager.set_setting("quality", i)
			for j in 3:
				qbs[j].set_style("yellow" if j == i else "blue"))
		qrow.add_child(qb)
	content.add_child(qc)
	# language
	var lc: PanelContainer = card(200)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 14)
	lc.add_child(lv)
	lv.add_child(UI.label("set_language", 42, Color("ffd23c")))
	var lrow := HBoxContainer.new()
	lrow.alignment = BoxContainer.ALIGNMENT_CENTER
	lrow.add_theme_constant_override("separation", 14)
	lv.add_child(lrow)
	var lbs: Dictionary = {}
	for code in LocalizationManager.languages:
		var lb: FButton = FButton.create("", "yellow" if LocalizationManager.current == code else "blue", Vector2(280, 100), "globe", 38)
		lb.text = LocalizationManager.t("lang_" + code)
		lbs[code] = lb
		var cc: String = code
		lb.pressed.connect(func() -> void:
			LocalizationManager.set_language(cc)
			for k in lbs:
				(lbs[k] as FButton).set_style("yellow" if k == cc else "blue")
				(lbs[k] as FButton).text = LocalizationManager.t("lang_" + k))
		lrow.add_child(lb)
	content.add_child(lc)
	# legal + data
	var dc: PanelContainer = card(200)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 14)
	dc.add_child(dv)
	var pp: FButton = FButton.create("set_privacy", "blue", Vector2(760, 100), "info", 38)
	pp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pp.pressed.connect(func() -> void: OS.shell_open("https://omer-poyraz.github.io/frogpop-bubble-quest/privacy-policy/"))
	dv.add_child(pp)
	var tos: FButton = FButton.create("set_terms", "blue", Vector2(760, 100), "info", 38)
	tos.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tos.pressed.connect(func() -> void: OS.shell_open("https://omer-poyraz.github.io/frogpop-bubble-quest/terms/"))
	dv.add_child(tos)
	var reset: FButton = FButton.create("set_reset", "red", Vector2(760, 100), "close", 38)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	reset.pressed.connect(_confirm_reset)
	dv.add_child(reset)
	dv.add_child(UI.raw_label("FrogPop: Bubble Quest  v%s  |  Poyraz Yazılım" % str(ProjectSettings.get_setting("application/config/version")), 26, Color("8f9bd6")))
	content.add_child(dc)

func _row(label_key: String, icon_name: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	h.add_child(UI.icon_rect(icon_name, 64))
	var l: LocLabel = UI.label(label_key, 40, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	return h

func _slider(label_key: String, setting: String, icon_name: String) -> Control:
	var h: HBoxContainer = _row(label_key, icon_name)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(SettingsManager.get_setting(setting))
	s.custom_minimum_size = Vector2(380, 60)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color("3fd96a")
	grab.set_corner_radius_all(14)
	s.add_theme_stylebox_override("slider", UI.box(Color(0, 0, 0, 0.45), Color(1, 1, 1, 0.25), 14, 2, 0))
	s.add_theme_stylebox_override("grabber_area", grab)
	s.add_theme_stylebox_override("grabber_area_highlight", grab)
	s.value_changed.connect(func(v: float) -> void:
		SettingsManager.set_setting(setting, v)
		if setting == "sfx":
			AudioManager.play("pop", 1.0, 0.0, 0.1))
	h.add_child(s)
	return h

func _toggle(label_key: String, setting: String, icon_name: String) -> Control:
	var h: HBoxContainer = _row(label_key, icon_name)
	var b: FButton = FButton.create("", "green" if bool(SettingsManager.get_setting(setting)) else "gray", Vector2(190, 84), "", 36)
	b.text = LocalizationManager.t("on") if bool(SettingsManager.get_setting(setting)) else LocalizationManager.t("off")
	b.pressed.connect(func() -> void:
		var nv: bool = not bool(SettingsManager.get_setting(setting))
		SettingsManager.set_setting(setting, nv)
		b.set_style("green" if nv else "gray")
		b.text = LocalizationManager.t("on") if nv else LocalizationManager.t("off"))
	h.add_child(b)
	return h

func _confirm_reset() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var p: PanelContainer = UI.panel()
	p.custom_minimum_size = Vector2(800, 520)
	p.position = Vector2(140, 700)
	dim.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 24)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)
	v.add_child(UI.label("reset_confirm", 42, Color.WHITE))
	var yes: FButton = FButton.create("yes_delete", "red", Vector2(560, 110), "", 40)
	yes.pressed.connect(func() -> void:
		SaveManager.reset_all()
		GameManager.go("menu"))
	v.add_child(yes)
	var no: FButton = FButton.create("cancel", "gray", Vector2(560, 110), "", 40)
	no.pressed.connect(func() -> void: dim.queue_free())
	v.add_child(no)
