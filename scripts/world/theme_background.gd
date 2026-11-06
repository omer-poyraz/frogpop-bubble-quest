class_name ThemeBackground
extends Control
## Procedural layered world background: shader sky + 3 parallax decor layers + ambient particles.
## Data comes from data/themes/*.json; variation (0..2) changes layout, hue and light.

var theme_index: int = -1
var variant: int = 0
var sky: ColorRect
var layers: Array[Control] = []
var particles: CPUParticles2D
var flash: ColorRect
var _mat: ShaderMaterial
var _t: float = 0.0
var _cur_top: Color
var _cur_mid: Color
var _cur_bot: Color
var low_quality: bool = false

class DecorLayer extends Control:
	var th: Dictionary = {}
	var depth: int = 0
	var variant: int = 0
	var palette: Array[Color] = []
	var rng := RandomNumberGenerator.new()
	func setup(t: Dictionary, d: int, v: int, pal: Array[Color]) -> void:
		th = t
		depth = d
		variant = v
		palette = pal
		rng.seed = int(t["variants"][v]["seed"]) * 7 + d * 131
		queue_redraw()
	func _hills(base: float, amp: float, freq: float, col: Color, phase: float = 0.0) -> void:
		var w: float = size.x
		var h: float = size.y
		var pts := PackedVector2Array()
		var n: int = 36
		for i in n + 1:
			var x: float = w * float(i) / float(n)
			var y: float = base + sin(x * freq + phase) * amp + sin(x * freq * 2.3 + phase * 1.7) * amp * 0.4
			pts.append(Vector2(x, y))
		pts.append(Vector2(w, h))
		pts.append(Vector2(0, h))
		draw_colored_polygon(pts, col)
	func _draw() -> void:
		if th.is_empty():
			return
		var w: float = size.x
		var h: float = size.y
		var col: Color = palette[depth]
		var style: String = str(th["decor"])
		var lay: int = int(th["variants"][variant]["layout"])
		var base: float = h * (0.74 + 0.09 * depth) - lay * 14.0
		var amp: float = 26.0 + depth * 10.0 + lay * 8.0
		var phase: float = float(lay) * 1.3 + depth
		var accent: Color = Color(str(th["accent"]))
		match style:
			"forest":
				_hills(base, amp, 0.004 + lay * 0.001, col, phase)
				var count: int = 7 + depth * 2 + lay * 2
				for i in count:
					var x: float = rng.randf() * w
					var th: float = 130.0 + rng.randf() * 120.0 + depth * 50.0
					var y: float = base + sin(x * 0.004 + phase) * amp + 10
					for k in 3:
						var s: float = 1.0 - k * 0.22
						draw_colored_polygon(PackedVector2Array([Vector2(x - 60 * s, y - th * 0.3 * k), Vector2(x + 60 * s, y - th * 0.3 * k), Vector2(x, y - th * (0.45 + 0.3 * k))]), col.lightened(0.04 * k))
					draw_rect(Rect2(x - 7, y - 4, 14, 30), col.darkened(0.3))
			"candy":
				_hills(base, amp * 1.2, 0.005, col, phase)
				for i in 6 + depth * 2:
					var x2: float = rng.randf() * w
					var y2: float = base - rng.randf() * 80.0
					var r: float = 50.0 + rng.randf() * 50.0
					draw_rect(Rect2(x2 - 6, y2 - 30, 12, 140), Color(1, 1, 1, 0.5))
					draw_circle(Vector2(x2, y2 - 60), r, col.lightened(0.15))
					draw_arc(Vector2(x2, y2 - 60), r * 0.6, 0, TAU * 1.6, 32, Color(1, 1, 1, 0.55), 8.0)
					draw_arc(Vector2(x2, y2 - 60), r * 0.3, 0, TAU * 1.2, 24, Color(1, 1, 1, 0.5), 7.0)
			"ocean":
				for k in 4:
					_hills(base - k * 40.0 + 30.0, 18.0 + k * 5.0, 0.007 + k * 0.002, col.lightened(0.05 * k), phase + k)
				for i in 8 + depth * 2:
					var x3: float = rng.randf() * w
					var hh: float = 120.0 + rng.randf() * 220.0
					for j in 6:
						draw_line(Vector2(x3 + sin(j * 0.9) * 14, h - j * hh / 6.0), Vector2(x3 + sin((j + 1) * 0.9) * 14, h - (j + 1) * hh / 6.0), col.darkened(0.15), 12.0)
			"ice":
				_hills(base + 30.0, amp * 0.6, 0.004, col, phase)
				for i in 6 + depth * 2:
					var x4: float = rng.randf() * w
					var pk: float = 160.0 + rng.randf() * 280.0 + depth * 40.0
					var bw: float = 90.0 + rng.randf() * 90.0
					draw_colored_polygon(PackedVector2Array([Vector2(x4 - bw, base + 60), Vector2(x4, base + 60 - pk), Vector2(x4 + bw, base + 60)]), col.lightened(0.08))
					draw_colored_polygon(PackedVector2Array([Vector2(x4 - bw * 0.3, base + 60 - pk * 0.7), Vector2(x4, base + 60 - pk), Vector2(x4 + bw * 0.25, base + 60 - pk * 0.72)]), Color(1, 1, 1, 0.75))
			"volcano":
				_hills(base + 20.0, amp, 0.003, col, phase)
				for i in 2 + depth:
					var x5: float = w * (0.15 + 0.35 * i + rng.randf() * 0.2)
					var vh: float = 230.0 + rng.randf() * 160.0 + depth * 60.0
					draw_colored_polygon(PackedVector2Array([Vector2(x5 - 200, base + 40), Vector2(x5 - 36, base + 40 - vh), Vector2(x5 + 36, base + 40 - vh), Vector2(x5 + 200, base + 40)]), col.lightened(0.05))
					draw_colored_polygon(PackedVector2Array([Vector2(x5 - 36, base + 40 - vh), Vector2(x5 + 36, base + 40 - vh), Vector2(x5 + 10, base + 40 - vh + 70), Vector2(x5 - 18, base + 40 - vh + 120)]), accent.lerp(Color(1, 0.3, 0.1), 0.5))
					draw_circle(Vector2(x5, base + 40 - vh - 20), 26.0, Color(accent.r, accent.g, accent.b, 0.22))
			"crystal":
				_hills(base + 30.0, amp * 0.7, 0.004, col.darkened(0.1), phase)
				for i in 7 + depth * 3:
					var x6: float = rng.randf() * w
					var ch: float = 120.0 + rng.randf() * 260.0
					var cw: float = 26.0 + rng.randf() * 34.0
					var ang: float = rng.randf_range(-0.35, 0.35)
					var by: float = base + 40
					var pts := PackedVector2Array([Vector2(-cw, 0), Vector2(0, -ch), Vector2(cw, 0)])
					var tp := PackedVector2Array()
					for p in pts:
						tp.append(Vector2(x6, by) + p.rotated(ang))
					draw_colored_polygon(tp, col.lerp(accent, 0.25 + 0.2 * depth))
					draw_line(tp[1], (tp[0] + tp[2]) * 0.5, Color(1, 1, 1, 0.35), 4.0)
			"temple":
				_hills(base + 20.0, amp * 0.5, 0.003, col, phase)
				for i in 5 + depth * 2:
					var x7: float = (float(i) + rng.randf() * 0.5) * w / float(5 + depth * 2)
					var ph: float = 200.0 + rng.randf() * 140.0 + depth * 40.0
					draw_rect(Rect2(x7 - 26, base + 40 - ph, 52, ph), col.lightened(0.06))
					draw_rect(Rect2(x7 - 38, base + 40 - ph - 22, 76, 24), col.lightened(0.1))
					draw_rect(Rect2(x7 - 36, base + 36, 72, 18), col.darkened(0.15))
					for f in 3:
						draw_line(Vector2(x7 - 12 + f * 12, base + 40 - ph + 10), Vector2(x7 - 12 + f * 12, base + 30), col.darkened(0.15), 3.0)
			"mushroom":
				_hills(base + 20.0, amp, 0.004, col, phase)
				for i in 5 + depth * 2:
					var x8: float = rng.randf() * w
					var mh: float = 140.0 + rng.randf() * 160.0 + depth * 40.0
					var mr: float = 70.0 + rng.randf() * 60.0
					draw_rect(Rect2(x8 - 22, base + 30 - mh, 44, mh), Color(1, 0.95, 0.9, 0.9).darkened(0.1 * depth))
					draw_colored_polygon(_cap(Vector2(x8, base + 30 - mh), mr), col.lerp(accent, 0.35).lightened(0.05))
					for d in 4:
						draw_circle(Vector2(x8 - mr * 0.5 + d * mr * 0.33, base + 30 - mh - mr * 0.35 + (d % 2) * 14), 9.0, Color(1, 1, 1, 0.65))
			"desert":
				_hills(base - 40.0, amp * 1.6, 0.003 + lay * 0.0006, col, phase)
				_hills(base + 10.0, amp * 1.2, 0.004, col.darkened(0.08), phase + 2.0)
				for i in 3 + depth:
					var x9: float = rng.randf() * w
					var ch2: float = 70.0 + rng.randf() * 90.0
					var by2: float = base + 20.0
					draw_rect(Rect2(x9 - 10, by2 - ch2, 20, ch2), col.darkened(0.25))
					draw_rect(Rect2(x9 - 40, by2 - ch2 * 0.6, 14, ch2 * 0.35), col.darkened(0.25))
					draw_rect(Rect2(x9 - 40, by2 - ch2 * 0.35, 40, 12), col.darkened(0.25))
					draw_rect(Rect2(x9 + 26, by2 - ch2 * 0.75, 14, ch2 * 0.4), col.darkened(0.25))
					draw_rect(Rect2(x9 + 10, by2 - ch2 * 0.45, 30, 12), col.darkened(0.25))
			"galaxy":
				for i in 40 + depth * 20:
					var sx: float = rng.randf() * w
					var sy: float = rng.randf() * h
					draw_circle(Vector2(sx, sy), rng.randf_range(1.0, 3.2) * (1 + depth * 0.4), Color(1, 1, 1, rng.randf_range(0.3, 0.9)))
				if depth == 0:
					for i in 3:
						draw_circle(Vector2(w * rng.randf(), h * rng.randf_range(0.1, 0.7)), rng.randf_range(160, 320), Color(accent.r, accent.g, accent.b, 0.06))
				if depth >= 1:
					var px: float = w * (0.2 + 0.6 * rng.randf())
					var py: float = h * (0.12 + 0.2 * rng.randf() + 0.2 * depth)
					var pr: float = 60.0 + 40.0 * depth + lay * 16.0
					draw_circle(Vector2(px, py), pr, col.lightened(0.15))
					draw_circle(Vector2(px - pr * 0.25, py - pr * 0.25), pr * 0.7, col.lightened(0.28))
					draw_arc(Vector2(px, py), pr * 1.7, PI * 0.1, PI * 0.9, 40, accent.darkened(0.2), 10.0)
					draw_arc(Vector2(px, py), pr * 1.7, PI * 1.1, PI * 1.9, 40, accent.darkened(0.2), 10.0)
		# variation 2: horizon glow line
		if lay == 2 and depth == 2:
			draw_rect(Rect2(0, h - 80, w, 80), Color(accent.r, accent.g, accent.b, 0.08))
	func _cap(c: Vector2, r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 21:
			var a: float = PI + PI * float(i) / 20.0
			pts.append(c + Vector2(cos(a) * r, sin(a) * r * 0.75))
		pts.append(c + Vector2(r, 8))
		pts.append(c + Vector2(-r, 8))
		return pts

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	sky = ColorRect.new()
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/bg_gradient.gdshader")
	sky.material = _mat
	add_child(sky)
	for i in 3:
		var l := DecorLayer.new()
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(l)
		layers.append(l)
	particles = CPUParticles2D.new()
	particles.z_index = 1
	add_child(particles)
	flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(1, 1, 1, 0)
	add_child(flash)
	resized.connect(_on_resized)
	low_quality = SettingsManager.quality == 0

func _on_resized() -> void:
	if theme_index >= 0:
		for l in layers:
			l.queue_redraw()
		_place_particles()

func _hue_shift(c: Color, v: Dictionary) -> Color:
	var hh: float = fposmod(c.h + float(v["hue_shift"]), 1.0)
	var out: Color = Color.from_hsv(hh, c.s, clampf(c.v + float(v["light"]), 0.0, 1.0))
	return out

func apply_theme(idx: int, var_idx: int, animate: bool = false) -> void:
	var th: Dictionary = ThemeManager.get_theme(idx)
	if th.is_empty():
		return
	var v: Dictionary = th["variants"][var_idx % 3]
	var top: Color = _hue_shift(Color(str(th["sky"][0])), v)
	var mid: Color = _hue_shift(Color(str(th["sky"][1])), v)
	var bot: Color = _hue_shift(Color(str(th["sky"][2])), v)
	theme_index = idx
	variant = var_idx % 3
	var base_dark: Color = mid.darkened(0.45)
	var pal: Array[Color] = [mid.lerp(bot, 0.35).darkened(0.18), mid.darkened(0.32), top.darkened(0.5)]
	for i in layers.size():
		(layers[i] as DecorLayer).setup(th, i, variant, pal)
	if animate:
		var from_top: Color = _cur_top
		var from_mid: Color = _cur_mid
		var from_bot: Color = _cur_bot
		var tw: Tween = create_tween()
		tw.tween_method(func(k: float) -> void: _set_sky(from_top.lerp(top, k), from_mid.lerp(mid, k), from_bot.lerp(bot, k)), 0.0, 1.0, 1.2)
		var tf: Tween = create_tween()
		flash.color = Color(1, 1, 1, 0.0)
		tf.tween_property(flash, "color:a", 0.7, 0.25)
		tf.tween_property(flash, "color:a", 0.0, 0.7)
	else:
		_set_sky(top, mid, bot)
	_mat.set_shader_parameter("light", float(v["light"]) * 0.2)
	_mat.set_shader_parameter("bands", 0.2 if low_quality else 0.55)
	_setup_particles(th)

func _set_sky(top: Color, mid: Color, bot: Color) -> void:
	_cur_top = top
	_cur_mid = mid
	_cur_bot = bot
	_mat.set_shader_parameter("top", top)
	_mat.set_shader_parameter("mid", mid)
	_mat.set_shader_parameter("bottom", bot)

func _place_particles() -> void:
	var s: Vector2 = size
	var kind: String = str(ThemeManager.get_theme(theme_index)["particles"]["type"])
	if kind in ["bubbles", "embers", "spores"]:
		particles.position = Vector2(s.x * 0.5, s.y + 20)
	else:
		particles.position = Vector2(s.x * 0.5, -20)
	particles.emission_rect_extents = Vector2(s.x * 0.55, 10)

func _setup_particles(th: Dictionary) -> void:
	var p: Dictionary = th["particles"]
	var kind: String = str(p["type"])
	var col: Color = Color(str(p["color"]))
	particles.emitting = false
	particles.amount = maxi(int(float(p["count"]) * SettingsManager.particle_scale()), 6)
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.lifetime = 9.0
	particles.preprocess = 9.0
	particles.color = col
	particles.spread = 25.0
	particles.angular_velocity_min = -40.0
	particles.angular_velocity_max = 40.0
	particles.gravity = Vector2.ZERO
	var tex_name: String = "spark"
	match kind:
		"leaves":
			tex_name = "shard"; particles.direction = Vector2(0.3, 1); particles.initial_velocity_min = 50; particles.initial_velocity_max = 110; particles.scale_amount_min = 0.5; particles.scale_amount_max = 1.2
		"snow":
			tex_name = "spark"; particles.direction = Vector2(0.15, 1); particles.initial_velocity_min = 40; particles.initial_velocity_max = 100; particles.scale_amount_min = 0.35; particles.scale_amount_max = 0.9
		"bubbles":
			tex_name = "ring"; particles.direction = Vector2(0, -1); particles.initial_velocity_min = 40; particles.initial_velocity_max = 110; particles.scale_amount_min = 0.15; particles.scale_amount_max = 0.5
		"embers":
			tex_name = "spark"; particles.direction = Vector2(0.1, -1); particles.initial_velocity_min = 70; particles.initial_velocity_max = 160; particles.scale_amount_min = 0.3; particles.scale_amount_max = 0.9
		"spores":
			tex_name = "glow"; particles.direction = Vector2(0, -1); particles.initial_velocity_min = 25; particles.initial_velocity_max = 70; particles.scale_amount_min = 0.2; particles.scale_amount_max = 0.55
		"dust":
			tex_name = "glow"; particles.direction = Vector2(1, 0.3); particles.initial_velocity_min = 30; particles.initial_velocity_max = 80; particles.scale_amount_min = 0.15; particles.scale_amount_max = 0.45
		"stars":
			tex_name = "sparkle"; particles.direction = Vector2(0.1, 1); particles.initial_velocity_min = 10; particles.initial_velocity_max = 40; particles.scale_amount_min = 0.15; particles.scale_amount_max = 0.5
		_:
			tex_name = "sparkle"; particles.direction = Vector2(0, 1); particles.initial_velocity_min = 25; particles.initial_velocity_max = 70; particles.scale_amount_min = 0.2; particles.scale_amount_max = 0.6
	particles.texture = load("res://assets/particles/%s.png" % tex_name)
	_place_particles()
	particles.emitting = true

func _process(delta: float) -> void:
	_t += delta
	for i in layers.size():
		(layers[i] as Control).position.x = sin(_t * (0.05 + 0.03 * i)) * (10.0 + 14.0 * i)
