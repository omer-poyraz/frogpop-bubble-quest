extends RefCounted

func _scan(dir: String, out: Array) -> void:
	var d: DirAccess = DirAccess.open(dir)
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		_scan(dir + "/" + sub, out)

func test_all_scripts_compile(t: Node) -> void:
	var files: Array = []
	_scan("res://scripts", files)
	_scan("res://tests", files)
	for f in files:
		var s: Resource = load(f)
		t.check(s != null and (s as GDScript).can_instantiate() or f.ends_with("test_runner.gd"), "compiles: " + f)

func test_background_has_size(t: Node) -> void:
	var holder := Control.new()
	holder.size = Vector2(1080, 1920)
	t.add_child(holder)
	var bg := ThemeBackground.new()
	holder.add_child(bg)
	bg.apply_theme(0, 0)
	await t.get_tree().process_frame
	await t.get_tree().process_frame
	print("bg size ", bg.size, " sky size ", bg.sky.size, " mat top ", bg._mat.get_shader_parameter("top"), " layers ", bg.layers[0].size)
	t.check(bg.sky.size.x > 100.0, "sky has size")
	holder.queue_free()

const SIZES: Array = [Vector2(1080, 1920), Vector2(1080, 2340), Vector2(1440, 1920), Vector2(1080, 1620)]

func _overflow(node: Node, vp: Vector2, bad: Array) -> void:
	if node is ThemeBackground:
		return
	if node is Control:
		var c: Control = node
		if c.is_visible_in_tree() and c.size.x > 0.0 and c.size.y > 0.0 and c.modulate.a > 0.1:
			var r: Rect2 = c.get_global_rect()
			var in_scroll: bool = false
			var p: Node = c.get_parent()
			while p != null:
				if p is ScrollContainer:
					in_scroll = true
					break
				p = p.get_parent()
			if not in_scroll and (r.position.x < -3.0 or r.end.x > vp.x + 3.0) and c.get_class() != "ColorRect":
				bad.append("%s %s" % [c.get_path(), r])
	for ch in node.get_children():
		_overflow(ch, vp, bad)

func test_every_screen_opens_without_overflow(t: Node) -> void:
	for sz in SIZES:
		for name in GameManager.SCREENS.keys():
			if name == "boot" or name == "game":
				continue
			var holder := Control.new()
			holder.size = sz
			holder.custom_minimum_size = sz
			t.add_child(holder)
			var scr: Control = GameManager.make_screen(name, {})
			scr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			holder.add_child(scr)
			await t.get_tree().process_frame
			await t.get_tree().process_frame
			var bad: Array = []
			_overflow(scr, sz, bad)
			t.check(bad.is_empty(), "%s @%s overflow: %s" % [name, sz, str(bad.slice(0, 2))])
			t.check(scr.get_child_count() > 0, name + " has content")
			holder.queue_free()
			await t.get_tree().process_frame

func test_game_screen_every_mode_autoplays(t: Node) -> void:
	for mode in K.MODES:
		var holder := Control.new()
		holder.size = Vector2(1080, 1920)
		t.add_child(holder)
		var scr: Control = GameManager.make_screen("game", {"mode": mode, "auto_play": true, "seed": 321})
		scr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.add_child(scr)
		await t.get_tree().process_frame
		var steps: int = 0
		while steps < 2400 and scr.core.state != GameCore.State.LOST and scr.core.state != GameCore.State.ENDED:
			scr._process(1.0 / 30.0)
			steps += 1
		t.check(scr.core.score_mgr.score > 0, "%s: bot scored (%d)" % [mode, scr.core.score_mgr.score])
		t.check(scr.view.get_child_count() > 3, "%s: view built" % mode)
		t.check(scr.core.chain.check_invariants() == "", "%s: invariants" % mode)
		holder.queue_free()
		await t.get_tree().process_frame
	AdsManager.in_gameplay = false

func test_game_screen_input_and_overlays(t: Node) -> void:
	SaveManager.data["powers"]["slow"] = 3
	var holder := Control.new()
	holder.size = Vector2(1080, 1920)
	t.add_child(holder)
	var scr: Control = GameManager.make_screen("game", {"mode": "classic", "seed": 5})
	scr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(scr)
	await t.get_tree().process_frame
	for i in 300:
		scr._process(1.0 / 30.0)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = scr.world.position + scr.core.frog_pos + Vector2(0, -400)
	scr._on_touch(ev)
	t.check(scr.view.aim_visible, "press shows aim")
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = ev.position
	scr._on_touch(up)
	t.check(scr.core.shots == 1, "release fires")
	scr._toggle_pause()
	await t.get_tree().process_frame
	t.check(scr.get_tree().paused and scr.overlay_layer.get_child_count() > 0, "pause overlay")
	scr._toggle_pause()
	t.check(not scr.get_tree().paused, "resume")
	# power button use
	scr._on_power_pressed("slow")
	t.check(scr.core.power.slow_t > 0.0, "power button works")
	# force game over -> panel
	scr.core.end_now()
	for i in 10:
		await t.get_tree().process_frame
	await t.get_tree().create_timer(1.1).timeout
	t.check(scr.overlay_layer.get_child_count() > 0, "game over panel")
	scr.get_tree().paused = false
	holder.queue_free()
	AdsManager.in_gameplay = false

func test_frog_has_all_12_animations_and_costumes(t: Node) -> void:
	for costume in ["classic", "royal", "wizard", "ninja", "pirate", "galaxy"]:
		var frog := Frog.new()
		t.add_child(frog)
		frog.build(costume)
		for a in Frog.ANIMS:
			t.check(frog.player.has_animation(a) or frog.blinker.has_animation(a), "%s has %s" % [costume, a])
		# every animation track must resolve to a real node
		var img: Node = frog.lean.get_node("img")
		var broken: int = 0
		for a in Frog.ANIMS:
			var pl: AnimationPlayer = frog.blinker if a == "blink" else frog.player
			var anim: Animation = pl.get_animation(a)
			for i in anim.get_track_count():
				var np: NodePath = anim.track_get_path(i)
				var root: Node = img if pl.root_node == pl.get_path_to(img) else frog
				if root.get_node_or_null(NodePath(np.get_concatenated_names())) == null:
					broken += 1
		t.check(broken == 0, "%s animation tracks resolve (%d broken)" % [costume, broken])
		for a in Frog.ANIMS:
			frog.play(a)
			frog._process(0.1)
		t.check(frog.nodes.has("pupil_l"), "eyes exist")
		frog.look_at_point(Vector2(500, 100))
		frog._process(0.05)
		frog.queue_free()
		await t.get_tree().process_frame

func test_localization_complete(t: Node) -> void:
	var files: Array = []
	_scan("res://scripts", files)
	var used: Dictionary = {}
	var rx := RegEx.new()
	rx.compile("(?:UI\\.label|FButton\\.create|\\.t|set_key|LocLabel\\.new|_show_banner|toast)\\(\"([a-z][a-z_0-9]*)\"")
	for f in files:
		var txt: String = FileAccess.get_file_as_string(f)
		for m in rx.search_all(txt):
			if not m.get_string(1).ends_with("_"):
				used[m.get_string(1)] = f
	# dynamic families
	for p in K.POWERS:
		used["power_" + p] = "dyn"
		used["power_%s_d" % p] = "dyn"
	for i in 10:
		used["world_%d" % i] = "dyn"
	for s in ProgressionManager.skins:
		used[str(s["name_key"])] = "dyn"
	for a in ProgressionManager.achievements:
		used[str(a["id"])] = "dyn"
	for m in ProgressionManager.mission_templates:
		used[str(m["key"])] = "dyn"
	for m in K.MODES:
		used["mode_" + m] = "dyn"
		used["mode_%s_d" % m] = "dyn"
	for k in ["sc_double", "sc_triple", "sc_chain_reaction", "sc_perfect", "sc_streak", "sc_golden", "sc_last_second", "tab_daily", "tab_weekly", "tab_ach", "tab_skins", "tab_worlds", "tab_powers", "q_low", "q_med", "q_high", "lang_en", "lang_tr", "store_unavailable", "purchase_ok", "store_error"]:
		used[k] = "dyn"
	var missing: Array = []
	for k in used:
		if not LocalizationManager.has_key(k):
			missing.append("%s (%s)" % [k, used[k]])
	t.check(missing.is_empty(), "missing translation keys: " + str(missing.slice(0, 8)))
	for k in LocalizationManager.table:
		var e: Dictionary = LocalizationManager.table[k]
		for lang in LocalizationManager.languages:
			t.check(str(e.get(lang, "")) != "", "key %s has %s" % [k, lang])
		# placeholders must match between languages
		for i in 3:
			var ph: String = "{%d}" % i
			t.check(str(e.get("en", "")).contains(ph) == str(e.get("tr", "")).contains(ph), "placeholder %s consistent in %s" % [ph, k])
	t.check(LocalizationManager.languages.size() >= 2, "TR + EN")

func test_audio_files_exist(t: Node) -> void:
	var files: Array = []
	_scan("res://scripts", files)
	var rx := RegEx.new()
	rx.compile("AudioManager\\.play\\(\"([a-z_]+)\"")
	var names: Dictionary = {}
	for f in files:
		for m in rx.search_all(FileAccess.get_file_as_string(f)):
			names[m.get_string(1)] = true
	for n in names:
		t.check(ResourceLoader.exists("res://assets/audio/sfx_%s.ogg" % n), "sfx exists: " + n)
	for i in 10:
		t.check(ResourceLoader.exists("res://assets/audio/theme_%d.ogg" % i), "music theme %d" % i)
	t.check(ResourceLoader.exists("res://assets/audio/music_menu.ogg"), "menu music")
	for key in ["pop", "shoot", "collide", "chain", "combo", "power", "click", "gameover", "record", "world"]:
		t.check(ResourceLoader.exists("res://assets/audio/sfx_%s.ogg" % key), "spec sound " + key)

func test_theme_data_complete(t: Node) -> void:
	for i in ThemeManager.count():
		var th: Dictionary = ThemeManager.get_theme(i)
		for k in ["sky", "track", "track_edge", "accent", "particles", "music", "decor", "variants"]:
			t.check(th.has(k), "theme %d has %s" % [i, k])
		t.check((th["variants"] as Array).size() == K.BG_VARIANTS, "theme %d has 3 variants" % i)
		t.check(ResourceLoader.exists("res://assets/audio/%s.ogg" % th["music"]), "theme music file")

func test_branding_assets_exist(t: Node) -> void:
	for f in ["logo", "icon", "splash", "feature_graphic", "mascot"]:
		t.check(FileAccess.file_exists("res://assets/branding/%s.png" % f), "branding " + f)
	var img: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/branding/play_store_icon_512.png"))
	t.check(img != null and img.get_width() == 512 and img.get_height() == 512, "512 play icon")
	var fg: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/branding/feature_graphic.png"))
	t.check(fg != null and fg.get_width() == 1024 and fg.get_height() == 500, "1024x500 feature graphic")
