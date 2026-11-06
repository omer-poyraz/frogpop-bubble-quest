extends SceneTree
func _init() -> void:
	var fails: Array = []
	var fallback_used: int = 0
	for t in PathGenerator.TYPES:
		for sd in 400:
			var seed_v: int = hash([9100 + sd * 37, sd]) 
			var ok: bool = false
			var reason: String = ""
			for attempt in 12:
				var rng := RandomNumberGenerator.new()
				rng.seed = hash([t, seed_v, attempt])
				var pd: PathData = PathGenerator._build(t, rng, attempt)
				if pd == null:
					continue
				reason = PathGenerator.validate(pd)
				if reason == "":
					ok = true
					break
			if not ok:
				fallback_used += 1
				fails.append("%s seed %d last reason %s" % [t, seed_v, reason])
	print("FALLBACKS ", fallback_used)
	for f in fails.slice(0, 10):
		print(f)
	quit()
