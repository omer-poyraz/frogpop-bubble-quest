extends SceneTree
func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var raw: PackedVector2Array = PathGenerator._heart(rng)
	print("raw n=", raw.size())
	var worst: float = 0.0
	for i in range(1, raw.size() - 1):
		var a: float = absf((raw[i] - raw[i-1]).angle_to(raw[i+1] - raw[i]))
		var l: float = raw[i].distance_to(raw[i-1])
		if a / maxf(l, 0.1) > 0.02:
			print(i, " ang ", a, " seg ", l, " ", raw[i])
	quit()
