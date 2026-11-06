extends SceneTree
func _init() -> void:
	var out: Dictionary = {}
	for t in PathGenerator.TYPES:
		for sd in [1, 2, 3]:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash([t, sd, 0])
			var pd: PathData = PathGenerator._build(t, rng, 0)
			var reason: String = PathGenerator.validate(pd)
			var pts: Array = []
			for i in range(0, pd.pts.size(), 5):
				pts.append([snappedf(pd.pts[i].x, 0.1), snappedf(pd.pts[i].y, 0.1)])
			print("%s seed %d len %.0f enter %.0f minR %.0f reach %.2f %s" % [t, sd, pd.length, pd.enter_s, pd.min_radius, pd.reach, reason])
			out["%s_%d" % [t, sd]] = {"pts": pts, "frog": [pd.frog_pos.x, pd.frog_pos.y], "enter": pd.enter_s, "reason": reason}
	var f := FileAccess.open("res://build/paths.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	quit()
