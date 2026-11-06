extends Control
## Scripted capture of REAL gameplay for the promo videos (never AI footage).
## Run one clip per process:
##   godot --path . res://tools/trailer_director.tscn --write-movie out.avi --fixed-fps 60 --resolution 1920x1080 --quit-after N -- --fresh-save --clip=hook --lang=en
## Clips: hook pre play worlds powers costumes modes cta logo
const CAP: Dictionary = {
	"en": {
		"aim": "AIM. SHOOT. POP!", "chain": "CHAIN REACTIONS!", "combo": "BIG COMBOS", "worlds": "10 MAGICAL WORLDS", "endless": "ENDLESS FUN",
		"powers": "7 SUPER POWER-UPS", "costumes": "CUTE FROG COSTUMES", "modes": "4 GAME MODES", "offline": "PLAY OFFLINE", "free": "FREE TO PLAY",
		"download": "DOWNLOAD NOW", "store": "Android & iOS", "again": "POP AGAIN?", "tag": "Pop the chain. Save the pond!",
		"p_rainbow": "RAINBOW BLAST", "p_bomb": "BOMB BUBBLE", "p_slow": "SLOW MOTION", "p_switch": "COLOR SWITCH", "p_lightning": "LIGHTNING", "p_shield": "SHIELD", "p_backward": "BACKWARD BLAST",
		"m1": "Endless Classic", "m2": "Time Attack", "m3": "Zen Mode", "m4": "Daily Challenge",
		"c0": "Classic Frog", "c1": "Royal Frog", "c2": "Wizard Frog", "c3": "Ninja Frog", "c4": "Pirate Frog", "c5": "Galaxy Frog"},
	"tr": {
		"aim": "NİŞAN AL. AT. PATLAT!", "chain": "ZİNCİR REAKSİYONLAR!", "combo": "DEV KOMBOLAR", "worlds": "10 BÜYÜLÜ DÜNYA", "endless": "SONSUZ EĞLENCE",
		"powers": "7 SÜPER GÜÇLENDİRİCİ", "costumes": "SEVİMLİ KOSTÜMLER", "modes": "4 OYUN MODU", "offline": "ÇEVRİM DIŞI OYNA", "free": "ÜCRETSİZ OYNA",
		"download": "ŞİMDİ İNDİR", "store": "Android & iOS", "again": "TEKRAR PATLAT?", "tag": "Zinciri patlat, gölü kurtar!",
		"p_rainbow": "GÖKKUŞAĞI PATLAMASI", "p_bomb": "BOMBA BALON", "p_slow": "YAVAŞ ÇEKİM", "p_switch": "RENK DEĞİŞTİR", "p_lightning": "YILDIRIM", "p_shield": "KALKAN", "p_backward": "GERİ SARIM",
		"m1": "Sonsuz Klasik", "m2": "Zamana Karşı", "m3": "Zen Modu", "m4": "Günlük Meydan Okuma",
		"c0": "Klasik Kurbağa", "c1": "Kraliyet Kurbağası", "c2": "Büyücü Kurbağa", "c3": "Ninja Kurbağa", "c4": "Korsan Kurbağa", "c5": "Galaksi Kurbağası"}}

var clip: String = "hook"
var lang: String = "en"
var portrait: bool = false
var wave: int = 1
var seed_v: int = 7
var skin: String = "royal"
var think: float = 0.5
var demo: String = ""
var preroll: float = 0.0
var caps: Dictionary = {}
var overlay: CanvasLayer
var screen: Control = null
var holder: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--clip="): clip = a.substr(7)
		elif a.begins_with("--lang="): lang = a.substr(7)
		elif a.begins_with("--wave="): wave = int(a.substr(7))
		elif a.begins_with("--seed="): seed_v = int(a.substr(7))
		elif a.begins_with("--skin="): skin = a.substr(7)
		elif a.begins_with("--think="): think = float(a.substr(8))
		elif a.begins_with("--demo="): demo = a.substr(7)
		elif a.begins_with("--preroll="): preroll = float(a.substr(10))
		elif a == "--portrait": portrait = true
	caps = CAP[lang]
	LocalizationManager.set_language(lang, false)
	SettingsManager.set_setting("music", 0.0)   # music is added in post; clips keep game SFX only
	SaveManager.data["tutorial_done"] = true
	SaveManager.data["selected_skin"] = skin
	for s in ["royal", "wizard", "ninja", "pirate", "galaxy"]:
		if not (SaveManager.data["unlocked_skins"] as Array).has(s):
			(SaveManager.data["unlocked_skins"] as Array).append(s)
	for p in K.POWERS:
		SaveManager.data["powers"][p] = 5
	GameManager.register_main(self)
	holder = Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(holder)
	overlay = CanvasLayer.new()
	overlay.layer = 90
	add_child(overlay)
	await get_tree().process_frame
	call("_clip_" + clip)

# GameManager.go() is called by screens on button press; the director ignores navigation.
func show_screen(_n: String, _p: Dictionary) -> void:
	pass

func show_toast(_t: String) -> void:
	pass

# ---------------------------------------------------------------- helpers
func _vp() -> Vector2:
	return get_viewport_rect().size

func _make_screen(name: String, params: Dictionary) -> Control:
	if screen != null:
		screen.queue_free()
	var s: Control = GameManager.make_screen(name, params)
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(s)
	screen = s
	return s

func _game(params: Dictionary) -> Control:
	var p: Dictionary = {"no_banner": true, "mode": "classic", "auto_play": true, "seed": seed_v, "start_wave": wave, "bot_think": think}
	p.merge(params, true)
	var scr: Control = _make_screen("game", p)
	if preroll > 0.0:
		# fast-forward the simulation so the clip starts mid-action (all in one frame)
		var steps: int = int(preroll * 60.0)
		for i in steps:
			scr.core.update(1.0 / 60.0)
			if scr.bot != null:
				scr.bot.tick(scr.core, 1.0 / 60.0)
			for d in scr._demo:
				pass
		scr.core.power.tick(0.0)
	return scr

## Kinetic caption: pops in with a bounce, optional shake, fades out after `hold`.
func caption(text: String, where: String, color: Color = Color.WHITE, size: int = 140, at: float = 0.0, hold: float = 2.0, dy: float = 0.0) -> void:
	if at > 0.0:
		await get_tree().create_timer(at).timeout
	if not portrait:
		size = int(size * 1.3)
	var vp0: Vector2 = _vp()
	var max_w: float = 900.0 if portrait else (vp0.x - 1080.0) * 0.5 - 140.0
	var wide_bottom: bool = (not portrait) and where == "bottom"
	if wide_bottom:
		max_w = vp0.x * 0.8
	# shrink until the longest word fits on one line (no mid-word breaks)
	var longest: String = ""
	for wd in text.split(" "):
		if wd.length() > longest.length():
			longest = wd
	while size > 40 and UI.font(700).get_string_size(longest, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_w * 0.96:
		size = int(size * 0.94)
	var l := Label.new()
	UI.style_text(l, size, color, int(size / 5.0))
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	var vp: Vector2 = _vp()
	var w: float = max_w
	l.custom_minimum_size = Vector2(w, 0)
	l.size = Vector2(w, 400)
	l.pivot_offset = Vector2(w * 0.5, 200)
	var margin: float = 70.0
	match where:
		"left": l.position = Vector2(margin, vp.y * 0.5 - 200)
		"right": l.position = Vector2(vp.x - w - margin, vp.y * 0.5 - 200)
		"top": l.position = Vector2((vp.x - w) * 0.5, vp.y * (0.13 if portrait else 0.07))
		"bottom": l.position = Vector2((vp.x - w) * 0.5, vp.y * 0.70)
		_: l.position = Vector2((vp.x - w) * 0.5, vp.y * 0.5 - 200)
	l.position.y += dy
	l.scale = Vector2(0.3, 0.3)
	l.modulate.a = 0.0
	l.rotation = deg_to_rad(randf_range(-4.0, 4.0))
	overlay.add_child(l)
	var tw: Tween = l.create_tween().set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 1.0, 0.15)
	var tw2: Tween = l.create_tween()
	tw2.tween_interval(hold)
	tw2.tween_property(l, "modulate:a", 0.0, 0.3)
	tw2.parallel().tween_property(l, "scale", Vector2(1.15, 1.15), 0.3)
	tw2.tween_callback(l.queue_free)

func _side() -> String:
	return "top" if portrait else "left"

func _side2() -> String:
	return "bottom" if portrait else "right"

# ---------------------------------------------------------------- cascade scenario
const NEST: Array = [5, 6, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 3, 3, 2, 2, 1, 1, 0, 0, 6, 5, 7, 6, 5, 7]

func _build_cascade(scr: Control, route: String) -> int:
	var core: GameCore = scr.core
	var pd: PathData = PathGenerator.generate(route, 4711)
	core.path = pd
	core.frog_pos = pd.frog_pos
	core.params["speed"] = 24.0
	var cols: Array[int] = []
	for c in NEST:
		cols.append(int(c))
	core.chain.setup(pd, cols)
	var front_s: float = minf(pd.enter_s + float(cols.size()) * K.BALL_D + 120.0, pd.length * 0.55)
	for i in core.chain.balls.size():
		(core.chain.balls[i] as Ball).s = front_s - float(i) * K.BALL_D
	core.projectiles.clear()
	core.state = GameCore.State.PLAYING
	core.ammo = 4
	core.ammo_next = 6
	scr.view.on_new_wave(ThemeManager.get_theme(scr._theme_idx if scr._theme_idx >= 0 else 0))
	# index of the middle "4 4" pair: NEST indices 10,11
	return 10

func _fire_cascade(scr: Control) -> void:
	var core: GameCore = scr.core
	var tgt: Ball = core.chain.balls[10]
	core.ammo = 4
	core.reload = 0.0
	core.fire(core.chain.world_pos(tgt))

# ---------------------------------------------------------------- clips
func _clip_hook() -> void:
	var scr: Control = _game({"auto_play": false, "start_wave": 1, "seed": 3})
	await get_tree().create_timer(0.4).timeout
	_build_cascade(scr, "wave")
	scr.view.aim_target = scr.core.frog_pos + Vector2(0, -400)
	await get_tree().create_timer(0.6).timeout
	_fire_cascade(scr)
	caption(caps["chain"], _side(), Color("ffd23c"), 150, 0.8, 2.6)

func _clip_pre() -> void:
	# the exact frame the hook starts from (used as loop point for shorts)
	var scr: Control = _game({"auto_play": false, "start_wave": 1, "seed": 3})
	await get_tree().create_timer(0.4).timeout
	_build_cascade(scr, "wave")
	caption(caps["again"], "top" if portrait else "left", Color("ff7ac8"), 150, 0.1, 3.0)

func _clip_play() -> void:
	var scr: Control = _game({"bot_skill": 0.97})
	caption(caps["aim"], _side(), Color.WHITE, 150, 0.4, 2.4)
	caption(caps["combo"], _side2(), Color("ffd23c"), 140, 4.0, 2.4)

func _clip_worlds() -> void:
	# wave param selects the world (3 waves per world); caption = world name
	_game({"bot_skill": 1.0, "bot_think": 0.35})
	var idx: int = ThemeManager.world_for_wave(wave, seed_v)
	caption(LocalizationManager.world_name(idx).to_upper(), _side(), Color.WHITE, 130, 0.2, 2.2)

func _clip_powers() -> void:
	var scr: Control = _game({"demo": demo, "bot_think": 0.5, "bot_skill": 1.0})
	for d in demo.split(",", false):
		var kv: PackedStringArray = d.split(":")
		caption(caps["p_" + kv[1]], _side(), Color("a8c8ff"), 130, maxf(float(kv[0]) - 0.1, 0.05), 1.8)

func _clip_costumes() -> void:
	var vp: Vector2 = _vp()
	var bg := ThemeBackground.new()
	holder.add_child(bg)
	bg.apply_theme(9, 1)
	var fr := Frog.new()
	fr.base_scale = 1.9 if not portrait else 1.55
	holder.add_child(fr)
	fr.position = Vector2(vp.x * 0.5, vp.y * 0.5 + 40.0)
	var seq: Array = ["classic", "royal", "wizard", "ninja", "pirate", "galaxy"]
	var anims: Array = ["happy", "tongue", "combo", "shooting", "special", "victory"]
	fr.build("classic")
	fr.look_at_point(Vector2(vp.x * 0.5 + 400, vp.y * 0.3))
	caption(caps["costumes"], "top" if portrait else "left", Color.WHITE, 140, 0.1, 5.5)
	for i in seq.size():
		fr.build(seq[i])
		fr.play(anims[i])
		AudioManager.play("power" if i > 0 else "coin")
		caption(caps["c%d" % i], "bottom" if portrait else "right", Color("ffd23c"), 110, 0.0, 0.95)
		await get_tree().create_timer(1.0).timeout

func _clip_modes() -> void:
	var s: Control = _make_screen("modes", {})
	caption(caps["modes"], "top" if portrait else "left", Color.WHITE, 140, 0.2, 4.0)

func _clip_logo() -> void:
	var s: Control = _make_screen("menu", {})
	await get_tree().create_timer(0.2).timeout
	if s.frog != null:
		s.frog.play("happy")
		await get_tree().create_timer(1.6).timeout
		s.frog.play("tongue")
	caption(caps["tag"], "bottom" if portrait else "right", Color("ffd23c"), 110, 0.8, 3.0)

func _clip_cta() -> void:
	var vp: Vector2 = _vp()
	var bg := ThemeBackground.new()
	holder.add_child(bg)
	bg.apply_theme(2, 0)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/branding/wordmark.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var lw: float = 1500.0 if not portrait else 1000.0
	logo.size = Vector2(lw, lw * 0.38)
	logo.position = Vector2((vp.x - lw) * 0.5 if portrait else vp.x * 0.5 - lw * 0.5, vp.y * 0.07)
	logo.pivot_offset = logo.size * 0.5
	logo.scale = Vector2(0.4, 0.4)
	holder.add_child(logo)
	var tw: Tween = logo.create_tween()
	tw.tween_property(logo, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var pad := Sprite2D.new()
	pad.texture = load("res://assets/characters/frog_pad_back.png")
	pad.modulate = Color(0.6, 0.95, 0.7)
	pad.scale = Vector2(1.5, 1.5) if not portrait else Vector2(1.45, 1.45)
	pad.position = Vector2(vp.x * 0.5, vp.y * 0.58 + 130.0)
	holder.add_child(pad)
	var fr := Frog.new()
	fr.base_scale = 1.45 if not portrait else 1.4
	fr.position = Vector2(vp.x * 0.5, vp.y * 0.58)
	holder.add_child(fr)
	fr.build("royal")
	fr.play("happy")
	fr.look_at_point(Vector2(vp.x * 0.5, vp.y))
	var ft: Tween = fr.create_tween()
	ft.tween_interval(1.4)
	ft.tween_callback(fr.play.bind("tongue"))
	ft.tween_interval(1.6)
	ft.tween_callback(fr.play.bind("combo"))
	caption(caps["download"], "bottom", Color("ffd23c"), 150 if not portrait else 130, 0.7, 6.0, 40.0 if portrait else 120.0)
	caption(caps["store"] + "  |  " + caps["free"], "bottom", Color.WHITE, 62, 1.2, 5.5, 230.0 if portrait else 330.0)
