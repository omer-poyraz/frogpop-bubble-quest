class_name Frog
extends Node2D
## Layered animated mascot. Parts are stacked sprites sharing one origin (see tools/art/frog_svg.py).
## 12 animations are built in code on an AnimationPlayer. Eyes track a target position.

const A: String = "res://assets/characters/"
const IMG_W: float = 512.0
const IMG_H: float = 576.0
const CENTER: Vector2 = Vector2(256, 300)
const MOUTH: Vector2 = Vector2(256, 64 + 292)
const NECK: Vector2 = Vector2(256, 64 + 300)
const HIP: Vector2 = Vector2(256, 64 + 440)
const EYE_L: Vector2 = Vector2(190, 64 + 150)
const EYE_R: Vector2 = Vector2(322, 64 + 150)
const SHOULDER_L: Vector2 = Vector2(150, 64 + 330)
const SHOULDER_R: Vector2 = Vector2(362, 64 + 330)
const ANIMS: Array[String] = ["idle", "breathing", "blink", "happy", "shooting", "tongue", "excited", "combo", "damage", "game_over", "victory", "special"]

var costume: String = "classic"
var nodes: Dictionary = {}
var player: AnimationPlayer
var blinker: AnimationPlayer
var lean: Node2D
var torso: Node2D
var head: Node2D
var look_target: Vector2 = Vector2.ZERO
var has_target: bool = false
var look_strength: float = 11.0
var base_scale: float = 0.64
var _blink_t: float = 2.0
var _breath_started: bool = false
var state: String = "idle"
var _hold_state: bool = false
var _t: float = 0.0
var pad_tint: Color = Color.WHITE

func _ready() -> void:
	pass

## Mouth position in this node's parent space (where bubbles leave).
func mouth_offset() -> Vector2:
	return (MOUTH - CENTER) * base_scale

static func _tex(n: String) -> Texture2D:
	return load(A + n + ".png")

func _node(name: String, parent: Node2D, pivot: Vector2, parent_pivot: Vector2) -> Node2D:
	var n := Node2D.new()
	n.name = name
	n.position = pivot - parent_pivot
	parent.add_child(n)
	nodes[name] = n
	return n

func _spr(name: String, tex_name: String, parent: Node2D, pivot: Vector2, vis: bool = true) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = name
	s.texture = _tex(tex_name)
	s.centered = false
	s.offset = -pivot
	s.visible = vis
	parent.add_child(s)
	nodes[name] = s
	return s

func build(costume_id: String = "classic") -> void:
	for c in get_children():
		c.queue_free()
	nodes.clear()
	costume = costume_id
	scale = Vector2(base_scale, base_scale)
	var has_cos: bool = costume_id != "classic" and costume_id != ""
	lean = Node2D.new()
	lean.name = "lean"
	lean.position = Vector2.ZERO
	add_child(lean)
	# everything below is positioned relative to CENTER (root origin); pivots are absolute image coords
	var z := Node2D.new()
	z.name = "img"
	z.position = -CENTER
	lean.add_child(z)
	_spr("shadow", "frog_shadow", z, Vector2.ZERO)
	if has_cos:
		_spr("cos_back", "costume_%s_back" % costume_id, z, Vector2.ZERO)
	_spr("aura", "frog_aura", z, Vector2.ZERO, false)
	_spr("leg_l", "frog_leg_l", z, Vector2.ZERO)
	_spr("leg_r", "frog_leg_r", z, Vector2.ZERO)
	torso = _node("torso", z, HIP, Vector2.ZERO)
	_spr("body", "frog_body", torso, HIP)
	_spr("belly", "frog_belly", torso, HIP)
	if has_cos:
		_spr("cos_body", "costume_%s_body" % costume_id, torso, HIP)
	var arm_l: Node2D = _node("arm_l", torso, SHOULDER_L, HIP)
	_spr("arm_l_s", "frog_arm_l", arm_l, SHOULDER_L)
	var arm_r: Node2D = _node("arm_r", torso, SHOULDER_R, HIP)
	_spr("arm_r_s", "frog_arm_r", arm_r, SHOULDER_R)
	head = _node("head", z, NECK, Vector2.ZERO)
	_spr("head_s", "frog_head", head, NECK)
	_spr("cheek_l", "frog_cheek_l", head, NECK)
	_spr("cheek_r", "frog_cheek_r", head, NECK)
	_spr("eye_l", "frog_eye_l", head, NECK)
	_spr("eye_r", "frog_eye_r", head, NECK)
	var pl: Node2D = _node("pupil_l", head, EYE_L, NECK)
	_spr("pupil_l_s", "frog_pupil_l", pl, EYE_L)
	var pr: Node2D = _node("pupil_r", head, EYE_R, NECK)
	_spr("pupil_r_s", "frog_pupil_r", pr, EYE_R)
	var ll: Node2D = _node("lid_l", head, EYE_L + Vector2(0, -62), NECK)
	_spr("lid_l_s", "frog_lid_l", ll, EYE_L + Vector2(0, -62))
	var lr: Node2D = _node("lid_r", head, EYE_R + Vector2(0, -62), NECK)
	_spr("lid_r_s", "frog_lid_r", lr, EYE_R + Vector2(0, -62))
	ll.scale = Vector2(1, 0.001)
	lr.scale = Vector2(1, 0.001)
	_spr("happy_l", "frog_happy_l", head, NECK, false)
	_spr("happy_r", "frog_happy_r", head, NECK, false)
	_spr("mouth_smile", "frog_mouth_smile", head, NECK)
	_spr("mouth_open", "frog_mouth_open", head, NECK, false)
	_spr("mouth_o", "frog_mouth_o", head, NECK, false)
	_spr("mouth_sad", "frog_mouth_sad", head, NECK, false)
	var tg: Node2D = _node("tongue", head, MOUTH, NECK)
	_spr("tongue_s", "frog_tongue", tg, MOUTH)
	tg.scale = Vector2(1, 0.001)
	tg.visible = false
	if has_cos:
		_spr("cos_head", "costume_%s_head" % costume_id, head, NECK)
	_build_animations()
	reset_pose()
	play("idle")

func reset_pose() -> void:
	lean.modulate = Color.WHITE
	lean.rotation = 0.0
	torso.scale = Vector2.ONE
	torso.rotation = 0.0
	torso.position = HIP - Vector2.ZERO
	head.position = NECK
	head.rotation = 0.0
	head.scale = Vector2.ONE
	for n in ["arm_l", "arm_r"]:
		nodes[n].rotation = 0.0
	nodes["arm_l"].position = SHOULDER_L - HIP
	nodes["arm_r"].position = SHOULDER_R - HIP
	nodes["pupil_l"].scale = Vector2.ONE
	nodes["pupil_r"].scale = Vector2.ONE
	nodes["lid_l"].scale = Vector2(1, 0.001)
	nodes["lid_r"].scale = Vector2(1, 0.001)
	nodes["tongue"].scale = Vector2(1, 0.001)
	nodes["tongue"].visible = false
	nodes["tongue"].rotation = 0.0
	nodes["aura"].visible = false
	for n in ["happy_l", "happy_r", "mouth_open", "mouth_o", "mouth_sad"]:
		nodes[n].visible = false
	nodes["eye_l"].visible = true
	nodes["eye_r"].visible = true
	nodes["pupil_l"].visible = true
	nodes["pupil_r"].visible = true
	nodes["mouth_smile"].visible = true
	position = Vector2.ZERO if false else position

# ---------------- animation building ----------------
func _p(path: String) -> NodePath:
	var parts: PackedStringArray = path.split(":", true, 1)
	if parts[0] == "..":
		return NodePath(path)
	var img: Node = lean.get_node("img")
	return NodePath(str(img.get_path_to(nodes[parts[0]])) + ":" + parts[1])

func _tr(a: Animation, path: String, keys: Array, interp: int = Animation.INTERPOLATION_CUBIC) -> void:
	var idx: int = a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(idx, _p(path))
	a.track_set_interpolation_type(idx, interp)
	for k in keys:
		a.track_insert_key(idx, k[0], k[1])

func _vis(a: Animation, path: String, keys: Array) -> void:
	var idx: int = a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(idx, _p(path))
	a.value_track_set_update_mode(idx, Animation.UPDATE_DISCRETE)
	a.track_set_interpolation_type(idx, Animation.INTERPOLATION_NEAREST)
	for k in keys:
		a.track_insert_key(idx, k[0], k[1])

func _build_animations() -> void:
	if player != null:
		player.queue_free()
	player = AnimationPlayer.new()
	player.name = "AnimationPlayer"
	add_child(player)
	player.root_node = player.get_path_to(lean.get_node("img"))
	var lib := AnimationLibrary.new()
	var H: String = "head"
	var T: String = "torso"
	var V2: Callable = func(x: float, y: float) -> Vector2: return Vector2(x, y)
	# 1 idle
	var a: Animation = Animation.new(); a.length = 2.6; a.loop_mode = Animation.LOOP_LINEAR
	_tr(a, "head:position", [[0.0, NECK], [1.3, NECK + Vector2(0, -5)], [2.6, NECK]])
	_tr(a, "head:rotation", [[0.0, 0.0], [0.65, deg_to_rad(1.8)], [1.95, deg_to_rad(-1.8)], [2.6, 0.0]])
	_tr(a, "torso:scale", [[0.0, Vector2(1, 1)], [1.3, Vector2(1.012, 1.02)], [2.6, Vector2(1, 1)]])
	lib.add_animation("idle", a)
	# 2 breathing
	a = Animation.new(); a.length = 3.2; a.loop_mode = Animation.LOOP_LINEAR
	_tr(a, "torso:scale", [[0.0, Vector2(1, 1)], [1.6, Vector2(1.03, 1.05)], [3.2, Vector2(1, 1)]])
	_tr(a, "head:position", [[0.0, NECK], [1.6, NECK + Vector2(0, -7)], [3.2, NECK]])
	lib.add_animation("breathing", a)
	# 3 blink
	a = Animation.new(); a.length = 0.24
	_tr(a, "lid_l:scale", [[0.0, Vector2(1, 0.001)], [0.07, Vector2(1, 1)], [0.13, Vector2(1, 1)], [0.24, Vector2(1, 0.001)]])
	_tr(a, "lid_r:scale", [[0.0, Vector2(1, 0.001)], [0.07, Vector2(1, 1)], [0.13, Vector2(1, 1)], [0.24, Vector2(1, 0.001)]])
	var blib := AnimationLibrary.new()
	blib.add_animation("blink", a)
	if blinker != null:
		blinker.queue_free()
	blinker = AnimationPlayer.new()
	blinker.name = "Blinker"
	add_child(blinker)
	blinker.root_node = blinker.get_path_to(lean.get_node("img"))
	blinker.add_animation_library("", blib)
	lib.add_animation("blink", Animation.new())
	# 4 happy
	a = Animation.new(); a.length = 1.3
	_tr(a, "torso:scale", [[0.0, Vector2(1, 1)], [0.15, Vector2(1.08, 0.9)], [0.35, Vector2(0.95, 1.1)], [0.6, Vector2(1.03, 0.98)], [1.3, Vector2(1, 1)]])
	_tr(a, "head:position", [[0.0, NECK], [0.2, NECK + Vector2(0, 8)], [0.4, NECK + Vector2(0, -22)], [0.7, NECK + Vector2(0, 2)], [1.3, NECK]])
	_tr(a, "head:rotation", [[0.0, 0.0], [0.4, deg_to_rad(5)], [0.8, deg_to_rad(-5)], [1.3, 0.0]])
	_vis(a, "happy_l:visible", [[0.0, false], [0.1, true], [1.1, false]])
	_vis(a, "happy_r:visible", [[0.0, false], [0.1, true], [1.1, false]])
	_vis(a, "eye_l:visible", [[0.0, true], [0.1, false], [1.1, true]])
	_vis(a, "eye_r:visible", [[0.0, true], [0.1, false], [1.1, true]])
	_vis(a, "pupil_l:visible", [[0.0, true], [0.1, false], [1.1, true]])
	_vis(a, "pupil_r:visible", [[0.0, true], [0.1, false], [1.1, true]])
	lib.add_animation("happy", a)
	# 5 shooting: wind-up squash, recoil, open mouth
	a = Animation.new(); a.length = 0.42
	_tr(a, "torso:scale", [[0.0, Vector2(1, 1)], [0.05, Vector2(1.1, 0.86)], [0.14, Vector2(0.93, 1.1)], [0.42, Vector2(1, 1)]])
	_tr(a, "head:position", [[0.0, NECK], [0.05, NECK + Vector2(0, 14)], [0.14, NECK + Vector2(0, -12)], [0.42, NECK]])
	_tr(a, "head:scale", [[0.0, Vector2(1, 1)], [0.05, Vector2(1.04, 0.94)], [0.14, Vector2(0.97, 1.05)], [0.42, Vector2(1, 1)]])
	_vis(a, "mouth_smile:visible", [[0.0, true], [0.04, false], [0.34, true]])
	_vis(a, "mouth_open:visible", [[0.0, false], [0.04, true], [0.34, false]])
	_tr(a, "arm_l:rotation", [[0.0, 0.0], [0.08, deg_to_rad(-18)], [0.42, 0.0]])
	_tr(a, "arm_r:rotation", [[0.0, 0.0], [0.08, deg_to_rad(18)], [0.42, 0.0]])
	lib.add_animation("shooting", a)
	# 6 tongue
	a = Animation.new(); a.length = 0.55
	_vis(a, "tongue:visible", [[0.0, false], [0.03, true], [0.5, false]])
	_vis(a, "mouth_smile:visible", [[0.0, true], [0.03, false], [0.5, true]])
	_vis(a, "mouth_open:visible", [[0.0, false], [0.03, true], [0.5, false]])
	_tr(a, "tongue:scale", [[0.0, Vector2(1, 0.05)], [0.12, Vector2(1.0, 1.45)], [0.28, Vector2(1.05, 1.3)], [0.5, Vector2(1, 0.05)]])
	lib.add_animation("tongue", a)
	# 7 excited (loop)
	a = Animation.new(); a.length = 0.5; a.loop_mode = Animation.LOOP_LINEAR
	_tr(a, "head:position", [[0.0, NECK], [0.125, NECK + Vector2(0, -16)], [0.25, NECK], [0.375, NECK + Vector2(0, -16)], [0.5, NECK]])
	_tr(a, "torso:scale", [[0.0, Vector2(1, 1)], [0.125, Vector2(0.96, 1.07)], [0.25, Vector2(1.05, 0.95)], [0.375, Vector2(0.96, 1.07)], [0.5, Vector2(1, 1)]])
	_tr(a, "pupil_l:scale", [[0.0, Vector2(1.25, 1.25)], [0.5, Vector2(1.25, 1.25)]])
	_tr(a, "pupil_r:scale", [[0.0, Vector2(1.25, 1.25)], [0.5, Vector2(1.25, 1.25)]])
	_vis(a, "mouth_smile:visible", [[0.0, false]])
	_vis(a, "mouth_open:visible", [[0.0, true]])
	lib.add_animation("excited", a)
	# 8 combo celebration
	a = Animation.new(); a.length = 1.5
	_tr(a, "torso:position", [[0.0, HIP - Vector2.ZERO], [0.2, HIP + Vector2(0, 12)], [0.5, HIP + Vector2(0, -54)], [0.9, HIP + Vector2(0, 6)], [1.5, HIP]])
	_tr(a, "head:position", [[0.0, NECK], [0.2, NECK + Vector2(0, 22)], [0.5, NECK + Vector2(0, -92)], [0.9, NECK + Vector2(0, 10)], [1.5, NECK]])
	_tr(a, "head:rotation", [[0.0, 0.0], [0.5, deg_to_rad(-10)], [0.9, deg_to_rad(10)], [1.5, 0.0]])
	_tr(a, "arm_l:rotation", [[0.0, 0.0], [0.3, deg_to_rad(70)], [0.9, deg_to_rad(80)], [1.5, 0.0]])
	_tr(a, "arm_r:rotation", [[0.0, 0.0], [0.3, deg_to_rad(-70)], [0.9, deg_to_rad(-80)], [1.5, 0.0]])
	_vis(a, "happy_l:visible", [[0.0, false], [0.1, true], [1.2, false]])
	_vis(a, "happy_r:visible", [[0.0, false], [0.1, true], [1.2, false]])
	_vis(a, "eye_l:visible", [[0.0, true], [0.1, false], [1.2, true]])
	_vis(a, "eye_r:visible", [[0.0, true], [0.1, false], [1.2, true]])
	_vis(a, "pupil_l:visible", [[0.0, true], [0.1, false], [1.2, true]])
	_vis(a, "pupil_r:visible", [[0.0, true], [0.1, false], [1.2, true]])
	_vis(a, "mouth_smile:visible", [[0.0, false], [1.2, true]])
	_vis(a, "mouth_open:visible", [[0.0, true], [1.2, false]])
	lib.add_animation("combo", a)
	# 9 damage
	a = Animation.new(); a.length = 0.6
	_tr(a, "head:position", [[0.0, NECK], [0.06, NECK + Vector2(-16, 0)], [0.12, NECK + Vector2(16, 0)], [0.18, NECK + Vector2(-12, 0)], [0.24, NECK + Vector2(10, 0)], [0.36, NECK + Vector2(-4, 0)], [0.6, NECK]])
	_tr(a, "torso:scale", [[0.0, Vector2(1, 1)], [0.08, Vector2(1.1, 0.88)], [0.3, Vector2(0.98, 1.02)], [0.6, Vector2(1, 1)]])
	_tr(a, "pupil_l:scale", [[0.0, Vector2(1, 1)], [0.08, Vector2(0.6, 0.6)], [0.5, Vector2(0.75, 0.75)], [0.6, Vector2(1, 1)]])
	_tr(a, "pupil_r:scale", [[0.0, Vector2(1, 1)], [0.08, Vector2(0.6, 0.6)], [0.5, Vector2(0.75, 0.75)], [0.6, Vector2(1, 1)]])
	_vis(a, "mouth_smile:visible", [[0.0, false], [0.52, true]])
	_vis(a, "mouth_o:visible", [[0.0, true], [0.52, false]])
	_tr(a, "..:modulate", [[0.0, Color.WHITE], [0.05, Color(1, 0.45, 0.45)], [0.35, Color(1, 0.75, 0.75)], [0.6, Color.WHITE]])
	lib.add_animation("damage", a)
	# 10 game over (holds last pose)
	a = Animation.new(); a.length = 1.2
	_tr(a, "torso:scale", [[0.0, Vector2(1, 1)], [0.6, Vector2(1.05, 0.88)], [1.2, Vector2(1.05, 0.88)]])
	_tr(a, "head:position", [[0.0, NECK], [0.6, NECK + Vector2(0, 28)], [1.2, NECK + Vector2(0, 28)]])
	_tr(a, "head:rotation", [[0.0, 0.0], [0.8, deg_to_rad(-6)], [1.2, deg_to_rad(-6)]])
	_tr(a, "lid_l:scale", [[0.0, Vector2(1, 0.001)], [0.6, Vector2(1, 0.45)], [1.2, Vector2(1, 0.45)]])
	_tr(a, "lid_r:scale", [[0.0, Vector2(1, 0.001)], [0.6, Vector2(1, 0.45)], [1.2, Vector2(1, 0.45)]])
	_vis(a, "mouth_smile:visible", [[0.0, false]])
	_vis(a, "mouth_sad:visible", [[0.0, false], [0.3, true]])
	_tr(a, "arm_l:rotation", [[0.0, 0.0], [0.8, deg_to_rad(-12)]])
	_tr(a, "arm_r:rotation", [[0.0, 0.0], [0.8, deg_to_rad(12)]])
	_tr(a, "..:modulate", [[0.0, Color.WHITE], [0.8, Color(0.82, 0.88, 0.95)], [1.2, Color(0.82, 0.88, 0.95)]])
	lib.add_animation("game_over", a)
	# 11 victory
	a = Animation.new(); a.length = 2.0; a.loop_mode = Animation.LOOP_LINEAR
	_tr(a, "torso:position", [[0.0, HIP], [0.25, HIP + Vector2(0, 10)], [0.55, HIP + Vector2(0, -50)], [0.95, HIP], [1.2, HIP + Vector2(0, 10)], [1.5, HIP + Vector2(0, -50)], [1.9, HIP], [2.0, HIP]])
	_tr(a, "head:position", [[0.0, NECK], [0.25, NECK + Vector2(0, 20)], [0.55, NECK + Vector2(0, -88)], [0.95, NECK], [1.2, NECK + Vector2(0, 20)], [1.5, NECK + Vector2(0, -88)], [1.9, NECK], [2.0, NECK]])
	_tr(a, "arm_l:rotation", [[0.0, deg_to_rad(60)], [1.0, deg_to_rad(80)], [2.0, deg_to_rad(60)]])
	_tr(a, "arm_r:rotation", [[0.0, deg_to_rad(-60)], [1.0, deg_to_rad(-80)], [2.0, deg_to_rad(-60)]])
	_vis(a, "happy_l:visible", [[0.0, true]])
	_vis(a, "happy_r:visible", [[0.0, true]])
	_vis(a, "eye_l:visible", [[0.0, false]])
	_vis(a, "eye_r:visible", [[0.0, false]])
	_vis(a, "pupil_l:visible", [[0.0, false]])
	_vis(a, "pupil_r:visible", [[0.0, false]])
	_vis(a, "mouth_smile:visible", [[0.0, false]])
	_vis(a, "mouth_open:visible", [[0.0, true]])
	lib.add_animation("victory", a)
	# 12 special power
	a = Animation.new(); a.length = 1.3
	_vis(a, "aura:visible", [[0.0, true], [1.2, false]])
	_tr(a, "torso:scale", [[0.0, Vector2(1, 1)], [0.2, Vector2(0.92, 1.12)], [0.5, Vector2(1.14, 1.14)], [1.3, Vector2(1, 1)]])
	_tr(a, "head:rotation", [[0.0, 0.0], [0.2, deg_to_rad(-12)], [0.5, deg_to_rad(12)], [0.8, deg_to_rad(-8)], [1.3, 0.0]])
	_tr(a, "head:position", [[0.0, NECK], [0.3, NECK + Vector2(0, -20)], [1.3, NECK]])
	_tr(a, "pupil_l:scale", [[0.0, Vector2(1, 1)], [0.2, Vector2(1.4, 1.4)], [1.3, Vector2(1, 1)]])
	_tr(a, "pupil_r:scale", [[0.0, Vector2(1, 1)], [0.2, Vector2(1.4, 1.4)], [1.3, Vector2(1, 1)]])
	_tr(a, "arm_l:rotation", [[0.0, 0.0], [0.4, deg_to_rad(75)], [1.3, 0.0]])
	_tr(a, "arm_r:rotation", [[0.0, 0.0], [0.4, deg_to_rad(-75)], [1.3, 0.0]])
	_vis(a, "mouth_smile:visible", [[0.0, false], [1.2, true]])
	_vis(a, "mouth_open:visible", [[0.0, true], [1.2, false]])
	lib.add_animation("special", a)
	player.add_animation_library("", lib)
	player.animation_finished.connect(_on_anim_finished)

func play(anim: String, hold: bool = false) -> void:
	if player == null or not player.has_animation(anim):
		return
	if anim == "blink":
		# blink is an overlay: only on top of idle-like states
		if state in ["game_over", "victory", "excited", "combo", "special"]:
			return
		blinker.play("blink")
		return
	reset_pose()
	state = anim
	_hold_state = hold or anim == "game_over"
	player.play(anim)

func _on_anim_finished(anim: StringName) -> void:
	if anim == &"blink":
		return
	if anim == &"game_over":
		return
	if anim in [&"idle", &"breathing", &"excited", &"victory"]:
		return
	# one-shot finished -> back to idle
	reset_pose()
	state = "idle"
	player.play("idle")

func _process(delta: float) -> void:
	if player == null:
		return
	_t += delta
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blink_t = randf_range(1.8, 4.2)
		play("blink")
	# eye tracking
	if has_target:
		var inv: Transform2D = get_global_transform().affine_inverse()
		var local: Vector2 = inv * look_target
		for side in ["pupil_l", "pupil_r"]:
			var n: Node2D = nodes[side]
			var base: Vector2 = EYE_L if side == "pupil_l" else EYE_R
			var eye_pos: Vector2 = base - CENTER
			var d: Vector2 = local - eye_pos
			var dir: Vector2 = d.normalized() * minf(d.length() / 60.0, 1.0)
			n.position = (base - NECK) + dir * look_strength
		# slight lean toward the target (whole body)
		var dx: float = clampf(local.x / 500.0, -1.0, 1.0)
		lean.rotation = lerp_angle(lean.rotation, dx * deg_to_rad(9.0), 1.0 - exp(-delta * 8.0))

func look_at_point(p: Vector2) -> void:
	look_target = p
	has_target = true

func clear_look() -> void:
	has_target = false

## Convenience reactions used by gameplay.
func on_shoot() -> void:
	if state in ["game_over", "victory"]:
		return
	play("shooting")

func on_tongue() -> void:
	if state in ["game_over", "victory"]:
		return
	play("tongue")

func on_streak(streak: int) -> void:
	if state in ["game_over", "victory", "combo", "special"]:
		return
	if streak >= 3 and streak % 3 == 0:
		play("combo")
	elif streak >= 2:
		play("happy")

func on_damage() -> void:
	play("damage")

func set_excited(on: bool) -> void:
	if on and state in ["idle", "breathing"]:
		play("excited")
	elif not on and state == "excited":
		play("idle")
