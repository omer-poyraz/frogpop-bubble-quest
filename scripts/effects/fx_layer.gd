class_name FxLayer
extends Node2D
## Pooled particle system drawn in a single CanvasItem (no per-particle nodes).
## Fixed-size pool; oldest particle is recycled when the pool is full.

const MAX: int = 700
const TEX_NAMES: Array[String] = ["spark", "star", "sparkle", "shard", "ring", "glow"]

var textures: Array[Texture2D] = []
var additive: bool = false
var budget_scale: float = 1.0

# struct-of-arrays pool
var _pos: PackedVector2Array = PackedVector2Array()
var _vel: PackedVector2Array = PackedVector2Array()
var _life: PackedFloat32Array = PackedFloat32Array()
var _max_life: PackedFloat32Array = PackedFloat32Array()
var _size: PackedFloat32Array = PackedFloat32Array()
var _grow: PackedFloat32Array = PackedFloat32Array()
var _rot: PackedFloat32Array = PackedFloat32Array()
var _rvel: PackedFloat32Array = PackedFloat32Array()
var _grav: PackedFloat32Array = PackedFloat32Array()
var _drag: PackedFloat32Array = PackedFloat32Array()
var _col: PackedColorArray = PackedColorArray()
var _tex: PackedInt32Array = PackedInt32Array()
var _next: int = 0
var active: int = 0

func _ready() -> void:
	for n in TEX_NAMES:
		textures.append(load("res://assets/particles/%s.png" % n))
	_pos.resize(MAX); _vel.resize(MAX); _life.resize(MAX); _max_life.resize(MAX); _size.resize(MAX)
	_grow.resize(MAX); _rot.resize(MAX); _rvel.resize(MAX); _grav.resize(MAX); _drag.resize(MAX)
	_col.resize(MAX); _tex.resize(MAX)
	for i in MAX:
		_life[i] = 0.0
	if additive:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m
	budget_scale = SettingsManager.particle_scale()

func emit(tex: int, pos: Vector2, vel: Vector2, life: float, size: float, color: Color, grow: float = 0.0, grav: float = 0.0, rot: float = 0.0, rvel: float = 0.0, drag: float = 0.0) -> void:
	var i: int = _next
	_next = (_next + 1) % MAX
	_tex[i] = tex
	_pos[i] = pos
	_vel[i] = vel
	_life[i] = life
	_max_life[i] = life
	_size[i] = size
	_grow[i] = grow
	_rot[i] = rot
	_rvel[i] = rvel
	_grav[i] = grav
	_drag[i] = drag
	_col[i] = color

func clear() -> void:
	for i in MAX:
		_life[i] = 0.0
	active = 0
	queue_redraw()

func _process(delta: float) -> void:
	var n: int = 0
	for i in MAX:
		var l: float = _life[i]
		if l <= 0.0:
			continue
		l -= delta
		_life[i] = l
		if l <= 0.0:
			continue
		n += 1
		var v: Vector2 = _vel[i]
		v.y += _grav[i] * delta
		if _drag[i] > 0.0:
			v *= maxf(1.0 - _drag[i] * delta, 0.0)
		_vel[i] = v
		_pos[i] += v * delta
		_rot[i] += _rvel[i] * delta
		_size[i] = maxf(_size[i] + _grow[i] * delta, 0.0)
	active = n
	if n > 0 or _was_active:
		queue_redraw()
	_was_active = n > 0

var _was_active: bool = false

func _draw() -> void:
	for i in MAX:
		var l: float = _life[i]
		if l <= 0.0:
			continue
		var k: float = l / _max_life[i]
		var c: Color = _col[i]
		c.a *= minf(k * 2.5, 1.0)
		var t: Texture2D = textures[_tex[i]]
		var s: float = _size[i]
		draw_set_transform(_pos[i], _rot[i], Vector2.ONE)
		draw_texture_rect(t, Rect2(-s * 0.5, -s * 0.5, s, s), false, c)

# ---------------- high level effects ----------------

func burst_pop(pos: Vector2, color: Color, intensity: float = 1.0) -> void:
	var sc: float = budget_scale
	var n: int = maxi(int(8.0 * intensity * sc), 3)
	for i in n:
		var a: float = randf() * TAU
		var sp: float = randf_range(220.0, 620.0) * (0.8 + 0.3 * intensity)
		emit(3, pos, Vector2(cos(a), sin(a)) * sp, randf_range(0.35, 0.7), randf_range(18.0, 34.0), color.lightened(randf_range(0.0, 0.3)), -20.0, 900.0, randf() * TAU, randf_range(-9.0, 9.0), 1.2)
	var ns: int = maxi(int(3.0 * intensity * sc), 1)
	for i in ns:
		var a2: float = randf() * TAU
		emit(1, pos, Vector2(cos(a2), sin(a2)) * randf_range(120.0, 380.0), randf_range(0.45, 0.8), randf_range(30.0, 56.0), Color(1, 0.95, 0.6), -25.0, 200.0, randf() * TAU, randf_range(-5.0, 5.0), 1.5)
	for i in maxi(int(5.0 * sc), 2):
		var a3: float = randf() * TAU
		emit(0, pos, Vector2(cos(a3), sin(a3)) * randf_range(60.0, 320.0), randf_range(0.25, 0.5), randf_range(26.0, 46.0), color.lightened(0.5), -40.0, 0.0, 0.0, 0.0, 2.0)
	emit(5, pos, Vector2.ZERO, 0.28, 120.0 * intensity, color.lightened(0.4), 520.0)
	emit(4, pos, Vector2.ZERO, 0.32, 40.0, Color(1, 1, 1, 0.9), 560.0 * intensity)

func burst_stars(pos: Vector2, color: Color, count: int = 12, speed: float = 520.0) -> void:
	var n: int = maxi(int(float(count) * budget_scale), 4)
	for i in n:
		var a: float = randf() * TAU
		emit(1 if i % 2 == 0 else 2, pos, Vector2(cos(a), sin(a)) * randf_range(speed * 0.4, speed), randf_range(0.5, 1.0), randf_range(34.0, 70.0), color, -30.0, 300.0, randf() * TAU, randf_range(-6.0, 6.0), 1.4)

func muzzle_flash(pos: Vector2, color: Color) -> void:
	emit(5, pos, Vector2.ZERO, 0.18, 150.0, Color(1, 1, 1, 0.95), 220.0)
	emit(4, pos, Vector2.ZERO, 0.24, 30.0, color.lightened(0.5), 420.0)
	for i in maxi(int(6.0 * budget_scale), 2):
		var a: float = randf() * TAU
		emit(0, pos, Vector2(cos(a), sin(a)) * randf_range(120.0, 340.0), 0.3, 28.0, color.lightened(0.5), -50.0, 0.0, 0.0, 0.0, 3.0)

func trail(pos: Vector2, color: Color) -> void:
	emit(5, pos, Vector2(randf_range(-30, 30), randf_range(-30, 30)), 0.28, 56.0, Color(color.r, color.g, color.b, 0.5), -140.0)

func shockwave(pos: Vector2, color: Color, size: float = 60.0, grow: float = 900.0) -> void:
	emit(4, pos, Vector2.ZERO, 0.45, size, color, grow)

func confetti(pos: Vector2, count: int = 30) -> void:
	var cols: Array[Color] = K.BALL_COLORS
	var n: int = maxi(int(float(count) * budget_scale), 6)
	for i in n:
		var a: float = randf_range(-PI * 0.95, -PI * 0.05)
		emit(3, pos, Vector2(cos(a), sin(a)) * randf_range(300.0, 900.0), randf_range(0.9, 1.7), randf_range(16.0, 30.0), cols[i % cols.size()], 0.0, 900.0, randf() * TAU, randf_range(-10.0, 10.0), 0.6)

func lightning_bolt(points: PackedVector2Array) -> void:
	for p in points:
		emit(5, p, Vector2.ZERO, 0.4, 200.0, Color(1, 0.95, 0.5, 0.9), 300.0)
		emit(1, p, Vector2(randf_range(-200, 200), randf_range(-200, 200)), 0.6, 60.0, Color(1, 1, 0.7), -60.0, 0.0, randf() * TAU, 3.0)
