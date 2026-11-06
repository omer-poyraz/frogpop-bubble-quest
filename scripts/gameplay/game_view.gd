class_name GameView
extends Node2D
## Renders a GameCore: track, chain (pooled sprites), projectiles, ammo, aim line, dying balls.

const BALL_TEX_SIZE: float = 192.0
const DRAW_SCALE: float = (K.BALL_D + 6.0) / BALL_TEX_SIZE

var core: GameCore
var fx: FxLayer
var fx_add: FxLayer
var theme_idx: int = 0
var track: Node2D
var balls_layer: Node2D
var proj_layer: Node2D
var ammo_layer: Node2D
var aim: Node2D
var frog: Frog

var _mat: ShaderMaterial
var _rainbow_mat: ShaderMaterial
var _tex_cache: Dictionary = {}
var _views: Dictionary = {}          # ball id -> {node, disp_s, off, born, sym, gold}
var _pool: Array[Sprite2D] = []
var _proj: Dictionary = {}           # projectile (instance id) -> Sprite2D
var _dying: Array = []               # {node, t, delay, color, pos, kind}
var aim_target: Vector2 = Vector2.ZERO
var aim_visible: bool = false
var ammo_cur: Sprite2D
var ammo_next: Sprite2D
var ammo_cur_sym: Sprite2D
var ammo_next_sym: Sprite2D
var time: float = 0.0
var pad: Sprite2D
var colorblind: bool = false
var shown_bomb_ammo: bool = false

func setup(p_core: GameCore) -> void:
	core = p_core
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/bubble.gdshader")
	_rainbow_mat = ShaderMaterial.new()
	_rainbow_mat.shader = load("res://shaders/rainbow.gdshader")
	track = TrackView.new()
	add_child(track)
	pad = Sprite2D.new()
	pad.texture = load("res://assets/characters/frog_pad_back.png")
	pad.centered = true
	pad.scale = Vector2(0.64, 0.64)
	add_child(pad)
	frog = Frog.new()
	add_child(frog)
	balls_layer = Node2D.new()
	add_child(balls_layer)
	proj_layer = Node2D.new()
	add_child(proj_layer)
	ammo_layer = Node2D.new()
	add_child(ammo_layer)
	aim = AimLine.new()
	aim.view = self
	add_child(aim)
	fx = FxLayer.new()
	add_child(fx)
	fx_add = FxLayer.new()
	fx_add.additive = true
	add_child(fx_add)
	ammo_cur = _mk_sprite(ammo_layer)
	ammo_next = _mk_sprite(ammo_layer)
	ammo_cur_sym = _mk_sprite(ammo_layer)
	ammo_next_sym = _mk_sprite(ammo_layer)

func _mk_sprite(parent: Node) -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = true
	s.material = _mat
	parent.add_child(s)
	return s

func tex_for(color: int, kind: int = 0, hp: int = 2) -> Texture2D:
	var key: String = ""
	if kind == K.KIND_BOMB:
		key = "ball_bomb"
	elif kind == K.KIND_STONE:
		key = "ball_stone" if hp >= 2 else "ball_stone_cracked"
	elif color == K.RAINBOW:
		key = "ball_rainbow"
	else:
		key = "ball_%d" % clampi(color, 0, 7)
	if not _tex_cache.has(key):
		_tex_cache[key] = load("res://assets/bubbles/%s.png" % key)
	return _tex_cache[key]

func sym_tex(color: int) -> Texture2D:
	var key: String = "sym_%d" % clampi(color, 0, 7)
	if not _tex_cache.has(key):
		_tex_cache[key] = load("res://assets/bubbles/%s.png" % key)
	return _tex_cache[key]

func on_new_wave(theme: Dictionary) -> void:
	for id in _views:
		_release(_views[id]["node"])
	_views.clear()
	for k in _proj:
		(_proj[k] as Sprite2D).queue_free()
	_proj.clear()
	(track as TrackView).set_path(core.path, theme)
	pad.position = core.frog_pos + Vector2(0, 62)
	var accent: Color = Color(str(theme.get("accent", "#ffffff")))
	pad.modulate = Color(0.55, 0.9, 0.65).lerp(accent, 0.25)
	frog.position = core.frog_pos - frog.mouth_offset()
	if frog.nodes.is_empty():
		frog.build(ProgressionManager.selected_skin())
	colorblind = SettingsManager.colorblind

func _acquire() -> Sprite2D:
	var s: Sprite2D
	if _pool.is_empty():
		s = Sprite2D.new()
		s.centered = true
		s.material = _mat
		s.scale = Vector2(DRAW_SCALE, DRAW_SCALE)
		var sym := Sprite2D.new()
		sym.name = "sym"
		sym.scale = Vector2(0.55, 0.55)
		sym.visible = false
		s.add_child(sym)
		var gold := Sprite2D.new()
		gold.name = "gold"
		gold.texture = load("res://assets/bubbles/gold_ring.png")
		gold.visible = false
		s.add_child(gold)
	else:
		s = _pool.pop_back()
	s.visible = true
	s.modulate = Color.WHITE
	s.rotation = 0.0
	s.scale = Vector2(DRAW_SCALE, DRAW_SCALE)
	if s.get_parent() == null:
		balls_layer.add_child(s)
	return s

func _release(s: Sprite2D) -> void:
	s.visible = false
	_pool.append(s)

func squash(id: int, amount: float = 0.28) -> void:
	if _views.has(id):
		_views[id]["squash"] = amount

func ball_inserted(b: Ball, from_world: Vector2) -> void:
	var v: Dictionary = _ensure_view(b)
	var slot: Vector2 = core.path.pos_at(b.s)
	v["off"] = from_world - slot
	v["squash"] = 0.3
	v["disp_s"] = b.s

func _ensure_view(b: Ball) -> Dictionary:
	if _views.has(b.id):
		return _views[b.id]
	var s: Sprite2D = _acquire()
	var v: Dictionary = {"node": s, "disp_s": b.s, "off": Vector2.ZERO, "squash": 0.0, "kind": -1, "hp": -1, "color": -99}
	_views[b.id] = v
	return v

func _apply_look(v: Dictionary, b: Ball) -> void:
	var s: Sprite2D = v["node"]
	if v["kind"] != b.kind or v["hp"] != b.hp or v["color"] != b.color:
		v["kind"] = b.kind
		v["hp"] = b.hp
		v["color"] = b.color
		s.texture = tex_for(b.color, b.kind, b.hp)
		s.material = _rainbow_mat if b.color == K.RAINBOW else _mat
		var sym: Sprite2D = s.get_node("sym")
		sym.texture = sym_tex(b.color) if b.color >= 0 and b.color < 8 and b.kind == K.KIND_NORMAL else null
		var gold: Sprite2D = s.get_node("gold")
		gold.visible = b.golden
	(s.get_node("sym") as Sprite2D).visible = colorblind and b.kind == K.KIND_NORMAL and b.color >= 0

func spawn_death(pos: Vector2, color: int, delay: float, kind: int, golden: bool) -> void:
	var s: Sprite2D = _acquire()
	s.texture = tex_for(color, kind, 2)
	s.material = _rainbow_mat if color == K.RAINBOW else _mat
	s.position = pos
	(s.get_node("sym") as Sprite2D).visible = false
	(s.get_node("gold") as Sprite2D).visible = golden
	_dying.append({"node": s, "t": -delay, "color": color, "pos": pos, "kind": kind, "done": false})

func _process(delta: float) -> void:
	if core == null:
		return
	time += delta
	_sync_chain(delta)
	_sync_projectiles(delta)
	_sync_dying(delta)
	_sync_ammo()

func _sync_chain(delta: float) -> void:
	var path: PathData = core.path
	var seen: Dictionary = {}
	var danger_s: float = path.length * 0.82
	var k_smooth: float = 1.0 - exp(-delta * 24.0)
	var k_off: float = 1.0 - exp(-delta * 18.0)
	for b in core.chain.balls:
		var bb: Ball = b
		seen[bb.id] = true
		var v: Dictionary = _ensure_view(bb)
		_apply_look(v, bb)
		var ds: float = v["disp_s"]
		if absf(bb.s - ds) > 160.0:
			ds = bb.s
		else:
			ds = lerpf(ds, bb.s, k_smooth)
		v["disp_s"] = ds
		v["off"] = (v["off"] as Vector2) * (1.0 - k_off)
		var s: Sprite2D = v["node"]
		s.position = path.pos_at(ds) + (v["off"] as Vector2)
		var sq: float = v["squash"]
		if sq > 0.001:
			v["squash"] = sq * (1.0 - delta * 11.0)
			var sc: float = DRAW_SCALE
			s.scale = Vector2(sc * (1.0 + sq), sc * (1.0 - sq * 0.8))
		else:
			s.scale = Vector2(DRAW_SCALE, DRAW_SCALE)
		# idle floating
		s.position.y += sin(time * 2.0 + float(bb.id) * 0.7) * 1.4
		# hidden until it enters the field
		s.visible = true
		if bb.s > danger_s:
			s.modulate = Color(1.0, 0.88, 0.88)
		else:
			s.modulate = Color.WHITE
		if bb.golden:
			var g: Sprite2D = s.get_node("gold")
			g.rotation = time * 1.2
			g.scale = Vector2.ONE * (1.0 + 0.06 * sin(time * 5.0 + float(bb.id)))
	# release views of removed balls
	var dead: Array = []
	for id in _views:
		if not seen.has(id):
			dead.append(id)
	for id in dead:
		_release(_views[id]["node"])
		_views.erase(id)

func _sync_projectiles(_delta: float) -> void:
	var live: Dictionary = {}
	for pr in core.projectiles:
		var key: int = hash(pr)
		live[key] = true
		var s: Sprite2D
		if _proj.has(key):
			s = _proj[key]
		else:
			s = Sprite2D.new()
			s.texture = tex_for(pr["color"] if not pr["bomb"] else 0, K.KIND_BOMB if pr["bomb"] else K.KIND_NORMAL)
			s.material = _rainbow_mat if pr["color"] == K.RAINBOW else _mat
			s.scale = Vector2(DRAW_SCALE * 0.95, DRAW_SCALE * 0.95)
			proj_layer.add_child(s)
			_proj[key] = s
		s.position = pr["pos"]
		if randf() < 0.9:
			fx_add.trail(pr["pos"], K.color_of(pr["color"]) if pr["color"] < 8 else Color.WHITE)
	var rm: Array = []
	for k in _proj:
		if not live.has(k):
			rm.append(k)
	for k in rm:
		(_proj[k] as Sprite2D).queue_free()
		_proj.erase(k)

func _sync_dying(delta: float) -> void:
	var keep: Array = []
	for d in _dying:
		d["t"] += delta
		var t: float = d["t"]
		var s: Sprite2D = d["node"]
		if t < 0.0:
			keep.append(d)
			continue
		# grow, flash, squash then vanish (burst particles are emitted by the screen)
		var k: float = clampf(t / 0.14, 0.0, 1.0)
		var sc: float = DRAW_SCALE * (1.0 + 0.3 * sin(k * PI * 0.5))
		s.scale = Vector2(sc * (1.0 + 0.15 * k), sc * (1.0 - 0.12 * k))
		s.modulate = Color(1.0 + k, 1.0 + k, 1.0 + k, 1.0 - k * k)
		if k >= 1.0:
			_release(s)
		else:
			keep.append(d)
	_dying = keep

func _sync_ammo() -> void:
	var mouth: Vector2 = core.frog_pos
	var bob: float = sin(time * 3.0) * 2.0
	var can: bool = core.reload <= 0.0
	ammo_cur.texture = tex_for(core.ammo, K.KIND_BOMB if core.power.bomb_armed else 0)
	ammo_cur.material = _rainbow_mat if core.ammo == K.RAINBOW and not core.power.bomb_armed else _mat
	ammo_cur.position = mouth + Vector2(0, bob - 2)
	var ap: float = 0.8 if can else 0.35
	ammo_cur.scale = Vector2(DRAW_SCALE * ap, DRAW_SCALE * ap)
	ammo_cur.modulate.a = 1.0 if can else 0.6
	ammo_next.texture = tex_for(core.ammo_next)
	ammo_next.material = _rainbow_mat if core.ammo_next == K.RAINBOW else _mat
	ammo_next.position = core.frog_pos + Vector2(108, 86)
	ammo_next.scale = Vector2(DRAW_SCALE * 0.46, DRAW_SCALE * 0.46)
	for pair in [[ammo_cur_sym, core.ammo, ap * 0.55, ammo_cur.position], [ammo_next_sym, core.ammo_next, 0.26, ammo_next.position]]:
		var sy: Sprite2D = pair[0]
		var c: int = pair[1]
		sy.visible = colorblind and c >= 0 and c < 8 and not (pair[0] == ammo_cur_sym and core.power.bomb_armed)
		if sy.visible:
			sy.texture = sym_tex(c)
			sy.position = pair[3]
			sy.scale = Vector2(pair[2], pair[2])

## First ball hit along the aim ray (for the aim line). Returns end point.
func aim_end(from: Vector2, dir: Vector2) -> Vector2:
	var far: Vector2 = from + dir * 2600.0
	if core.chain.balls.is_empty():
		return far
	var poss := PackedVector2Array()
	for b in core.chain.balls:
		poss.append(core.path.pos_at((b as Ball).s))
	var hit: Dictionary = core.chain.segment_hit(from, far, poss)
	if hit.is_empty():
		return far
	return from.lerp(far, hit["t"])

class AimLine extends Node2D:
	var view: GameView
	func _process(_d: float) -> void:
		queue_redraw()
	func _draw() -> void:
		if view == null or not view.aim_visible or view.core.state == GameCore.State.LOST or not SettingsManager.get_setting("aim_line"):
			return
		var from: Vector2 = view.core.frog_pos
		var d: Vector2 = view.aim_target - from
		if d.length() < 30.0:
			return
		var dir: Vector2 = d.normalized()
		var end: Vector2 = view.aim_end(from + dir * 70.0, dir)
		var col: Color = K.color_of(view.core.ammo) if view.core.ammo < 8 else Color.WHITE
		var total: float = from.distance_to(end)
		var step: float = 34.0
		var n: int = int(total / step)
		for i in range(2, n):
			var p: Vector2 = from + dir * (float(i) * step - fmod(view.time * 60.0, step))
			var a: float = 0.75 * (1.0 - float(i) / float(maxi(n, 1)) * 0.6)
			draw_circle(p, 6.5, Color(col.r, col.g, col.b, a))
			draw_circle(p, 3.0, Color(1, 1, 1, a * 0.8))
		draw_arc(end, K.BALL_R * 0.9, 0, TAU, 32, Color(1, 1, 1, 0.65), 4.0)

class TrackView extends Node2D:
	var path: PathData
	var theme: Dictionary = {}
	func set_path(p: PathData, th: Dictionary) -> void:
		path = p
		theme = th
		queue_redraw()
	func _draw() -> void:
		if path == null:
			return
		var pts := PackedVector2Array()
		var i: int = 0
		while i < path.pts.size():
			pts.append(path.pts[i])
			i += 3
		pts.append(path.pts[path.pts.size() - 1])
		var edge: Color = Color(str(theme.get("track_edge", "#222222")))
		var tr: Color = Color(str(theme.get("track", "#444444")))
		var accent: Color = Color(str(theme.get("accent", "#ffffff")))
		draw_polyline(pts, Color(0, 0, 0, 0.22), K.BALL_D + 44.0, true)
		draw_polyline(pts, edge, K.BALL_D + 30.0, true)
		draw_polyline(pts, tr.darkened(0.12), K.BALL_D + 16.0, true)
		draw_polyline(pts, tr, K.BALL_D - 4.0, true)
		draw_polyline(pts, Color(1, 1, 1, 0.06), K.BALL_D * 0.5, true)
		# dotted centre line
		var s: float = path.enter_s
		while s < path.length:
			draw_circle(path.pos_at(s), 3.0, Color(accent.r, accent.g, accent.b, 0.22))
			s += 46.0
		# hole
		var end: Vector2 = path.pos_at(path.length)
		var dir: Vector2 = path.tangent_at(path.length)
		draw_circle(end, 62.0, Color(0, 0, 0, 0.5))
		draw_circle(end, 52.0, Color("0b0a14"))
		draw_arc(end, 54.0, 0, TAU, 40, accent, 6.0)
		draw_circle(end, 30.0, Color("1d1a33"))
		draw_arc(end, 66.0, 0, TAU, 40, Color(accent.r, accent.g, accent.b, 0.35), 4.0)
		var perp: Vector2 = dir.orthogonal()
		draw_colored_polygon(PackedVector2Array([end - dir * 18 + perp * 16, end + dir * 22, end - dir * 18 - perp * 16]), Color(accent.r, accent.g, accent.b, 0.55))
