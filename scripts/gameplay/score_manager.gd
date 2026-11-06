class_name ScoreManager
extends RefCounted
## Score, multipliers and achievement-style bonuses. Labels are localisation keys.

var score: int = 0
var coins_earned: int = 0
var best_chain: int = 0
var best_combo: int = 0
var balls_popped: int = 0
var perfect_shots: int = 0
var last_second_saves: int = 0

func reset() -> void:
	score = 0
	coins_earned = 0
	best_chain = 0
	best_combo = 0
	balls_popped = 0
	perfect_shots = 0
	last_second_saves = 0

## Returns {"points", "labels": Array[String], "big": bool, "golden": int}
func award(info: Dictionary, streak: int, danger: float) -> Dictionary:
	var n: int = (info["balls"] as Array).size()
	var run: int = int(info["run"])
	var level: int = int(info["level"])
	var labels: Array[String] = []
	var base: int = n * 10 + maxi(run - 3, 0) * 15
	var mult: float = 1.0 + 0.5 * float(level) + minf(float(streak), 10.0) * 0.08
	var golden: int = 0
	for b in info["balls"]:
		if (b as Ball).golden:
			golden += 1
	var pts: int = int(round(float(base) * mult))
	var big: bool = false
	if level >= 3:
		labels.append("sc_chain_reaction")
		big = true
	elif level == 2:
		labels.append("sc_triple")
		big = true
	elif level == 1:
		labels.append("sc_double")
		big = true
	if run >= 5 and level == 0:
		labels.append("sc_perfect")
		pts += 100
		perfect_shots += 1
		big = true
	if streak >= 5 and streak % 5 == 0:
		labels.append("sc_streak")
		pts += 25 * streak
		big = true
	if golden > 0:
		labels.append("sc_golden")
		pts += 150 * golden
		coins_earned += golden * 2
		big = true
	if danger > 0.88:
		labels.append("sc_last_second")
		pts += 300
		last_second_saves += 1
		big = true
	if str(info["source"]) == "lightning" or str(info["source"]) == "rainbow" or str(info["source"]) == "bomb":
		big = true
	score += pts
	balls_popped += n
	best_chain = maxi(best_chain, level + 1)
	best_combo = maxi(best_combo, streak)
	coins_earned += n / 6
	return {"points": pts, "labels": labels, "big": big, "golden": golden}
