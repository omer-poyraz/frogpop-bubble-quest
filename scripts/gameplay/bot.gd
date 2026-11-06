class_name Bot
extends RefCounted
## Greedy simulated shooter used for balance measurements, tests and trailer capture.

var think_interval: float = 0.22
var _t: float = 0.0
var skill: float = 1.0   # 1 = perfect aim, lower adds aim error
var rng := RandomNumberGenerator.new()
var use_powers: bool = true

func tick(core: GameCore, dt: float) -> void:
	_t += dt
	if _t < think_interval or not core.can_fire() or core.chain.balls.is_empty():
		return
	_t = 0.0
	if use_powers:
		_maybe_power(core)
	var best: Dictionary = _best_for(core, core.ammo)
	var alt: Dictionary = _best_for(core, core.ammo_next) if core.ammo_next != core.ammo else {}
	if not alt.is_empty() and (best.is_empty() or alt["score"] > best["score"] + 50.0):
		core.swap_ammo()
		best = alt
	if best.is_empty():
		best = _fallback(core)
	if best.is_empty():
		return
	var target: Vector2 = best["target"]
	if skill < 1.0:
		target += Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * (1.0 - skill) * 80.0
	core.fire(target)

func _maybe_power(core: GameCore) -> void:
	if core.danger > 0.8:
		for p in ["lightning", "backward", "shield", "bomb"]:
			if core.power.count(p) > 0 and core.use_power(p):
				return
	elif core.danger > 0.55 and core.power.count("slow") > 0 and core.power.slow_t <= 0.0:
		core.use_power("slow")

func _velocities(core: GameCore) -> Array:
	var segs: Array = core.chain.segments()
	var v: Array = []
	v.resize(core.chain.balls.size())
	var spd: float = core.base_speed() * core.power.speed_factor()
	if not core.chain.fully_entered() and segs.size() == 1:
		spd = K.INTRO_SPEED
	for k in segs.size():
		for i in range(segs[k][0], segs[k][1] + 1):
			v[i] = spd if k == segs.size() - 1 else 0.0
	return v

func _best_for(core: GameCore, color: int) -> Dictionary:
	var chain: BubbleChainManager = core.chain
	var n: int = chain.balls.size()
	if n == 0:
		return {}
	var poss := PackedVector2Array()
	poss.resize(n)
	for i in n:
		poss[i] = chain.path.pos_at((chain.balls[i] as Ball).s)
	var vel: Array = _velocities(core)
	var best: Dictionary = {}
	var best_score: float = -1.0
	var frog: Vector2 = core.frog_pos
	var enter: float = chain.path.enter_s
	var eff_color: int = color
	for i in n:
		var b: Ball = chain.balls[i]
		if b.s < enter or b.s > chain.path.length:
			continue
		# candidate: balls of our colour or neighbours of them (when rainbow, everything)
		var relevant: bool = color == K.RAINBOW or b.color == color
		if not relevant:
			if i > 0 and (chain.balls[i - 1] as Ball).color == color:
				relevant = true
			elif i + 1 < n and (chain.balls[i + 1] as Ball).color == color:
				relevant = true
		if not relevant:
			continue
		# lead compensation
		var t: float = frog.distance_to(poss[i]) / K.SHOT_SPEED
		var tp: Vector2 = chain.path.pos_at(b.s + float(vel[i]) * t * 1.0)
		t = frog.distance_to(tp) / K.SHOT_SPEED
		tp = chain.path.pos_at(b.s + float(vel[i]) * t)
		var dir: Vector2 = (tp - frog).normalized()
		var far: Vector2 = frog + dir * 3000.0
		var hit: Dictionary = chain.segment_hit(frog, far, poss)
		if hit.is_empty():
			continue
		var idx: int = int(hit["idx"])
		var contact: Vector2 = frog.lerp(far, hit["t"])
		var k: int = core.predict_slot(idx, contact)
		var run: int = 0
		if color == K.RAINBOW:
			for cc in K.NORMAL_COLORS:
				run = maxi(run, BubbleMatchSystem.preview_run(chain.balls, k, cc, enter))
		else:
			run = BubbleMatchSystem.preview_run(chain.balls, k, color, enter)
		var urgency: float = clampf(b.s / chain.path.length, 0.0, 1.0)
		var sc: float = 0.0
		if run >= 3:
			sc = 1000.0 + float(run) * 20.0 + urgency * 300.0
		elif run == 2:
			sc = 100.0 + urgency * 60.0
		else:
			sc = 5.0 + urgency * 10.0
		if sc > best_score:
			best_score = sc
			best = {"target": tp, "score": sc, "run": run}
	return best

func _fallback(core: GameCore) -> Dictionary:
	var fb: Ball = core.chain.front_balls(1)[0] if core.chain.front_balls(1).size() > 0 else null
	if fb == null:
		return {}
	return {"target": core.chain.world_pos(fb), "score": 0.0}
