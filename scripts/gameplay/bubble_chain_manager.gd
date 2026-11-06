class_name BubbleChainManager
extends RefCounted
## Chain of balls along a PathData. balls[0] is the FRONT (closest to the hole, largest s).
## Rules: only the rear-most contiguous segment is driven; front segments stand still
## behind a gap and may be magnet-pulled back when both gap ends match.

signal popped(info: Dictionary)
signal inserted(ball: Ball, from_world: Vector2)
signal joined(index: int)

var path: PathData
var balls: Array = []
var magnet_enabled: bool = true
var _prev_contig: Dictionary = {}   # rear-ball id -> contiguous last step
var reaction_level: int = 0
var time: float = 0.0
var removed_total: int = 0

func setup(p: PathData, colors: Array[int], kinds: Array = []) -> void:
	path = p
	balls.clear()
	_prev_contig.clear()
	for i in colors.size():
		var kind: int = K.KIND_NORMAL
		var gold: bool = false
		if i < kinds.size():
			var kd: int = int(kinds[i])
			kind = kd & 3
			gold = (kd & 4) != 0
		var b := Ball.new(colors[i] if kind != K.KIND_STONE else -1, -float(i) * K.BALL_D, kind, gold)
		balls.append(b)

func count() -> int:
	return balls.size()

func is_active(b: Ball) -> bool:
	return b.s >= path.enter_s

func active_count() -> int:
	var n: int = 0
	for b in balls:
		if b.s >= path.enter_s:
			n += 1
	return n

func front_s() -> float:
	return (balls[0] as Ball).s if balls.size() > 0 else -INF

func rear_s() -> float:
	return (balls[balls.size() - 1] as Ball).s if balls.size() > 0 else INF

func fully_entered() -> bool:
	return balls.size() == 0 or rear_s() >= path.enter_s

func world_pos(b: Ball) -> Vector2:
	return path.pos_at(b.s)

## Segment start indices (front-first).
func segments() -> Array:
	var segs: Array = []
	if balls.is_empty():
		return segs
	var start: int = 0
	for i in range(1, balls.size()):
		if not BubbleMatchSystem.contiguous(balls[i - 1], balls[i]):
			segs.append([start, i - 1])
			start = i
	segs.append([start, balls.size() - 1])
	return segs

## Advance by dt. speed: forward px/s of the driven rear segment (negative = reverse everything).
func step(dt: float, speed: float, front_limit: float = INF) -> void:
	time += dt
	var n: int = balls.size()
	if n == 0:
		return
	var segs: Array = segments()
	var vels: Array = []
	vels.resize(segs.size())
	for k in segs.size():
		vels[k] = 0.0
	if speed < 0.0:
		for k in segs.size():
			vels[k] = speed
	else:
		vels[segs.size() - 1] = speed
		if magnet_enabled:
			for k in range(segs.size() - 1):
				if _magnet_pair(segs[k][1], segs[k + 1][0]):
					vels[k] = -K.BACK_SPEED
	# front limit (shield / zen): the whole contiguous front segment may not pass it
	for k in segs.size():
		var v: float = vels[k]
		if v == 0.0:
			continue
		var s0: int = segs[k][0]
		var s1: int = segs[k][1]
		var d: float = v * dt
		if d > 0.0 and k == 0 and (balls[0] as Ball).s + d > front_limit:
			d = maxf(front_limit - (balls[0] as Ball).s, 0.0)
		elif d > 0.0 and k > 0:
			pass
		for i in range(s0, s1 + 1):
			(balls[i] as Ball).s += d
	# resolve overlaps rear -> front (pushing)
	for i in range(n - 2, -1, -1):
		var f: Ball = balls[i]
		var r: Ball = balls[i + 1]
		if f.s < r.s + K.BALL_D:
			# if gap closing, only snap when it is a real overlap (contact), preserving contiguity
			f.s = r.s + K.BALL_D
	if front_limit < INF and (balls[0] as Ball).s > front_limit:
		# push-back: keep chain behind the limit
		var over: float = (balls[0] as Ball).s - front_limit
		for b in balls:
			(b as Ball).s -= over
	# detect newly formed junctions
	var join_ids: Array[int] = []
	for i in range(1, n):
		var c: bool = BubbleMatchSystem.contiguous(balls[i - 1], balls[i])
		var rid: int = (balls[i] as Ball).id
		var was: bool = _prev_contig.get(rid, true)
		if c and not was:
			join_ids.append(rid)
		_prev_contig[rid] = c
	for rid2 in join_ids:
		# indices may shift after pops; re-find by id
		for j in range(1, balls.size()):
			if (balls[j] as Ball).id == rid2:
				_check_junction(j)
				break

func _magnet_pair(front_last: int, rear_first: int) -> bool:
	var a: Ball = balls[front_last]
	var b: Ball = balls[rear_first]
	if not a.matchable() or not b.matchable() or a.color != b.color:
		return false
	if a.s < path.enter_s or b.s < path.enter_s:
		return false
	var run_a: Array = BubbleMatchSystem.run_at(balls, front_last, path.enter_s)
	var run_b: Array = BubbleMatchSystem.run_at(balls, rear_first, path.enter_s)
	return (run_a[1] - run_a[0] + 1) + (run_b[1] - run_b[0] + 1) >= K.MIN_RUN

func _check_junction(i: int) -> void:
	# balls[i-1] and balls[i] just touched
	var a: Ball = balls[i - 1]
	var b: Ball = balls[i]
	if not a.matchable() or not b.matchable() or a.color != b.color:
		return
	if a.s < path.enter_s or b.s < path.enter_s:
		return
	var run: Array = BubbleMatchSystem.run_at(balls, i, path.enter_s)
	if run[1] - run[0] + 1 >= K.MIN_RUN:
		reaction_level += 1
		_pop_range(run[0], run[1], true, "magnet")

## Insert a new ball at list position k (between balls[k-1] and balls[k]).
func insert_at(k: int, b: Ball) -> int:
	k = clampi(k, 0, balls.size())
	if balls.is_empty():
		b.s = path.enter_s + K.BALL_D
		balls.append(b)
		return 0
	if k < balls.size() and k > 0 and BubbleMatchSystem.contiguous(balls[k - 1], balls[k]):
		b.s = (balls[k] as Ball).s + K.BALL_D
	elif k < balls.size() and k > 0:
		# gap on both sides: sit directly in front of the rear neighbour
		b.s = (balls[k] as Ball).s + K.BALL_D
	elif k == 0:
		b.s = (balls[0] as Ball).s + K.BALL_D
	else:
		b.s = (balls[k - 1] as Ball).s - K.BALL_D
	b.born = time
	balls.insert(k, b)
	_prev_contig[b.id] = true
	for j in range(k - 1, -1, -1):
		var f: Ball = balls[j]
		var r: Ball = balls[j + 1]
		if f.s < r.s + K.BALL_D:
			f.s = r.s + K.BALL_D
		else:
			break
	# the rear neighbour must not overlap either (when it was behind a gap but close)
	for j in range(k + 1, balls.size()):
		var f2: Ball = balls[j - 1]
		var r2: Ball = balls[j]
		if r2.s > f2.s - K.BALL_D:
			# only possible if b was placed behind a gap; shift rear part back
			var d: float = r2.s - (f2.s - K.BALL_D)
			for q in range(j, balls.size()):
				(balls[q] as Ball).s -= d
			break
	return k

## Resolve matches around list index i after an insert. Returns number of balls popped.
func resolve_insert(i: int) -> int:
	if i < 0 or i >= balls.size():
		return 0
	var b: Ball = balls[i]
	if not b.matchable() or b.s < path.enter_s:
		return 0
	var run: Array = BubbleMatchSystem.run_at(balls, i, path.enter_s)
	var len: int = run[1] - run[0] + 1
	if len >= K.MIN_RUN:
		return _pop_range(run[0], run[1], false, "shot")
	return 0

func _pop_range(i0: int, i1: int, junction: bool, source: String) -> int:
	var removed: Array = []
	var poss: PackedVector2Array = PackedVector2Array()
	var color: int = (balls[i0] as Ball).color
	for i in range(i0, i1 + 1):
		removed.append(balls[i])
		poss.append(world_pos(balls[i]))
	# bombs inside the run explode
	var extra: Array = []
	for b in removed:
		if (b as Ball).kind == K.KIND_BOMB:
			var c: Vector2 = world_pos(b)
			for o in balls:
				if o not in removed and o not in extra and (o as Ball).s >= path.enter_s and world_pos(o).distance_to(c) <= K.BOMB_RADIUS * 0.75:
					extra.append(o)
	# stones adjacent to the run take damage
	var stone_hits: Array = []
	for idx in [i0 - 1, i1 + 1]:
		if idx >= 0 and idx < balls.size():
			var nb: Ball = balls[idx]
			if nb.kind == K.KIND_STONE and nb not in removed:
				nb.hp -= 1
				stone_hits.append(nb)
	for sb in stone_hits:
		if (sb as Ball).hp <= 0:
			extra.append(sb)
	for e in extra:
		removed.append(e)
		poss.append(world_pos(e))
	_remove_balls(removed)
	var info: Dictionary = {"balls": removed, "positions": poss, "color": color, "junction": junction,
		"source": source, "level": reaction_level, "run": i1 - i0 + 1, "extra": extra.size(), "stone_hits": stone_hits}
	removed_total += removed.size()
	popped.emit(info)
	return removed.size()

func _remove_balls(list: Array) -> void:
	for b in list:
		balls.erase(b)
		_prev_contig.erase((b as Ball).id)

## Remove arbitrary balls (power-ups). Emits popped with source.
func remove_group(list: Array, source: String, color: int = -1) -> void:
	if list.is_empty():
		return
	var poss: PackedVector2Array = PackedVector2Array()
	for b in list:
		poss.append(world_pos(b))
	_remove_balls(list)
	removed_total += list.size()
	popped.emit({"balls": list, "positions": poss, "color": color, "junction": false, "source": source,
		"level": reaction_level, "run": list.size(), "extra": 0, "stone_hits": []})

func balls_within(center: Vector2, radius: float) -> Array:
	var out: Array = []
	for b in balls:
		if (b as Ball).s >= path.enter_s and world_pos(b).distance_to(center) <= radius:
			out.append(b)
	return out

func balls_of_color(c: int) -> Array:
	var out: Array = []
	for b in balls:
		if (b as Ball).s >= path.enter_s and (b as Ball).color == c:
			out.append(b)
	return out

func front_balls(n: int) -> Array:
	var out: Array = []
	for b in balls:
		if (b as Ball).s >= path.enter_s:
			out.append(b)
			if out.size() >= n:
				break
	return out

func colors_present() -> Array[int]:
	var seen: Dictionary = {}
	var out: Array[int] = []
	for b in balls:
		var bb: Ball = b
		if bb.s >= path.enter_s and bb.color >= 0 and not seen.has(bb.color):
			seen[bb.color] = true
			out.append(bb.color)
	return out

## Invariant check: strictly ordered, no overlap. Returns "" when valid.
func check_invariants() -> String:
	for i in range(1, balls.size()):
		var gap: float = (balls[i - 1] as Ball).s - (balls[i] as Ball).s
		if gap < K.BALL_D - 0.05:
			return "overlap %.3f at %d" % [gap, i]
	return ""

## Raycast of a moving projectile segment against active balls. Returns {idx, t} or {}.
func segment_hit(a: Vector2, b: Vector2, positions: PackedVector2Array) -> Dictionary:
	var best_t: float = INF
	var best_i: int = -1
	var ab: Vector2 = b - a
	var l2: float = ab.length_squared()
	for i in balls.size():
		if (balls[i] as Ball).s < path.enter_s:
			continue
		var c: Vector2 = positions[i]
		var t: float = 0.0 if l2 < 0.0001 else clampf((c - a).dot(ab) / l2, 0.0, 1.0)
		var d: float = (a + ab * t).distance_to(c)
		if d < K.HIT_RADIUS and t < best_t:
			best_t = t
			best_i = i
	if best_i < 0:
		return {}
	return {"idx": best_i, "t": best_t}
