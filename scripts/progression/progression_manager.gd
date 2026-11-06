extends Node
## Daily rewards, missions, achievements, costumes, stats. All local; clock-rollback guarded.

signal coins_changed(total: int)
signal achievement_unlocked(id: String)
signal mission_completed(id: String)
signal skin_changed(id: String)

const DAY_SECONDS: int = 86400
const DAILY_TABLE: Array = [
	{"coins": 60}, {"power": "slow", "n": 1}, {"coins": 100}, {"power": "bomb", "n": 1},
	{"coins": 150}, {"power": "lightning", "n": 1}, {"coins": 250, "power": "rainbow", "n": 1}]

var achievements: Array = []
var skins: Array = []
var mission_templates: Array = []
var time_offset_for_tests: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	achievements = _load_json("res://data/progression/achievements.json")
	skins = _load_json("res://data/progression/skins.json")
	mission_templates = _load_json("res://data/missions/missions.json")
	ensure_missions()

func _load_json(p: String) -> Array:
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	return v if typeof(v) == TYPE_ARRAY else []

# ---------- time (with rollback protection) ----------
func now_unix() -> int:
	var real: int = int(Time.get_unix_time_from_system()) + time_offset_for_tests
	var d: Dictionary = SaveManager.data["daily"]
	var seen: int = int(d.get("last_seen_unix", 0))
	var eff: int = maxi(real, seen)
	if real > seen:
		d["last_seen_unix"] = real
		SaveManager.mark_dirty()
	return eff

func clock_rolled_back() -> bool:
	var real: int = int(Time.get_unix_time_from_system()) + time_offset_for_tests
	return real + 600 < int(SaveManager.data["daily"].get("last_seen_unix", 0))

func date_str(unix: int = -1) -> String:
	if unix < 0:
		unix = now_unix()
	var bias: int = int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var dt: Dictionary = Time.get_date_dict_from_unix_time(unix + bias)
	return "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]

func week_str(unix: int = -1) -> String:
	if unix < 0:
		unix = now_unix()
	return "w%d" % int(unix / (DAY_SECONDS * 7))

func daily_seed() -> int:
	return hash(date_str() + "frogpop")

# ---------- daily login reward ----------
func daily_info() -> Dictionary:
	var d: Dictionary = SaveManager.data["daily"]
	var today: String = date_str()
	var last: String = str(d["last_claim_date"])
	var claimed_today: bool = last == today
	var streak: int = int(d["streak"])
	var continues: bool = last == date_str(now_unix() - DAY_SECONDS)
	var next_day: int = 1
	if claimed_today:
		next_day = (streak % 7) + 1
	elif continues:
		next_day = (streak % 7) + 1
	return {"can_claim": not claimed_today and not clock_rolled_back(), "claimed_today": claimed_today,
		"streak": streak, "day": next_day if not claimed_today else ((streak - 1) % 7) + 1, "rolled_back": clock_rolled_back()}

func claim_daily() -> Dictionary:
	var info: Dictionary = daily_info()
	if not info["can_claim"]:
		return {}
	var d: Dictionary = SaveManager.data["daily"]
	var today: String = date_str()
	var continues: bool = str(d["last_claim_date"]) == date_str(now_unix() - DAY_SECONDS)
	d["streak"] = (int(d["streak"]) + 1) if continues else 1
	d["last_claim_date"] = today
	d["claims"] = int(d["claims"]) + 1
	var reward: Dictionary = (DAILY_TABLE[(int(d["streak"]) - 1) % 7] as Dictionary).duplicate()
	if is_pro() and reward.has("coins"):
		reward["coins"] = int(reward["coins"] * 1.5)
	if reward.has("coins"):
		add_coins(int(reward["coins"]))
	if reward.has("power"):
		add_power(str(reward["power"]), int(reward.get("n", 1)))
	SaveManager.save()
	check_achievements()
	return reward

# ---------- coins / powers ----------
func add_coins(n: int) -> void:
	SaveManager.add_coins(n)
	coins_changed.emit(coins())

func coins() -> int:
	return int(SaveManager.data["coins"])

func add_power(p: String, n: int = 1) -> void:
	var pw: Dictionary = SaveManager.data["powers"]
	pw[p] = int(pw.get(p, 0)) + n
	SaveManager.mark_dirty()

func power_count(p: String) -> int:
	return int(SaveManager.data["powers"].get(p, 0))

func buy_power(p: String) -> bool:
	var price: int = int(K.POWER_PRICE.get(p, 9999))
	if SaveManager.spend_coins(price):
		add_power(p, 1)
		coins_changed.emit(coins())
		SaveManager.save()
		return true
	return false

func is_pro() -> bool:
	return bool(SaveManager.data["pro"]["active"])

func set_pro(active: bool, kind: String = "") -> void:
	SaveManager.data["pro"] = {"active": active, "kind": kind, "since": now_unix() if active else 0}
	if active:
		SaveManager.data["remove_ads"] = true
	SaveManager.save()

# ---------- skins ----------
func skin_def(id: String) -> Dictionary:
	for s in skins:
		if s["id"] == id:
			return s
	return {}

func is_skin_unlocked(id: String) -> bool:
	var def: Dictionary = skin_def(id)
	if def.is_empty():
		return false
	if def.get("pro_only", false) and is_pro():
		return true
	return (SaveManager.data["unlocked_skins"] as Array).has(id)

func can_use_skin(id: String) -> bool:
	return is_skin_unlocked(id)

func buy_skin(id: String) -> bool:
	var def: Dictionary = skin_def(id)
	if def.is_empty() or is_skin_unlocked(id) or def["unlock"] != "coins":
		return false
	if SaveManager.spend_coins(int(def["price"])):
		(SaveManager.data["unlocked_skins"] as Array).append(id)
		coins_changed.emit(coins())
		SaveManager.save()
		return true
	return false

func select_skin(id: String) -> bool:
	if not can_use_skin(id):
		return false
	SaveManager.data["selected_skin"] = id
	SaveManager.mark_dirty()
	skin_changed.emit(id)
	return true

func selected_skin() -> String:
	var id: String = str(SaveManager.data["selected_skin"])
	return id if can_use_skin(id) else "classic"

func select_theme(i: int) -> bool:
	if i >= 0:
		var t: Dictionary = ThemeManager.get_theme(i)
		if t.get("pro_only", false) and not is_pro():
			return false
		if not (SaveManager.data["unlocked_themes"] as Array).has(i):
			return false
	SaveManager.data["selected_theme"] = i
	SaveManager.mark_dirty()
	return true

# ---------- missions ----------
func ensure_missions() -> void:
	var m: Dictionary = SaveManager.data["missions"]
	var today: String = date_str()
	if str(m["date"]) != today or (m["list"] as Array).is_empty():
		m["date"] = today
		m["list"] = _gen_missions(3, 1.0, hash(today))
	var wk: String = week_str()
	if str(m["week"]) != wk or (m["weekly"] as Array).is_empty():
		m["week"] = wk
		m["weekly"] = _gen_missions(2, 6.0, hash(wk))
	SaveManager.mark_dirty()

func _gen_missions(n: int, mult: float, sd: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	var pool: Array = mission_templates.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j: int = rng.randi() % (i + 1)
		var tmp: Variant = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var level: int = mini(int(SaveManager.data["games_played"]) / 8, 5)
	var out: Array = []
	for i in mini(n, pool.size()):
		var t: Dictionary = pool[i]
		var cumulative: bool = t["stat"] in ["balls", "games", "powers"]
		var target: float = float(t["base"]) + float(t["scale"]) * level
		if mult > 1.0:
			target = target * (mult if cumulative else mult * 0.4)
		out.append({"id": t["id"], "stat": t["stat"], "key": t["key"], "target": int(maxf(target, 1.0)),
			"progress": 0, "coins": int(float(t["coins"]) * (1.0 if mult == 1.0 else 3.0)), "claimed": false})
	return out

func _apply_mission_stats(list: Array, info: Dictionary) -> Array:
	var done: Array = []
	for m in list:
		if m["claimed"]:
			continue
		var before: int = int(m["progress"])
		var v: int = 0
		match str(m["stat"]):
			"balls": v = before + int(info["balls"])
			"wave": v = maxi(before, int(info["wave"]))
			"score": v = maxi(before, int(info["score"]))
			"combo": v = maxi(before, int(info["best_combo"]))
			"games": v = before + 1
			"powers": v = before + int(info["powers_used"])
			"chain": v = maxi(before, int(info["best_chain"]))
		m["progress"] = v
		if before < int(m["target"]) and v >= int(m["target"]):
			done.append(m["id"])
			mission_completed.emit(m["id"])
	return done

func claim_mission(weekly: bool, idx: int) -> bool:
	var list: Array = SaveManager.data["missions"]["weekly" if weekly else "list"]
	if idx < 0 or idx >= list.size():
		return false
	var m: Dictionary = list[idx]
	if m["claimed"] or int(m["progress"]) < int(m["target"]):
		return false
	m["claimed"] = true
	add_coins(int(m["coins"]))
	SaveManager.save()
	return true

# ---------- game end ----------
## info comes from GameCore.game_over. Returns {record, new_achievements, coins}.
func report_game(info: Dictionary) -> Dictionary:
	ensure_missions()
	var d: Dictionary = SaveManager.data
	var score: int = int(info["score"])
	var record: bool = score > int(d["high_score"]) and str(info.get("mode", "classic")) != "zen"
	if record:
		d["high_score"] = score
	d["total_score"] = int(d["total_score"]) + score
	d["games_played"] = int(d["games_played"]) + 1
	d["play_time"] = float(d["play_time"]) + float(info["time"])
	d["best_wave"] = maxi(int(d["best_wave"]), int(info["wave"]))
	d["balls_popped"] = int(d["balls_popped"]) + int(info["balls"])
	d["best_chain"] = maxi(int(d["best_chain"]), int(info["best_chain"]))
	d["best_combo"] = maxi(int(d["best_combo"]), int(info["best_combo"]))
	d["powers_used"] = int(d["powers_used"]) + int(info["powers_used"])
	var earned: int = int(info["coins"])
	if is_pro():
		earned = int(earned * 1.5)
	add_coins(earned)
	var unlocked_themes: Array = d["unlocked_themes"]
	for w in range(0, mini(int(info["wave"]), 3 * K.WORLD_COUNT)):
		var world: int = ThemeManager.world_for_wave(w + 1, 1)
		if not unlocked_themes.has(world):
			unlocked_themes.append(world)
	var done_d: Array = _apply_mission_stats(d["missions"]["list"], info)
	var done_w: Array = _apply_mission_stats(d["missions"]["weekly"], info)
	var new_ach: Array = check_achievements()
	if str(info.get("mode", "")) == "daily":
		var dc: Dictionary = d["daily_challenge"]
		if str(dc["date"]) != date_str():
			dc["date"] = date_str()
			dc["best"] = 0
			dc["done"] = false
		dc["best"] = maxi(int(dc["best"]), score)
		if info["reason"] == "daily_done" and not dc["done"]:
			dc["done"] = true
			add_coins(150)
			earned += 150
	SaveManager.save()
	return {"record": record, "achievements": new_ach, "coins": earned, "missions": done_d + done_w}

# ---------- achievements ----------
func stat_value(stat: String) -> float:
	var d: Dictionary = SaveManager.data
	if stat == "daily_claims":
		return float(d["daily"]["claims"])
	return float(d.get(stat, 0))

func check_achievements() -> Array:
	var got: Array = []
	var ach: Dictionary = SaveManager.data["achievements"]
	for a in achievements:
		if ach.has(a["id"]):
			continue
		if stat_value(str(a["stat"])) >= float(a["target"]):
			ach[a["id"]] = int(Time.get_unix_time_from_system())
			add_coins(int(a["coins"]))
			got.append(a["id"])
			achievement_unlocked.emit(a["id"])
			for s in skins:
				if s.get("unlock", "") == "achievement" and s.get("achievement", "") == a["id"]:
					var us: Array = SaveManager.data["unlocked_skins"]
					if not us.has(s["id"]):
						us.append(s["id"])
	if not got.is_empty():
		SaveManager.mark_dirty()
	return got

func achievement_progress(a: Dictionary) -> float:
	return minf(stat_value(str(a["stat"])) / float(a["target"]), 1.0)
