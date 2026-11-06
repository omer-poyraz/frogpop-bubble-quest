extends SceneTree
func _init() -> void:
	var bad: int = 0
	for dir in ["res://scripts", "res://tests", "res://tools"]:
		bad += _scan(dir)
	print("SCRIPT CHECK: ", bad, " failed")
	quit(1 if bad > 0 else 0)
func _scan(dir: String) -> int:
	var bad: int = 0
	var d: DirAccess = DirAccess.open(dir)
	for f in d.get_files():
		if f.ends_with(".gd") and f != "check_scripts.gd":
			var s: Resource = load(dir + "/" + f)
			if s == null or not (s as GDScript).can_instantiate():
				print("FAILED: ", dir + "/" + f)
				bad += 1
	for sub in d.get_directories():
		bad += _scan(dir + "/" + sub)
	return bad
