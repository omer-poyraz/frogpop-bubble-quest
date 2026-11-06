class_name Difficulty
extends RefCounted
## Smooth, bounded (asymptotic) difficulty curve for the endless game.

const SPEED_MIN: float = 62.0
const SPEED_MAX: float = 152.0
const COUNT_MIN: int = 26
const COUNT_MAX: int = 82
const FILL_MAX: float = 0.62

static func is_boss(wave: int) -> bool:
	return wave >= 10 and wave % 10 == 0

static func speed(wave: int) -> float:
	return SPEED_MIN + (SPEED_MAX - SPEED_MIN) * (1.0 - exp(-float(wave) / 28.0))

static func ball_count(wave: int) -> int:
	return COUNT_MIN + int(float(COUNT_MAX - COUNT_MIN) * (1.0 - exp(-float(wave) / 22.0)))

static func color_count(wave: int) -> int:
	return clampi(4 + int(4.5 * (1.0 - exp(-float(wave) / 10.0))), 4, K.NORMAL_COLORS)

static func stone_chance(wave: int) -> float:
	if wave < 6: return 0.0
	return 0.05 * (1.0 - exp(-float(wave - 5) / 12.0))

static func bomb_chance(wave: int) -> float:
	return 0.0 if wave < 3 else 0.03

static func golden_chance(_wave: int) -> float:
	return 0.035

static func mode_speed_mul(mode: String) -> float:
	match mode:
		"zen": return 0.55
		"time": return 1.0
		_: return 1.0

## Build params for a wave of a mode.
static func params(wave: int, mode: String) -> Dictionary:
	var count: int = ball_count(wave)
	var boss: bool = is_boss(wave)
	if boss:
		count = mini(int(count * 1.12), COUNT_MAX + 8)
	if mode == "zen":
		count = int(count * 0.8)
	return {
		"wave": wave, "speed": speed(wave) * mode_speed_mul(mode), "count": count,
		"colors": color_count(wave), "stone": stone_chance(wave), "bomb": bomb_chance(wave),
		"golden": golden_chance(wave), "boss": boss}

## Pick the route type for a wave: deterministic, never the same as the previous wave.
static func route_type(wave: int, seed_value: int, prev_type: String) -> String:
	if is_boss(wave):
		return "boss"
	var pool: Array[String] = PathGenerator.types_for_wave(wave)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, wave, "route"])
	var t: String = pool[rng.randi() % pool.size()]
	if t == prev_type and pool.size() > 1:
		t = pool[(pool.find(t) + 1) % pool.size()]
	return t

## World (theme) index for a wave: 3 waves per world, themes rotate, never repeating back-to-back.
static func world_for_wave(wave: int, order: Array = []) -> int:
	var idx: int = int((wave - 1) / 3)
	if order.is_empty():
		return idx % K.WORLD_COUNT
	return int(order[idx % order.size()])

## Generate the initial colour/kind sequence (front-first), avoiding accidental 3-runs.
static func make_sequence(p: Dictionary, rng: RandomNumberGenerator, max_count: int) -> Dictionary:
	var count: int = mini(int(p["count"]), max_count)
	var ncol: int = int(p["colors"])
	var palette: Array[int] = []
	for i in K.NORMAL_COLORS:
		palette.append(i)
	# per-wave palette shuffle so colour roles vary
	for i in range(palette.size() - 1, 0, -1):
		var j: int = rng.randi() % (i + 1)
		var tmp: int = palette[i]
		palette[i] = palette[j]
		palette[j] = tmp
	palette = palette.slice(0, ncol)
	var colors: Array[int] = []
	var kinds: Array = []
	var prev: int = -1
	var prev2: int = -1
	for i in count:
		var c: int = palette[rng.randi() % palette.size()]
		if rng.randf() < 0.36 and prev >= 0:
			c = prev
		if c == prev and c == prev2:
			var alt: Array[int] = []
			for pc in palette:
				if pc != c:
					alt.append(pc)
			c = alt[rng.randi() % alt.size()]
		var kind: int = K.KIND_NORMAL
		var gold: int = 0
		var r: float = rng.randf()
		if i > 6 and i < count - 4:
			if r < float(p["stone"]):
				kind = K.KIND_STONE
			elif r < float(p["stone"]) + float(p["bomb"]):
				kind = K.KIND_BOMB
			elif r < float(p["stone"]) + float(p["bomb"]) + float(p["golden"]):
				gold = 4
		colors.append(c)
		kinds.append(kind | gold)
		if kind == K.KIND_STONE:
			prev2 = prev
			prev = -1
		else:
			prev2 = prev
			prev = c
	return {"colors": colors, "kinds": kinds, "palette": palette}
