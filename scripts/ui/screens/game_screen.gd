extends Control
## Gameplay screen: owns the GameCore, GameView, HUD, input, overlays and event -> effect wiring.

var params: Dictionary = {}
var mode: String = "classic"
var core: GameCore
var view: GameView
var bg: ThemeBackground
var world: Node2D
var floating: FloatingText
var touch: Control
var hud: Control
var top_bar: Control
var power_bar: HBoxContainer
var power_buttons: Dictionary = {}
var score_label: Label
var best_label: Label
var wave_label: Label
var world_label: Label
var coin_label: Label
var streak_label: Label
var timer_label: Label
var progress: ProgressBar
var meter: ProgressBar
var banner: Label
var banner_sub: Label
var hint: Label
var danger_rect: ColorRect
var danger_mat: ShaderMaterial
var flash_rect: ColorRect
var overlay_layer: Control
var pause_btn: FButton
var bot: Bot = null
var auto_play: bool = false

var _shown_score: float = 0.0
var _shake: float = 0.0
var _zoom: float = 0.0
var _theme_idx: int = -1
var _pressing: bool = false
var _press_time: float = 0.0
var _press_pos: Vector2 = Vector2.ZERO
var _targeting: String = ""
var _paused: bool = false
var _over: bool = false
var _warn_t: float = 0.0
var _best_at_start: int = 0
var _results: Dictionary = {}
var _first_shot_done: bool = false
var _wave_seen: int = 0

func _ready() -> void:
	mode = str(params.get("mode", GameManager.mode))
	auto_play = bool(params.get("auto_play", false))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_best_at_start = int(SaveManager.data["high_score"])
	AdsManager.in_gameplay = true
	_build_world()
	_build_hud()
	get_tree().root.size_changed.connect(_layout)
	_layout()
	core = GameCore.new()
	core.wave_started.connect(_on_wave_started)
	core.shot_fired.connect(_on_shot)
	core.ball_inserted.connect(_on_inserted)
	core.pop_scored.connect(_on_pop)
	core.missed.connect(_on_miss)
	core.power_used.connect(_on_power_used)
	core.power_earned.connect(_on_power_earned)
	core.game_over.connect(_on_game_over)
	core.wave_cleared.connect(_on_wave_cleared)
	core.score_changed.connect(_on_score)
	core.streak_changed.connect(_on_streak)
	core.bomb_exploded.connect(_on_bomb)
	core.lightning_struck.connect(_on_lightning)
	core.ammo_changed.connect(_on_ammo_changed)
	view.setup(core)
	var inv: Dictionary = {}
	for p in K.POWERS:
		inv[p] = ProgressionManager.power_count(p)
	var start_wave: int = int(params.get("start_wave", 1))
	if auto_play:
		bot = Bot.new()
		bot.skill = 0.97
	core.start(mode, int(params.get("seed", GameManager.game_seed(mode))), inv, start_wave)
	_update_power_buttons()
	if not SaveManager.data["tutorial_done"] and not auto_play:
		_show_hint()

# ------------------------------------------------------------------ build
func _build_world() -> void:
	bg = ThemeBackground.new()
	add_child(bg)
	world = Node2D.new()
	add_child(world)
	view = GameView.new()
	world.add_child(view)
	floating = FloatingText.new()
	floating.z_index = 60
	world.add_child(floating)
	touch = Control.new()
	touch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	touch.mouse_filter = Control.MOUSE_FILTER_STOP
	touch.gui_input.connect(_on_touch)
	add_child(touch)
	danger_rect = ColorRect.new()
	danger_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	danger_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	danger_mat = ShaderMaterial.new()
	danger_mat.shader = load("res://shaders/vignette.gdshader")
	danger_rect.material = danger_mat
	add_child(danger_rect)
	flash_rect = ColorRect.new()
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(1, 1, 1, 0)
	add_child(flash_rect)

func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	top_bar = Control.new()
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.custom_minimum_size = Vector2(0, 260)
	top_bar.size = Vector2(1080, 260)
	hud.add_child(top_bar)
	pause_btn = FButton.create("", "dark", Vector2(112, 112), "pause")
	pause_btn.position = Vector2(30, 24)
	pause_btn.pressed.connect(_toggle_pause)
	top_bar.add_child(pause_btn)
	var sc_title: LocLabel = UI.label("hud_score", 28, Color("a9b8ff"))
	sc_title.position = Vector2(290, 14)
	sc_title.size = Vector2(500, 36)
	top_bar.add_child(sc_title)
	score_label = UI.raw_label("0", 92, Color.WHITE)
	score_label.position = Vector2(240, 40)
	score_label.size = Vector2(600, 104)
	top_bar.add_child(score_label)
	best_label = UI.raw_label("", 30, Color("ffd23c"))
	best_label.position = Vector2(240, 140)
	best_label.size = Vector2(600, 40)
	top_bar.add_child(best_label)
	var coin_pill: PanelContainer = UI.pill()
	coin_pill.position = Vector2(830, 26)
	coin_pill.custom_minimum_size = Vector2(220, 60)
	var cv: HBoxContainer = UI.value_pill("coin", "0", 34)
	coin_label = cv.get_node("value")
	coin_pill.add_child(cv)
	top_bar.add_child(coin_pill)
	wave_label = UI.raw_label("", 36, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	wave_label.position = Vector2(700, 96)
	wave_label.size = Vector2(350, 44)
	top_bar.add_child(wave_label)
	world_label = UI.raw_label("", 28, Color("a9b8ff"), HORIZONTAL_ALIGNMENT_RIGHT)
	world_label.position = Vector2(600, 138)
	world_label.size = Vector2(450, 36)
	top_bar.add_child(world_label)
	timer_label = UI.raw_label("", 64, Color("ffd23c"))
	timer_label.position = Vector2(30, 140)
	timer_label.size = Vector2(200, 80)
	timer_label.visible = false
	top_bar.add_child(timer_label)
	progress = ProgressBar.new()
	progress.position = Vector2(150, 198)
	progress.size = Vector2(780, 26)
	progress.show_percentage = false
	progress.min_value = 0.0
	progress.max_value = 1.0
	var bgs: StyleBoxFlat = UI.box(Color(0, 0, 0, 0.4), Color(1, 1, 1, 0.25), 13, 3, 0)
	bgs.content_margin_top = 0
	bgs.content_margin_bottom = 0
	progress.add_theme_stylebox_override("background", bgs)
	var fills: StyleBoxFlat = UI.box(Color("3fd96a"), Color("1c8f45"), 13, 2, 0)
	fills.content_margin_top = 0
	fills.content_margin_bottom = 0
	progress.add_theme_stylebox_override("fill", fills)
	top_bar.add_child(progress)
	var hole_icon: TextureRect = UI.icon_rect("heart", 46)
	hole_icon.position = Vector2(944, 186)
	top_bar.add_child(hole_icon)
	streak_label = UI.raw_label("", 46, Color("ffd23c"))
	streak_label.position = Vector2(290, 232)
	streak_label.size = Vector2(500, 56)
	streak_label.pivot_offset = Vector2(250, 28)
	streak_label.modulate.a = 0.0
	top_bar.add_child(streak_label)
	# power bar
	power_bar = HBoxContainer.new()
	power_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	power_bar.add_theme_constant_override("separation", 10)
	power_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(power_bar)
	for p in K.POWERS:
		power_bar.add_child(_make_power_button(p))
	meter = ProgressBar.new()
	meter.show_percentage = false
	meter.min_value = 0.0
	meter.max_value = 1.0
	meter.add_theme_stylebox_override("background", UI.box(Color(0, 0, 0, 0.4), Color(1, 1, 1, 0.2), 8, 2, 0))
	var mf: StyleBoxFlat = UI.box(Color("a65bff"), Color("5a2aa8"), 8, 2, 0)
	meter.add_theme_stylebox_override("fill", mf)
	meter.custom_minimum_size = Vector2(820, 16)
	hud.add_child(meter)
	banner = UI.raw_label("", 96, Color.WHITE)
	banner.modulate.a = 0.0
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(banner)
	banner_sub = UI.raw_label("", 52, Color("ffd23c"))
	banner_sub.modulate.a = 0.0
	banner_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(banner_sub)
	hint = UI.label("hint_aim", 44, Color.WHITE)
	hint.visible = false
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(hint)
	overlay_layer = Control.new()
	overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay_layer)

func _make_power_button(p: String) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(128, 140)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b: FButton = FButton.create("", "dark", Vector2(122, 122), "p_" + p)
	b.position = Vector2(3, 12)
	b.pressed.connect(_on_power_pressed.bind(p))
	holder.add_child(b)
	var badge: Label = UI.raw_label("0", 30, Color.WHITE)
	badge.position = Vector2(78, 0)
	badge.size = Vector2(48, 44)
	badge.name = "badge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_bg := Panel.new()
	badge_bg.add_theme_stylebox_override("panel", UI.box(Color("ff5a6e"), Color.WHITE, 22, 3, 0))
	badge_bg.position = Vector2(80, 0)
	badge_bg.size = Vector2(46, 44)
	badge_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_bg.name = "badge_bg"
	holder.add_child(badge_bg)
	holder.add_child(badge)
	power_buttons[p] = {"holder": holder, "button": b, "badge": badge, "bg": badge_bg}
	return holder

func _layout() -> void:
	if world == null:
		return
	var vp: Vector2 = get_viewport_rect().size
	world.position = Vector2((vp.x - K.FIELD_W) * 0.5, (vp.y - K.FIELD_H) * 0.5)
	var ins: Vector4 = UI.safe_insets(get_viewport())
	top_bar.position = Vector2((vp.x - 1080.0) * 0.5, ins.x)
	power_bar.position = Vector2((vp.x - 1000.0) * 0.5, vp.y - 160.0 - ins.y)
	power_bar.size = Vector2(1000, 140)
	meter.position = Vector2((vp.x - 820.0) * 0.5, vp.y - 176.0 - ins.y)
	banner.position = Vector2((vp.x - 1000.0) * 0.5, vp.y * 0.30)
	banner.size = Vector2(1000, 120)
	banner.pivot_offset = Vector2(500, 60)
	banner_sub.position = Vector2((vp.x - 1000.0) * 0.5, vp.y * 0.30 + 120.0)
	banner_sub.size = Vector2(1000, 70)
	hint.position = Vector2((vp.x - 900.0) * 0.5, vp.y * 0.62)
	hint.size = Vector2(900, 160)

# ------------------------------------------------------------------ loop
func _process(delta: float) -> void:
	if core == null:
		return
	var vp: Vector2 = get_viewport_rect().size
	if not _paused and not _over:
		core.update(delta)
		if bot != null:
			bot.tick(core, delta)
			view.aim_visible = false
		core.power.tick(0.0)
		_update_hud(delta)
	elif _over:
		core.update(0.0)
	# look + shake + zoom
	if not _paused:
		var mouth: Vector2 = core.frog_pos
		if view.aim_visible:
			view.frog.look_at_point(view.global_transform * view.aim_target)
		else:
			var tgt: Ball = core.chain.front_balls(1)[0] if core.chain.front_balls(1).size() > 0 else null
			if tgt != null:
				view.frog.look_at_point(view.global_transform * core.chain.world_pos(tgt))
		_shake = maxf(_shake - delta * 40.0, 0.0)
		_zoom = maxf(_zoom - delta * 1.6, 0.0)
		var base: Vector2 = Vector2((vp.x - K.FIELD_W) * 0.5, (vp.y - K.FIELD_H) * 0.5)
		var off: Vector2 = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake if _shake > 0.5 else Vector2.ZERO
		var z: float = 1.0 + _zoom * 0.035
		world.scale = Vector2(z, z)
		world.position = base + off - (Vector2(vp.x * 0.5, vp.y * 0.5) - base) * (z - 1.0)

func _update_hud(delta: float) -> void:
	_shown_score = lerpf(_shown_score, float(core.score_mgr.score), 1.0 - exp(-delta * 10.0))
	score_label.text = LocalizationManager.fmt_num(int(round(_shown_score)))
	var best: int = maxi(_best_at_start, core.score_mgr.score)
	best_label.text = LocalizationManager.t("hud_best") + " " + LocalizationManager.fmt_num(best)
	coin_label.text = LocalizationManager.fmt_num(ProgressionManager.coins())
	if core.chain.count() > 0:
		var pr: float = clampf(core.chain.front_s() / core.path.length, 0.0, 1.0)
		progress.value = pr
		var fs: StyleBoxFlat = progress.get_theme_stylebox("fill") as StyleBoxFlat
		fs.bg_color = Color("3fd96a").lerp(Color("ff4a5e"), clampf((pr - 0.45) / 0.45, 0.0, 1.0))
	meter.value = core.power.meter
	danger_mat.set_shader_parameter("strength", core.danger * core.danger * 0.75)
	if core.danger > 0.8 and core.state == GameCore.State.PLAYING:
		_warn_t -= delta
		if _warn_t <= 0.0:
			_warn_t = 0.9
			AudioManager.play("warn", 1.0, -8.0)
	if mode == "time":
		timer_label.visible = true
		timer_label.text = str(int(ceil(core.time_left)))
		timer_label.modulate = Color(1, 0.4, 0.4) if core.time_left < 10.0 else Color.WHITE
	_update_power_buttons()

func _update_power_buttons() -> void:
	for p in power_buttons:
		var d: Dictionary = power_buttons[p]
		var n: int = core.power.count(p) if core != null else ProgressionManager.power_count(p)
		(d["badge"] as Label).text = str(n)
		(d["badge"] as Label).visible = n > 0
		(d["bg"] as Panel).visible = n > 0
		var b: FButton = d["button"]
		var active: bool = (p == "bomb" and core != null and core.power.bomb_armed) or (p == _targeting) or \
			(p == "slow" and core != null and core.power.slow_t > 0.0) or (p == "shield" and core != null and core.power.shield_t > 0.0)
		b.set_style("yellow" if active else ("dark" if n > 0 else "gray"))
		b.modulate.a = 1.0 if n > 0 else 0.75

# ------------------------------------------------------------------ input
func _field_pos(p: Vector2) -> Vector2:
	return (p - world.position) / world.scale.x if world.scale.x > 0.01 else p - world.position

func _on_touch(ev: InputEvent) -> void:
	if _paused or _over or core == null or bot != null:
		return
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		var fp: Vector2 = _field_pos(ev.position)
		if ev.pressed:
			_pressing = true
			_press_time = Time.get_ticks_msec() / 1000.0
			_press_pos = fp
			view.aim_target = fp
			view.aim_visible = true
		elif _pressing:
			_pressing = false
			var quick: bool = Time.get_ticks_msec() / 1000.0 - _press_time < 0.25
			if _targeting != "":
				_use_targeted(fp)
			elif quick and fp.distance_to(core.frog_pos) < 70.0:
				core.swap_ammo()
				AudioManager.play("swap")
			else:
				core.fire(fp)
			view.aim_visible = false
	elif ev is InputEventMouseMotion and _pressing:
		view.aim_target = _field_pos(ev.position)

func _use_targeted(fp: Vector2) -> void:
	var p: String = _targeting
	_targeting = ""
	var hits: Array = core.chain.balls_within(fp, K.HIT_RADIUS + 20.0)
	if hits.is_empty():
		GameManager.toast("toast_tap_ball")
		_targeting = p
		return
	core.use_power(p, fp)

func _on_power_pressed(p: String) -> void:
	if _paused or _over or core == null:
		return
	if core.power.count(p) <= 0:
		var price: int = int(K.POWER_PRICE[p])
		if ProgressionManager.coins() >= price and ProgressionManager.buy_power(p):
			core.power.inventory[p] = core.power.count(p) + 1
			GameManager.toast("toast_bought", [LocalizationManager.t("power_" + p)])
			AudioManager.play("coin")
		else:
			GameManager.toast("toast_need_coins", [price])
		return
	if p == "rainbow":
		if _targeting == "rainbow":
			_targeting = ""
		else:
			_targeting = "rainbow"
			GameManager.toast("toast_tap_ball")
		return
	core.use_power(p)

func _toggle_pause() -> void:
	if _over:
		return
	_set_paused(not _paused)

func _set_paused(on: bool) -> void:
	_paused = on
	get_tree().paused = on
	if on:
		_show_pause_overlay()
	else:
		_clear_overlay()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if core != null and not _over and not _paused and bot == null:
			_set_paused(true)
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not _over:
		_toggle_pause()

func _exit_tree() -> void:
	get_tree().paused = false
	AdsManager.in_gameplay = false

# ------------------------------------------------------------------ overlays
func _clear_overlay() -> void:
	for c in overlay_layer.get_children():
		c.queue_free()

func _dim() -> ColorRect:
	var d := ColorRect.new()
	d.color = Color(0.02, 0.04, 0.14, 0.72)
	d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	d.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_layer.add_child(d)
	return d

func _centered_panel(w: float, h: float) -> PanelContainer:
	var vp: Vector2 = get_viewport_rect().size
	var p: PanelContainer = UI.panel()
	p.custom_minimum_size = Vector2(w, h)
	p.position = Vector2((vp.x - w) * 0.5, (vp.y - h) * 0.5)
	p.pivot_offset = Vector2(w, h) * 0.5
	p.scale = Vector2(0.85, 0.85)
	p.modulate.a = 0.0
	overlay_layer.add_child(p)
	var tw: Tween = p.create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(p, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "modulate:a", 1.0, 0.18)
	return p

func _show_pause_overlay() -> void:
	_clear_overlay()
	overlay_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	_dim()
	var p: PanelContainer = _centered_panel(760, 880)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)
	v.add_child(UI.label("pause_title", 80, Color.WHITE))
	var resume: FButton = FButton.create("resume", "green", Vector2(560, 130), "play")
	resume.pressed.connect(func() -> void: _set_paused(false))
	v.add_child(resume)
	var restart: FButton = FButton.create("restart", "blue", Vector2(560, 110), "replay")
	restart.pressed.connect(func() -> void: _leave("game"))
	v.add_child(restart)
	if mode == "zen" or mode == "time":
		var fin: FButton = FButton.create("finish_run", "purple", Vector2(560, 110), "check")
		fin.pressed.connect(func() -> void:
			_set_paused(false)
			core.end_now())
		v.add_child(fin)
	var menu: FButton = FButton.create("menu", "gray", Vector2(560, 110), "home")
	menu.pressed.connect(func() -> void: _leave("menu"))
	v.add_child(menu)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	var snd: FButton = FButton.create("", "dark", Vector2(110, 110), "mute" if SettingsManager.muted else "sound")
	snd.pressed.connect(func() -> void:
		SettingsManager.set_setting("mute", not SettingsManager.muted)
		snd.icon = UI.icon("mute" if SettingsManager.muted else "sound"))
	row.add_child(snd)
	var vib: FButton = FButton.create("", "dark" if SettingsManager.vibration else "gray", Vector2(110, 110), "vibrate")
	vib.pressed.connect(func() -> void:
		SettingsManager.set_setting("vibration", not SettingsManager.vibration)
		vib.set_style("dark" if SettingsManager.vibration else "gray"))
	row.add_child(vib)
	v.add_child(row)

func _leave(screen: String) -> void:
	_clear_overlay()
	_paused = false
	get_tree().paused = false
	if not _over:
		# an abandoned run still counts (score, stats) except when nothing happened
		if core.shots > 0 and mode != "zen":
			_over = true
			core.end_now()
			ProgressionManager.report_game(core_result())
	AdsManager.in_gameplay = false
	AdsManager.note_game_finished()
	if screen == "menu" or screen == "game":
		AdsManager.show_interstitial()
	if screen == "game":
		GameManager.start_game(mode)
	else:
		GameManager.go(screen)

func core_result() -> Dictionary:
	return {"reason": "quit", "score": core.score_mgr.score, "wave": core.wave, "time": core.time, "balls": core.score_mgr.balls_popped,
		"best_chain": core.score_mgr.best_chain, "best_combo": core.score_mgr.best_combo, "coins": core.score_mgr.coins_earned,
		"shots": core.shots, "mode": mode, "powers_used": core.power.used_count}

func _show_hint() -> void:
	hint.visible = true
	hint.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(hint, "modulate:a", 1.0, 0.6).set_delay(1.2)

# ------------------------------------------------------------------ core events
func _theme_for_wave(wave: int) -> int:
	var sel: int = int(SaveManager.data["selected_theme"])
	if sel >= 0:
		return sel
	return ThemeManager.world_for_wave(wave, core.seed_value)

func _on_wave_started(wave: int, path: PathData) -> void:
	var idx: int = _theme_for_wave(wave)
	var var_idx: int = ThemeManager.variant_for_wave(wave, core.seed_value)
	var th: Dictionary = ThemeManager.get_theme(idx)
	var changed: bool = idx != _theme_idx
	bg.apply_theme(idx, var_idx, _theme_idx >= 0 and changed)
	view.on_new_wave(th)
	world_label.text = LocalizationManager.world_name(idx)
	wave_label.text = LocalizationManager.t("hud_wave", [wave])
	if changed:
		if _theme_idx >= 0:
			AudioManager.play("world")
			view.fx.confetti(Vector2(K.FIELD_W * 0.5, K.FIELD_H * 0.5), 40)
		AudioManager.play_music(str(th["music"]), 1.5)
	_theme_idx = idx
	_wave_seen = wave
	if mode == "daily":
		_show_banner(LocalizationManager.t("mode_daily") + " " + str(wave) + "/3", LocalizationManager.world_name(idx))
	elif wave > 1 or changed:
		_show_banner(LocalizationManager.t("hud_wave", [wave]), LocalizationManager.world_name(idx))
	view.frog.play("idle")
	progress.value = 0.0

func _show_banner(t1: String, t2: String) -> void:
	banner.text = t1
	banner_sub.text = t2
	banner.scale = Vector2(0.6, 0.6)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(banner, "modulate:a", 1.0, 0.2)
	tw.tween_property(banner, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(banner_sub, "modulate:a", 1.0, 0.3)
	var tw2: Tween = create_tween()
	tw2.tween_interval(1.5)
	tw2.set_parallel(true)
	tw2.tween_property(banner, "modulate:a", 0.0, 0.5)
	tw2.tween_property(banner_sub, "modulate:a", 0.0, 0.5)

func _on_shot(color: int, from: Vector2, dir: Vector2) -> void:
	AudioManager.play("shoot", randf_range(0.95, 1.08), -3.0)
	SettingsManager.vibrate(8)
	var col: Color = K.color_of(color) if color < 8 else Color.WHITE
	view.fx_add.muzzle_flash(from, col)
	view.frog.on_shoot()
	view.frog.on_tongue() if randf() < 0.0 else null
	if not _first_shot_done:
		_first_shot_done = true
		if hint.visible:
			hint.visible = false
		SaveManager.data["tutorial_done"] = true
		SaveManager.mark_dirty()

func _on_inserted(b: Ball, contact: Vector2) -> void:
	view.ball_inserted(b, contact)
	AudioManager.play("collide", randf_range(0.9, 1.15), -4.0)
	view.fx_add.shockwave(core.path.pos_at(b.s), Color(1, 1, 1, 0.5), 40.0, 380.0)

func _on_miss() -> void:
	pass

func _on_ammo_changed() -> void:
	pass

func _on_score(_s: int) -> void:
	pass

func _on_streak(streak: int) -> void:
	if streak >= 2:
		streak_label.text = LocalizationManager.t("hud_streak", [streak])
		streak_label.modulate.a = 1.0
		streak_label.scale = Vector2(1.4, 1.4)
		var tw: Tween = create_tween()
		tw.tween_property(streak_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		view.frog.set_excited(streak >= 5)
	else:
		streak_label.modulate.a = 0.0
		view.frog.set_excited(false)
	view.frog.on_streak(streak)

func _on_pop(info: Dictionary, award: Dictionary) -> void:
	var balls: Array = info["balls"]
	var poss: PackedVector2Array = info["positions"]
	var level: int = int(info["level"])
	var n: int = balls.size()
	var center: Vector2 = Vector2.ZERO
	for i in n:
		var b: Ball = balls[i]
		var delay: float = float(i) * 0.03
		view.spawn_death(poss[i], b.color, delay, b.kind, b.golden)
		center += poss[i]
		var col: Color = K.color_of(b.color) if b.color >= 0 else Color("b0b0c0")
		var pos_i: Vector2 = poss[i]
		var inten: float = 1.0 + 0.25 * float(level)
		var t: Tween = create_tween()
		t.tween_interval(delay + 0.12)
		t.tween_callback(func() -> void:
			if is_instance_valid(view):
				view.fx.burst_pop(pos_i, col, inten)
				view.fx_add.burst_pop(pos_i, col.lightened(0.3), inten * 0.5))
		if i < 6 or i % 3 == 0:
			var tp: Tween = create_tween()
			tp.tween_interval(delay + 0.08)
			tp.tween_callback(AudioManager.play_pop.bind(level, n))
	center /= float(maxi(n, 1))
	_shake = minf(8.0 + float(n) * 1.6 + float(level) * 5.0, 30.0) * (0.6 if SettingsManager.quality == 0 else 1.0)
	SettingsManager.vibrate(20 + mini(n * 4, 60))
	var pts: int = int(award["points"])
	var col2: Color = Color("ffd23c") if level == 0 else Color("ff9a3c")
	floating.show_text("+" + str(pts), center + Vector2(0, -50), col2, 52 + mini(level * 8, 30))
	var delay_txt: float = 0.0
	for lk in award["labels"]:
		var tt: Tween = create_tween()
		tt.tween_interval(0.12 + delay_txt)
		tt.tween_callback(func() -> void:
			floating.show_text(LocalizationManager.t(lk), center + Vector2(0, -130 - delay_txt * 280.0), Color("ff7ac8"), 66, 120.0, 1.2))
		delay_txt += 0.18
	if award["big"]:
		view.fx_add.burst_stars(center, Color("ffe27a"), 14 + level * 4)
		view.fx_add.shockwave(center, Color(1, 0.95, 0.6, 0.8), 70.0, 1100.0)
		AudioManager.play("combo" if level < 2 else "chain", 1.0, -2.0)
		_zoom = 1.0
		flash_rect.color = Color(1, 1, 1, 0.22)
		create_tween().tween_property(flash_rect, "color:a", 0.0, 0.25)
		view.frog.play("combo" if level >= 2 else "happy")
	if award["golden"] > 0:
		AudioManager.play("coin")
		view.fx_add.burst_stars(center, Color("ffd23c"), 18)
	if n >= 5 and level == 0:
		view.frog.on_tongue()

func _on_power_used(p: String) -> void:
	# persist inventory change
	SaveManager.data["powers"][p] = maxi(int(SaveManager.data["powers"].get(p, 0)) - 1, 0)
	SaveManager.mark_dirty()
	_targeting = ""
	view.frog.play("special")
	var snd: String = {"rainbow": "rainbow", "bomb": "switch", "slow": "slow", "switch": "switch", "lightning": "lightning", "shield": "shield", "backward": "rewind"}[p]
	AudioManager.play(snd)
	var c: Vector2 = core.frog_pos
	view.fx_add.burst_stars(c, Color("a8c8ff"), 16)
	view.fx_add.shockwave(c, Color(0.7, 0.85, 1.0, 0.8), 80.0, 1500.0)
	if p == "slow":
		flash_rect.color = Color(0.5, 0.7, 1.0, 0.3)
		create_tween().tween_property(flash_rect, "color:a", 0.0, 0.5)
	floating.show_text(LocalizationManager.t("power_" + p), c + Vector2(0, -140), Color("a8c8ff"), 56, 100.0, 1.1)
	_update_power_buttons()

func _on_power_earned(p: String) -> void:
	ProgressionManager.add_power(p)
	GameManager.toast("toast_power_earned", [LocalizationManager.t("power_" + p)])
	AudioManager.play("power")

func _on_bomb(pos: Vector2) -> void:
	AudioManager.play("bomb")
	view.fx.burst_stars(pos, Color("ff9a3c"), 22, 800.0)
	view.fx_add.shockwave(pos, Color(1, 0.7, 0.3, 0.9), 80.0, 1800.0)
	view.fx_add.emit(5, pos, Vector2.ZERO, 0.4, 300.0, Color(1, 0.8, 0.4, 0.8), 600.0)
	_shake = 34.0
	flash_rect.color = Color(1, 0.9, 0.7, 0.4)
	create_tween().tween_property(flash_rect, "color:a", 0.0, 0.35)

func _on_lightning(positions: PackedVector2Array) -> void:
	view.fx_add.lightning_bolt(positions)
	_shake = 24.0
	flash_rect.color = Color(0.9, 0.95, 1.0, 0.5)
	create_tween().tween_property(flash_rect, "color:a", 0.0, 0.3)

func _on_wave_cleared(wave: int, bonus: int) -> void:
	AudioManager.play("win")
	view.fx.confetti(Vector2(K.FIELD_W * 0.5, K.FIELD_H * 0.6), 50)
	view.frog.play("victory")
	_show_banner(LocalizationManager.t("wave_clear"), "+" + str(bonus))
	SettingsManager.vibrate(60)

func _on_game_over(info: Dictionary) -> void:
	if _over:
		return
	_over = true
	AdsManager.in_gameplay = false
	_targeting = ""
	view.aim_visible = false
	if info["reason"] != "daily_done" and info["reason"] != "time":
		view.frog.play("game_over")
		AudioManager.play("gameover")
	else:
		view.frog.play("victory")
		AudioManager.play("win")
	_results = ProgressionManager.report_game(info)
	AdsManager.note_game_finished()
	GameManager.last_result = info
	get_tree().create_timer(0.9).timeout.connect(func() -> void: _show_game_over(info))

func _show_game_over(info: Dictionary) -> void:
	if not is_inside_tree():
		return
	_clear_overlay()
	overlay_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	_dim()
	var p: PanelContainer = _centered_panel(860, 1180)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)
	var title_key: String = "go_title"
	if info["reason"] == "time":
		title_key = "go_time_up"
	elif info["reason"] == "daily_done":
		title_key = "go_daily_done"
	elif info["reason"] == "quit":
		title_key = "go_finished"
	v.add_child(UI.label(title_key, 78, Color("ffd23c")))
	var sc: Label = UI.raw_label("0", 120, Color.WHITE)
	v.add_child(sc)
	var tw: Tween = create_tween()
	tw.tween_method(func(k: float) -> void: sc.text = LocalizationManager.fmt_num(int(k)), 0.0, float(info["score"]), 1.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _results.get("record", false):
		var rec: LocLabel = UI.label("go_new_record", 58, Color("ff7ac8"))
		v.add_child(rec)
		rec.pivot_offset = Vector2(430, 40)
		var rt: Tween = rec.create_tween().set_loops()
		rt.tween_property(rec, "scale", Vector2(1.1, 1.1), 0.5).set_trans(Tween.TRANS_SINE)
		rt.tween_property(rec, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
		AudioManager.play("record")
		view.fx.confetti(Vector2(K.FIELD_W * 0.5, 500), 60)
	else:
		v.add_child(UI.label("go_best_is", 40, Color("a9b8ff"), HORIZONTAL_ALIGNMENT_CENTER, [LocalizationManager.fmt_num(int(SaveManager.data["high_score"]))]))
	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 40)
	stats.add_theme_constant_override("v_separation", 6)
	for pair in [["st_wave", info["wave"]], ["st_balls", info["balls"]], ["st_best_combo", info["best_combo"]], ["st_best_chain", info["best_chain"]]]:
		stats.add_child(UI.label(pair[0], 36, Color("a9b8ff"), HORIZONTAL_ALIGNMENT_LEFT))
		stats.add_child(UI.raw_label(str(pair[1]), 36, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT))
	var sc_center := CenterContainer.new()
	sc_center.add_child(stats)
	v.add_child(sc_center)
	var coins_row := HBoxContainer.new()
	coins_row.alignment = BoxContainer.ALIGNMENT_CENTER
	coins_row.add_child(UI.value_pill("coin", "+" + str(int(_results.get("coins", 0))), 50))
	v.add_child(coins_row)
	for aid in _results.get("achievements", []):
		v.add_child(UI.label("ach_toast", 34, Color("7dffb0"), HORIZONTAL_ALIGNMENT_CENTER, [LocalizationManager.t(aid)]))
	# actions
	if info.get("can_continue", false) and AdsManager.can_show_rewarded():
		var cont: FButton = FButton.create("go_continue", "purple", Vector2(640, 120), "ad")
		cont.pressed.connect(func() -> void: _on_continue_pressed(cont))
		v.add_child(cont)
	elif info.get("can_continue", false):
		var na: Label = UI.label("ads_unavailable", 30, Color("8f9bd6"))
		v.add_child(na)
	var again: FButton = FButton.create("go_replay", "green", Vector2(640, 128), "replay")
	again.pressed.connect(func() -> void: _leave_after_over("game"))
	v.add_child(again)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	var menu: FButton = FButton.create("go_menu", "blue", Vector2(310, 100), "home", 38)
	menu.pressed.connect(func() -> void: _leave_after_over("menu"))
	row.add_child(menu)
	var share: FButton = FButton.create("go_missions", "yellow", Vector2(310, 100), "trophy", 38)
	share.pressed.connect(func() -> void: _leave_after_over("missions"))
	row.add_child(share)
	v.add_child(row)

func _on_continue_pressed(btn: FButton) -> void:
	btn.disabled = true
	var cb: Callable = func(ok: bool) -> void:
		if ok:
			_clear_overlay()
			_over = false
			AdsManager.in_gameplay = true
			core.revive()
			view.frog.play("idle")
		else:
			btn.disabled = false
	AdsManager.rewarded_finished.connect(cb, CONNECT_ONE_SHOT)
	AdsManager.show_rewarded()

func _leave_after_over(screen: String) -> void:
	AdsManager.show_interstitial()
	if screen == "game":
		GameManager.start_game(mode)
	else:
		GameManager.go(screen)
