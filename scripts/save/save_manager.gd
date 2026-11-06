extends Node
## JSON save with atomic write, checksum, rolling backup and validation.

signal saved()
signal loaded()

const SAVE_PATH: String = "user://frogpop_save.json"
const BACKUP_PATH: String = "user://frogpop_save.bak.json"
const TMP_PATH: String = "user://frogpop_save.tmp"
const VERSION: int = 1

var data: Dictionary = {}
var path_override: String = ""   # tests
var recovered_from_backup: bool = false
var corrupt_detected: bool = false
var _dirty: bool = false
var _autosave_t: float = 0.0

static func defaults() -> Dictionary:
	return {
		"v": VERSION,
		"high_score": 0, "total_score": 0, "games_played": 0, "play_time": 0.0, "coins": 200,
		"best_wave": 0, "balls_popped": 0, "best_chain": 0, "best_combo": 0, "powers_used": 0,
		"unlocked_skins": ["classic"], "selected_skin": "classic",
		"unlocked_themes": [0], "selected_theme": -1,
		"achievements": {},
		"daily": {"last_claim_date": "", "streak": 0, "claims": 0, "last_seen_unix": 0},
		"missions": {"date": "", "list": [], "week": "", "weekly": []},
		"daily_challenge": {"date": "", "best": 0, "done": false},
		"settings": {"music": 0.7, "sfx": 0.9, "mute": false, "vibration": true, "quality": 2, "language": "", "colorblind": false, "aim_line": true},
		"pro": {"active": false, "kind": "", "since": 0},
		"remove_ads": false,
		"powers": {"rainbow": 1, "bomb": 2, "slow": 2, "switch": 2, "lightning": 1, "shield": 1, "backward": 1},
		"ads": {"games_since_ad": 0, "last_ad_unix": 0},
		"tutorial_done": false,
		"first_run_unix": 0,
	}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game()

func _p(base: String) -> String:
	if path_override == "":
		return base
	return base.replace("user://", path_override)

func _process(delta: float) -> void:
	if _dirty:
		_autosave_t += delta
		if _autosave_t > 4.0:
			save()

func mark_dirty() -> void:
	_dirty = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save()

static func checksum(d: Dictionary) -> int:
	var copy: Dictionary = d.duplicate(true)
	copy.erase("sum")
	return hash(_canon(copy))

## Canonical text form: sorted keys, whole floats printed as ints (JSON round trip turns ints into floats).
static func _canon(v: Variant) -> String:
	match typeof(v):
		TYPE_DICTIONARY:
			var keys: Array = (v as Dictionary).keys()
			keys.sort()
			var parts: PackedStringArray = PackedStringArray()
			for k in keys:
				parts.append(str(k) + ":" + _canon(v[k]))
			return "{" + ",".join(parts) + "}"
		TYPE_ARRAY:
			var parts2: PackedStringArray = PackedStringArray()
			for e in v:
				parts2.append(_canon(e))
			return "[" + ",".join(parts2) + "]"
		TYPE_FLOAT:
			var f: float = v
			if is_equal_approx(f, round(f)) and absf(f) < 1.0e15:
				return str(int(round(f)))
			return "%.6f" % f
		TYPE_INT:
			return str(v)
		TYPE_BOOL:
			return "true" if v else "false"
		_:
			return "\"" + str(v) + "\""

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var txt: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		corrupt_detected = true
		return {}
	var d: Dictionary = parsed
	if not d.has("sum") or int(d["sum"]) != checksum(d):
		corrupt_detected = true
		return {}
	return d

func load_game() -> void:
	recovered_from_backup = false
	corrupt_detected = false
	var d: Dictionary = _read(_p(SAVE_PATH))
	if d.is_empty():
		d = _read(_p(BACKUP_PATH))
		if not d.is_empty():
			recovered_from_backup = true
	if d.is_empty():
		data = defaults()
		data["first_run_unix"] = int(Time.get_unix_time_from_system())
	else:
		data = validate(d)
	loaded.emit()

## Merge with defaults and clamp critical values.
static func validate(d: Dictionary) -> Dictionary:
	var out: Dictionary = defaults()
	for k in d:
		if out.has(k) and typeof(out[k]) == typeof(d[k]):
			if typeof(out[k]) == TYPE_DICTIONARY:
				var merged: Dictionary = (out[k] as Dictionary).duplicate(true)
				for kk in (d[k] as Dictionary):
					merged[kk] = d[k][kk]
				out[k] = merged
			else:
				out[k] = d[k]
		elif out.has(k) and typeof(out[k]) == TYPE_INT and typeof(d[k]) == TYPE_FLOAT:
			out[k] = int(d[k])
		elif out.has(k) and typeof(out[k]) == TYPE_FLOAT and typeof(d[k]) == TYPE_INT:
			out[k] = float(d[k])
	for k in ["high_score", "total_score", "games_played", "coins", "best_wave", "balls_popped", "best_chain", "best_combo", "powers_used"]:
		out[k] = maxi(int(out[k]), 0)
	out["play_time"] = maxf(float(out["play_time"]), 0.0)
	var skins: Array = out["unlocked_skins"]
	if not skins.has("classic"):
		skins.append("classic")
	if not skins.has(out["selected_skin"]):
		out["selected_skin"] = "classic"
	var themes: Array = out["unlocked_themes"]
	if themes.is_empty():
		themes.append(0)
	var st: Dictionary = out["settings"]
	st["music"] = clampf(float(st["music"]), 0.0, 1.0)
	st["sfx"] = clampf(float(st["sfx"]), 0.0, 1.0)
	st["quality"] = clampi(int(st["quality"]), 0, 2)
	var pw: Dictionary = out["powers"]
	for p in K.POWERS:
		pw[p] = clampi(int(pw.get(p, 0)), 0, 999)
	return out

func save() -> bool:
	_dirty = false
	_autosave_t = 0.0
	data["v"] = VERSION
	data.erase("sum")
	data["sum"] = checksum(data)
	var txt: String = JSON.stringify(data, "", true)
	var main_path: String = _p(SAVE_PATH)
	var tmp: FileAccess = FileAccess.open(_p(TMP_PATH), FileAccess.WRITE)
	if tmp == null:
		return false
	tmp.store_string(txt)
	tmp.close()
	# rotate current good file into backup, then move tmp into place
	if FileAccess.file_exists(main_path):
		var old: Dictionary = _read(main_path)
		if not old.is_empty():
			DirAccess.copy_absolute(main_path, _p(BACKUP_PATH))
	var err: int = DirAccess.rename_absolute(_p(TMP_PATH), main_path)
	if err != OK:
		var f2: FileAccess = FileAccess.open(main_path, FileAccess.WRITE)
		if f2 == null:
			return false
		f2.store_string(txt)
		f2.close()
	saved.emit()
	return true

func delete_files_backup_only() -> void:
	if FileAccess.file_exists(_p(BACKUP_PATH)):
		DirAccess.remove_absolute(_p(BACKUP_PATH))

func reset_all() -> void:
	data = defaults()
	data["first_run_unix"] = int(Time.get_unix_time_from_system())
	save()

func delete_files() -> void:
	for p in [SAVE_PATH, BACKUP_PATH, TMP_PATH]:
		if FileAccess.file_exists(_p(p)):
			DirAccess.remove_absolute(_p(p))

# convenience accessors
func get_val(key: String, fallback: Variant = null) -> Variant:
	return data.get(key, fallback)

func set_val(key: String, v: Variant) -> void:
	data[key] = v
	mark_dirty()

func add_coins(n: int) -> void:
	data["coins"] = maxi(int(data["coins"]) + n, 0)
	mark_dirty()

func spend_coins(n: int) -> bool:
	if int(data["coins"]) < n:
		return false
	data["coins"] = int(data["coins"]) - n
	mark_dirty()
	return true
