extends RefCounted

func test_all_route_types_valid(t: Node) -> void:
	for type in PathGenerator.TYPES:
		for sd in [1, 2, 3, 17, 99, 12345]:
			var pd: PathData = PathGenerator.generate(type, sd)
			var reason: String = PathGenerator.validate(pd)
			t.check(reason == "", "%s seed %d invalid: %s" % [type, sd, reason])
			t.check(pd.length - pd.enter_s >= PathGenerator.MIN_LENGTH, "%s long enough" % type)
			t.check(pd.min_radius >= PathGenerator.MIN_RADIUS - 0.5, "%s curvature" % type)
			t.check(pd.reach >= PathGenerator.MIN_REACH, "%s reach" % type)

func test_route_is_deterministic(t: Node) -> void:
	var a: PathData = PathGenerator.generate("spiral", 42)
	var b: PathData = PathGenerator.generate("spiral", 42)
	t.check(a.pts.size() == b.pts.size() and a.length == b.length, "same seed => same route")
	var c: PathData = PathGenerator.generate("wave", 43)
	var d: PathData = PathGenerator.generate("wave", 44)
	t.check(c.kind == "wave" and d.kind == "wave", "types honoured")

func test_length_table_continuity(t: Node) -> void:
	for type in ["spiral", "snake", "heart", "cross", "labyrinth"]:
		var pd: PathData = PathGenerator.generate(type, 7)
		var prev: Vector2 = pd.pos_at(0.0)
		var worst: float = 0.0
		var s: float = 1.0
		while s < pd.length:
			var p: Vector2 = pd.pos_at(s)
			worst = maxf(worst, p.distance_to(prev))
			prev = p
			s += 1.0
		t.check(worst < 1.2, "%s step continuity %.3f" % [type, worst])
		# cumulative table strictly monotonic
		var mono: bool = true
		for i in range(1, pd.cum.size()):
			if pd.cum[i] < pd.cum[i - 1]:
				mono = false
		t.check(mono, "%s cum monotonic" % type)
		t.approx(pd.pos_at(pd.length).distance_to(pd.pts[pd.pts.size() - 1]), 0.0, 0.01, "end pos")

func test_nearest_s_roundtrip(t: Node) -> void:
	var pd: PathData = PathGenerator.generate("snake", 5)
	for s in [300.0, 900.0, 1700.0, 2600.0]:
		var p: Vector2 = pd.pos_at(s)
		t.approx(pd.nearest_s(p, s, 200.0), s, 1.5, "nearest_s")
		t.approx(pd.nearest_s(p), s, 1.5, "nearest_s global")

func test_start_is_offscreen_and_hole_visible(t: Node) -> void:
	for type in PathGenerator.TYPES:
		var pd: PathData = PathGenerator.generate(type, 11)
		var p0: Vector2 = pd.pos_at(0.0)
		t.check(not Rect2(0, 0, K.FIELD_W, K.FIELD_H).has_point(p0), "%s starts off-screen" % type)
		var end: Vector2 = pd.pos_at(pd.length)
		t.check(PathGenerator.FIELD.has_point(end), "%s hole inside playfield" % type)
		t.check(end.distance_to(pd.frog_pos) >= K.FROG_CLEAR, "%s hole clear of frog" % type)
