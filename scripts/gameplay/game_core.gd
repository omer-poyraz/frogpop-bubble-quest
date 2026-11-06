class_name GameCore
extends RefCounted
## Pure game rules: waves, shooting, scoring, power-ups. No nodes, no rendering.

signal wave_started(wave: int, path: PathData)
signal wave_cleared(wave: int, bonus: int)
signal game_over(info: Dictionary)
signal shot_fired(color: int, from: Vector2, dir: Vector2)
signal ball_inserted(ball: Ball, from_world: Vector2)
signal pop_scored(info: Dictionary, award: Dictionary)
signal missed()
signal power_used(power: String)
signal power_earned(power: String)
signal ammo_changed()
signal score_changed(score: int)
signal streak_changed(streak: int)
signal bomb_exploded(pos: Vector2)
signal lightning_struck(positions: PackedVector2Array)
signal time_changed(left: float)
signal hole_warning(level: float)

enum State { INTRO, PLAYING, WAVE_CLEAR, LOST, ENDED }

var mode: String = "classic"
var state: int = State.INTRO
var wave: int = 0
var seed_value: int = 1
var rng := RandomNumberGenerator.new()
var path: PathData
var chain := BubbleChainManager.new()
var score_mgr := ScoreManager.new()
var power := PowerUpManager.new()
var params: Dictionary = {}
var palette: Array[int] = []
var frog_pos: Vector2 = Vector2(540, 960)
var aim_dir: Vector2 = Vector2.UP
var ammo: int = 0
var ammo_next: int = 0
var projectiles: Array = []   # {pos, vel, color, bomb}
var streak: int = 0
var time: float = 0.0
var reload: float = 0.0
var shots: int = 0
var misses: int = 0
var danger: float = 0.0
var time_left: float = 0.0
var continued: bool = false
var wave_clear_t: float = 0.0
var prev_route: String = ""
var intro_done: bool = false
var rainbow_next: bool = false
var _acc: float = 0.0
var _pos_cache: PackedVector2Array = PackedVector2Array()
var _ended: bool = false
var world_order: Array = []
var events: Array = []   # lightweight log for tests / bot

const TIME_ATTACK_SECONDS: float = 90.0
const WAVE_CLEAR_DELAY: float = 1.9
const BOMB_PROJECTILE: int = 100

func start(p_mode: String, p_seed: int, inventory: Dictionary = {}, start_wave: int = 1) -> void:
	mode = p_mode
	seed_value = p_seed
	rng.seed = p_seed
	score_mgr.reset()
	power.setup(inventory)
	streak = 0
	shots = 0
	misses = 0
	time = 0.0
	continued = false
	_ended = false
	projectiles.clear()
	time_left = TIME_ATTACK_SECONDS
	chain.popped.connect(_on_chain_popped)
	wave = start_wave - 1
	_begin_wave()

func _begin_wave() -> void:
	wave += 1
	params = Difficulty.params(wave, mode)
	var rtype: String = Difficulty.route_type(wave, seed_value, prev_route)
	prev_route = rtype
	path = PathGenerator.generate(rtype, hash([seed_value, wave]))
	frog_pos = path.frog_pos
	var max_by_len: int = int(FILL_MAX_RATIO * (path.length - path.enter_s) / K.BALL_D)
	var seq: Dictionary = Difficulty.make_sequence(params, rng, max_by_len)
	palette = seq["palette"]
	chain.setup(path, seq["colors"], seq["kinds"])
	chain.reaction_level = 0
	projectiles.clear()
	intro_done = false
	state = State.INTRO
	danger = 0.0
	wave_clear_t = 0.0
	_roll_ammo(true)
	wave_started.emit(wave, path)

const FILL_MAX_RATIO: float = 0.6

func _roll_ammo(initial: bool = false) -> void:
	if initial:
		ammo = _pick_color()
		ammo_next = _pick_color()
	else:
		ammo = ammo_next
		ammo_next = _pick_color()
	ammo_changed.emit()

func _pick_color() -> int:
	if rainbow_next:
		rainbow_next = false
		return K.RAINBOW
	var present: Array[int] = chain.colors_present()
	if present.is_empty():
		present = palette
	return present[rng.randi() % present.size()]

func base_speed() -> float:
	return float(params["speed"])

func can_fire() -> bool:
	return (state == State.PLAYING or state == State.INTRO) and reload <= 0.0

func fire(target: Vector2) -> bool:
	if not can_fire():
		return false
	var d: Vector2 = target - frog_pos
	if d.length() < 40.0:
		return false
	aim_dir = d.normalized()
	var color: int = ammo
	var bomb: bool = false
	if power.bomb_armed:
		bomb = true
		power.bomb_armed = false
	var start_pos: Vector2 = frog_pos + aim_dir * 70.0
	projectiles.append({"pos": start_pos, "prev": start_pos, "vel": aim_dir * K.SHOT_SPEED, "color": color, "bomb": bomb, "age": 0.0})
	shots += 1
	reload = K.RELOAD_TIME
	_roll_ammo()
	shot_fired.emit(color, start_pos, aim_dir)
	return true

func swap_ammo() -> void:
	var t: int = ammo
	ammo = ammo_next
	ammo_next = t
	ammo_changed.emit()

## Frame update: accumulates fixed steps.
func update(dt: float) -> void:
	_acc += minf(dt, 0.25)
	var n: int = 0
	while _acc >= K.STEP and n < K.MAX_STEPS_PER_FRAME:
		_step(K.STEP)
		_acc -= K.STEP
		n += 1
	if _acc > K.STEP * K.MAX_STEPS_PER_FRAME:
		_acc = 0.0

func _step(dt: float) -> void:
	if state == State.ENDED or state == State.LOST:
		return
	time += dt
	reload = maxf(reload - dt, 0.0)
	if state == State.WAVE_CLEAR:
		wave_clear_t -= dt
		if wave_clear_t <= 0.0:
			if mode == "daily" and wave >= 3:
				_finish("daily_done")
			else:
				_begin_wave()
		_step_projectiles(dt)
		return
	power.tick(dt)
	if mode == "time":
		var before: int = int(ceil(time_left))
		time_left = maxf(time_left - dt, 0.0)
		if int(ceil(time_left)) != before:
			time_changed.emit(time_left)
		if time_left <= 0.0:
			_finish("time")
			return
	# chain speed
	var spd: float = base_speed() * power.speed_factor()
	if not chain.fully_entered() and chain.segments().size() == 1:
		spd = K.INTRO_SPEED
	if power.reverse_t > 0.0:
		spd = -PowerUpManager.REVERSE_SPEED
	var limit: float = INF
	var hole_s: float = path.length - K.BALL_D * 0.5
	if mode == "zen" or power.shield_t > 0.0:
		limit = hole_s - 2.0
	chain.step(dt, spd, limit)
	if state == State.INTRO and chain.fully_entered():
		state = State.PLAYING
		intro_done = true
	_step_projectiles(dt)
	# danger / loss
	if chain.count() > 0:
		danger = clampf((chain.front_s() - path.length * 0.72) / (path.length * 0.28), 0.0, 1.0)
		if chain.front_s() >= hole_s and mode != "zen" and power.shield_t <= 0.0:
			state = State.LOST
			_finish("hole")
			return
	else:
		danger = 0.0
	hole_warning.emit(danger)
	# wave cleared
	if chain.count() == 0 and state != State.WAVE_CLEAR:
		var bonus: int = 200 + wave * 25
		score_mgr.score += bonus
		score_changed.emit(score_mgr.score)
		state = State.WAVE_CLEAR
		wave_clear_t = WAVE_CLEAR_DELAY
		projectiles.clear()
		wave_cleared.emit(wave, bonus)

func _finish(reason: String) -> void:
	if _ended:
		return
	_ended = true
	if reason == "hole" or reason == "time":
		state = State.LOST if reason == "hole" else State.ENDED
	else:
		state = State.ENDED
	var info: Dictionary = {"reason": reason, "score": score_mgr.score, "wave": wave, "time": time, "balls": score_mgr.balls_popped,
		"best_chain": score_mgr.best_chain, "best_combo": score_mgr.best_combo, "coins": score_mgr.coins_earned,
		"shots": shots, "perfect": score_mgr.perfect_shots, "saves": score_mgr.last_second_saves, "mode": mode,
		"powers_used": power.used_count, "can_continue": reason == "hole" and not continued}
	game_over.emit(info)

## Used by "continue" (rewarded ad): clear front balls and grant a shield window.
func revive() -> void:
	if state != State.LOST:
		return
	continued = true
	_ended = false
	var front: Array = chain.front_balls(14)
	chain.remove_group(front, "revive")
	power.shield_t = 4.0
	state = State.PLAYING

func end_now() -> void:
	_finish("quit")

func _positions() -> PackedVector2Array:
	var n: int = chain.balls.size()
	_pos_cache.resize(n)
	for i in n:
		_pos_cache[i] = chain.path.pos_at((chain.balls[i] as Ball).s)
	return _pos_cache

func _step_projectiles(dt: float) -> void:
	if projectiles.is_empty():
		return
	var keep: Array = []
	for pr in projectiles:
		var poss: PackedVector2Array = _positions()
		var a: Vector2 = pr["pos"]
		var b: Vector2 = a + (pr["vel"] as Vector2) * dt
		pr["prev"] = a
		pr["age"] += dt
		var hit: Dictionary = {}
		if chain.balls.size() > 0:
			hit = chain.segment_hit(a, b, poss)
		if not hit.is_empty():
			var contact: Vector2 = a.lerp(b, hit["t"])
			_land(pr, int(hit["idx"]), contact)
			continue
		pr["pos"] = b
		if b.x < -150 or b.x > K.FIELD_W + 150 or b.y < -150 or b.y > K.FIELD_H + 150:
			_on_miss()
			continue
		keep.append(pr)
	projectiles = keep

func _on_miss() -> void:
	misses += 1
	if streak > 0:
		streak = 0
		streak_changed.emit(0)
	missed.emit()

func _land(pr: Dictionary, idx: int, contact: Vector2) -> void:
	chain.reaction_level = 0
	if pr["bomb"]:
		_explode_at(contact)
		return
	var hit_ball: Ball = chain.balls[idx]
	var hit_pos: Vector2 = chain.path.pos_at(hit_ball.s)
	var tang: Vector2 = chain.path.tangent_at(hit_ball.s)
	var front_side: bool = (contact - hit_pos).dot(tang) > 0.0
	var k: int = idx if front_side else idx + 1
	var color: int = pr["color"]
	var b := Ball.new(color, 0.0)
	if color == K.RAINBOW:
		var best_c: int = hit_ball.color
		var best_run: int = -1
		for cand in [hit_ball.color, (chain.balls[idx - 1] as Ball).color if idx > 0 else -1, (chain.balls[idx + 1] as Ball).color if idx + 1 < chain.balls.size() else -1]:
			if cand < 0:
				continue
			var r: int = BubbleMatchSystem.preview_run(chain.balls, k, cand, chain.path.enter_s)
			if r > best_run:
				best_run = r
				best_c = cand
		b.color = best_c
	var nk: int = chain.insert_at(k, b)
	ball_inserted.emit(b, contact)
	var popped_n: int = chain.resolve_insert(nk)
	if popped_n == 0:
		if streak > 0:
			streak = 0
			streak_changed.emit(0)
	# long streak reward: next ammo becomes rainbow
	events.append("shot")

func _explode_at(pos: Vector2) -> void:
	var list: Array = chain.balls_within(pos, K.BOMB_RADIUS)
	bomb_exploded.emit(pos)
	if list.is_empty():
		_on_miss()
		return
	chain.remove_group(list, "bomb")

func _on_chain_popped(info: Dictionary) -> void:
	var src: String = str(info["source"])
	if src == "shot" or src == "magnet":
		if src == "shot":
			streak += 1
			streak_changed.emit(streak)
			if streak > 0 and streak % 8 == 0:
				rainbow_next = true
	var a: Dictionary = score_mgr.award(info, streak, danger)
	var earned: String = power.add_points(int(a["points"]), rng)
	score_changed.emit(score_mgr.score)
	pop_scored.emit(info, a)
	if earned != "":
		power_earned.emit(earned)

# ---------------- Power-ups ----------------

func use_power(p: String, arg: Variant = null) -> bool:
	if state != State.PLAYING and state != State.INTRO:
		return false
	if power.count(p) <= 0 and not (mode == "zen" and false):
		return false
	var ok: bool = false
	chain.reaction_level = 0
	match p:
		"rainbow":
			var c: int = -1
			if arg is int:
				c = int(arg)
			elif arg is Vector2:
				var hits: Array = chain.balls_within(arg, K.HIT_RADIUS)
				if not hits.is_empty():
					c = (hits[0] as Ball).color
			if c < 0:
				c = best_color()
			if c >= 0:
				var list: Array = chain.balls_of_color(c)
				if not list.is_empty():
					chain.remove_group(list, "rainbow", c)
					ok = true
		"bomb":
			if not power.bomb_armed:
				power.bomb_armed = true
				ok = true
		"slow":
			power.slow_t = PowerUpManager.SLOW_TIME
			ok = true
		"switch":
			ammo = switch_color()
			ammo_changed.emit()
			ok = true
		"lightning":
			var list2: Array = chain.front_balls(PowerUpManager.LIGHTNING_COUNT)
			if not list2.is_empty():
				var ps := PackedVector2Array()
				for b in list2:
					ps.append(chain.world_pos(b))
				lightning_struck.emit(ps)
				chain.remove_group(list2, "lightning")
				ok = true
		"shield":
			power.shield_t = PowerUpManager.SHIELD_TIME
			ok = true
		"backward":
			power.reverse_t = PowerUpManager.REVERSE_TIME
			ok = true
	if ok:
		power.consume(p)
		power_used.emit(p)
	return ok

func best_color() -> int:
	var counts: Dictionary = {}
	for b in chain.balls:
		var bb: Ball = b
		if bb.s >= chain.path.enter_s and bb.color >= 0:
			counts[bb.color] = int(counts.get(bb.color, 0)) + 1
	var best: int = -1
	var bc: int = 0
	for c in counts:
		if counts[c] > bc:
			bc = counts[c]
			best = c
	return best

## Colour that completes the most useful run near the front.
func switch_color() -> int:
	var best: int = ammo
	var best_score: int = -1
	for c in chain.colors_present():
		if c == ammo:
			continue
		var sc: int = 0
		for k in chain.balls.size() + 1:
			sc = maxi(sc, BubbleMatchSystem.preview_run(chain.balls, k, c, chain.path.enter_s))
		if sc > best_score:
			best_score = sc
			best = c
	return best

## Hypothetical insert result for bots/tests: list position for a hit.
func predict_slot(idx: int, contact: Vector2) -> int:
	var hit_ball: Ball = chain.balls[idx]
	var hit_pos: Vector2 = chain.path.pos_at(hit_ball.s)
	var tang: Vector2 = chain.path.tangent_at(hit_ball.s)
	return idx if (contact - hit_pos).dot(tang) > 0.0 else idx + 1
