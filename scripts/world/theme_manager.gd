extends Node
## Loads data/themes/*.json. A new world = a new JSON (+ decor style); no gameplay change needed.

signal theme_changed(index: int)

var themes: Array = []
var current: int = 0
var variant: int = 0
var order_cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reload()

func reload() -> void:
	themes.clear()
	var dir: DirAccess = DirAccess.open("res://data/themes")
	if dir == null:
		return
	var files: Array[String] = []
	for f in dir.get_files():
		if f.ends_with(".json"):
			files.append(f)
	files.sort()
	for f in files:
		var txt: String = FileAccess.get_file_as_string("res://data/themes/" + f)
		var d: Variant = JSON.parse_string(txt)
		if typeof(d) == TYPE_DICTIONARY:
			themes.append(d)

func count() -> int:
	return themes.size()

func get_theme(i: int) -> Dictionary:
	if themes.is_empty():
		return {}
	return themes[posmod(i, themes.size())]

func color_of(i: int, key: String, idx: int = -1) -> Color:
	var t: Dictionary = get_theme(i)
	if idx >= 0:
		return Color(str(t[key][idx]))
	return Color(str(t[key]))

## Deterministic world order: shuffled cycles, never repeating the same world back-to-back.
func world_for_wave(wave: int, seed_value: int) -> int:
	var n: int = maxi(themes.size(), 1)
	var group: int = int((wave - 1) / 3)
	var cycle: int = int(group / n)
	var order: Array = _cycle_order(cycle, seed_value, n)
	return int(order[group % n])

func variant_for_wave(wave: int, seed_value: int) -> int:
	return int(hash([seed_value, wave / 3, "bgv"]) % K.BG_VARIANTS)

func _cycle_order(cycle: int, seed_value: int, n: int) -> Array:
	var key: String = "%d_%d" % [seed_value, cycle]
	if order_cache.has(key):
		return order_cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, cycle, "world"])
	var arr: Array = []
	for i in n:
		arr.append(i)
	if cycle == 0:
		# first cycle is the natural showcase order
		order_cache[key] = arr
		return arr
	for i in range(n - 1, 0, -1):
		var j: int = rng.randi() % (i + 1)
		var t: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = t
	var prev: Array = _cycle_order(cycle - 1, seed_value, n)
	if arr[0] == prev[n - 1] and n > 1:
		var t2: Variant = arr[0]
		arr[0] = arr[1]
		arr[1] = t2
	order_cache[key] = arr
	return arr
