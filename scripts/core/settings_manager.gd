extends Node
## Thin facade over SaveManager.data["settings"] + applies audio/quality/haptics.

signal changed(key: String)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func s() -> Dictionary:
	return SaveManager.data["settings"]

func get_setting(key: String) -> Variant:
	return s()[key]

func set_setting(key: String, v: Variant) -> void:
	s()[key] = v
	SaveManager.mark_dirty()
	changed.emit(key)

var music: float:
	get: return float(s()["music"])
var sfx: float:
	get: return float(s()["sfx"])
var muted: bool:
	get: return bool(s()["mute"])
var vibration: bool:
	get: return bool(s()["vibration"])
var quality: int:
	get: return int(s()["quality"])
var colorblind: bool:
	get: return bool(s()["colorblind"])

func vibrate(ms: int = 20) -> void:
	if vibration and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)

## Particle budget multiplier by graphics quality.
func particle_scale() -> float:
	match quality:
		0: return 0.35
		1: return 0.7
		_: return 1.0

func glow_enabled() -> bool:
	return quality >= 1
