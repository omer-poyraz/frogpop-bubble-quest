extends RefCounted

func _mk(colors: Array[int], s0: float = 900.0) -> BubbleChainManager:
	var pd: PathData = PathGenerator.generate("snake", 3)
	var ch := BubbleChainManager.new()
	ch.setup(pd, colors)
	for i in ch.balls.size():
		(ch.balls[i] as Ball).s = s0 - float(i) * K.BALL_D
	return ch

func test_insert_pushes_front_and_keeps_invariant(t: Node) -> void:
	var ch: BubbleChainManager = _mk([0, 1, 2, 3, 4])
	var fronts: Array[float] = []
	for b in ch.balls:
		fronts.append((b as Ball).s)
	ch.insert_at(2, Ball.new(5, 0.0))
	t.check(ch.count() == 6, "count")
	t.check(ch.check_invariants() == "", "no overlap after insert: " + ch.check_invariants())
	t.approx((ch.balls[0] as Ball).s, fronts[0] + K.BALL_D, 0.01, "front ball pushed by one diameter")
	t.approx((ch.balls[4] as Ball).s, fronts[3], 0.01, "rear balls stay")

func test_three_in_row_pops(t: Node) -> void:
	var ch: BubbleChainManager = _mk([0, 1, 1, 2, 3])
	var info: Array = []
	ch.popped.connect(func(i: Dictionary) -> void: info.append(i))
	var idx: int = ch.insert_at(3, Ball.new(1, 0.0))
	var n: int = ch.resolve_insert(idx)
	t.check(n == 3, "3 popped, got %d" % n)
	t.check(ch.count() == 3, "remaining 3")
	t.check(info.size() == 1 and info[0]["source"] == "shot", "popped signal")

func test_two_in_row_does_not_pop(t: Node) -> void:
	var ch: BubbleChainManager = _mk([0, 1, 2, 3, 4])
	var idx: int = ch.insert_at(2, Ball.new(1, 0.0))
	t.check(ch.resolve_insert(idx) == 0, "pair must not pop")
	t.check(ch.count() == 6, "kept")

func test_gap_stops_front_and_rear_closes(t: Node) -> void:
	var ch: BubbleChainManager = _mk([0, 1, 2, 3, 4, 5], 1200.0)
	var front_before: float = (ch.balls[0] as Ball).s
	ch.remove_group([ch.balls[2]], "test")  # gap in the middle
	var rear_before: float = ch.rear_s()
	for i in 30:
		ch.step(K.STEP, 100.0)
	t.approx((ch.balls[0] as Ball).s, front_before, 0.001, "front segment standing still")
	t.check(ch.rear_s() > rear_before, "rear moves")
	for i in 300:
		ch.step(K.STEP, 100.0)
	t.check(ch.check_invariants() == "", "no overlap while closing")
	t.check(BubbleMatchSystem.contiguous(ch.balls[1], ch.balls[2]), "gap closed")

func test_magnet_pulls_back_and_chain_reacts(t: Node) -> void:
	# R R | B | R G : popping B should pull R R back, merge with R, pop 3
	var ch: BubbleChainManager = _mk([0, 0, 1, 0, 2], 1500.0)
	var pops: Array = []
	ch.popped.connect(func(i: Dictionary) -> void: pops.append(i))
	ch.remove_group([ch.balls[2]], "test")
	var guard: int = 0
	while ch.count() > 1 and guard < 4000:
		ch.step(K.STEP, 90.0)
		guard += 1
		t.check(ch.check_invariants() == "", "invariant during magnet")
	t.check(ch.count() == 1, "three reds popped by magnet (count %d)" % ch.count())
	t.check(pops.size() >= 2 and pops[pops.size() - 1]["source"] == "magnet", "magnet pop")
	t.check(ch.reaction_level >= 1, "reaction level")

func test_no_magnet_for_different_colours(t: Node) -> void:
	var ch: BubbleChainManager = _mk([0, 0, 1, 2, 2], 1500.0)
	ch.remove_group([ch.balls[2]], "test")
	var f0: float = (ch.balls[0] as Ball).s
	for i in 40:
		ch.step(K.STEP, 90.0)
	t.approx((ch.balls[0] as Ball).s, f0, 0.001, "front does not move back")

func test_stone_takes_two_hits(t: Node) -> void:
	var pd: PathData = PathGenerator.generate("snake", 3)
	var ch := BubbleChainManager.new()
	ch.setup(pd, [0, 1, 1, 0, 2] as Array[int], [0, 0, 0, K.KIND_STONE, 0])
	for i in ch.balls.size():
		(ch.balls[i] as Ball).s = 900.0 - float(i) * K.BALL_D
	# make the 4th ball a stone adjacent to a run of colour 1 (indices 1,2)
	var idx: int = ch.insert_at(2, Ball.new(1, 0.0))
	ch.resolve_insert(idx)
	var stone: Ball = null
	for b in ch.balls:
		if (b as Ball).kind == K.KIND_STONE:
			stone = b
	t.check(stone != null and stone.hp == 1, "stone cracked (hp %d)" % (stone.hp if stone else -1))

func test_bomb_ball_explodes_neighbours(t: Node) -> void:
	var pd: PathData = PathGenerator.generate("snake", 3)
	var ch := BubbleChainManager.new()
	ch.setup(pd, [3, 4, 1, 1, 5, 6, 7, 3, 4] as Array[int], [0, 0, K.KIND_BOMB, 0, 0, 0, 0, 0, 0])
	for i in ch.balls.size():
		(ch.balls[i] as Ball).s = 1000.0 - float(i) * K.BALL_D
	var idx: int = ch.insert_at(4, Ball.new(1, 0.0))
	ch.resolve_insert(idx)
	t.check(ch.count() < 6, "bomb removed extra balls (left %d)" % ch.count())

func test_segment_hit_no_tunnelling(t: Node) -> void:
	var ch: BubbleChainManager = _mk([0, 1, 2, 3], 900.0)
	var pos := PackedVector2Array()
	for b in ch.balls:
		pos.append(ch.world_pos(b))
	# a fast long segment passing through a ball must hit it
	var c: Vector2 = pos[1]
	var h: Dictionary = ch.segment_hit(c + Vector2(-500, 3), c + Vector2(500, 3), pos)
	t.check(not h.is_empty(), "long segment hits")
