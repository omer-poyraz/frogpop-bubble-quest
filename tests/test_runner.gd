extends Node
## Scene-based test runner (autoloads are available). Run:
## godot --headless --path . res://tests/test_runner.tscn   (exit code 0 = all passed)

const SUITES: Array[String] = [
	"res://tests/t_paths.gd", "res://tests/t_chain.gd", "res://tests/t_game.gd",
	"res://tests/t_progress.gd", "res://tests/t_ui.gd", "res://tests/t_perf.gd", "res://tests/t_sim.gd"]

var passed: int = 0
var failed: int = 0
var current: String = ""
var filter: String = ""

func check(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("  FAIL [", current, "] ", msg)

func approx(a: float, b: float, eps: float, msg: String) -> void:
	check(absf(a - b) <= eps, "%s (%.4f vs %.4f)" % [msg, a, b])

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--filter="):
			filter = a.substr(9)
	SaveManager.path_override = "user://test_"
	await get_tree().process_frame
	var t0: int = Time.get_ticks_msec()
	for path in SUITES:
		if filter != "" and not path.contains(filter):
			continue
		var scr: GDScript = load(path)
		if scr == null:
			failed += 1
			print("FAIL cannot load ", path)
			continue
		var suite: Object = scr.new()
		for m in suite.get_method_list():
			var name: String = m["name"]
			if name.begins_with("test_"):
				current = path.get_file().get_basename() + "." + name
				var before_f: int = failed
				var t1: int = Time.get_ticks_msec()
				var r: Variant = suite.call(name, self)
				if r is Object and r.get_class() == "GDScriptFunctionState":
					await r
				print("%s %s (%d ms)" % ["ok  " if failed == before_f else "FAIL", current, Time.get_ticks_msec() - t1])
	print("TESTS: %d passed, %d failed (%d ms)" % [passed, failed, Time.get_ticks_msec() - t0])
	SaveManager.delete_files()
	get_tree().quit(1 if failed > 0 else 0)
