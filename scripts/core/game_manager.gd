extends Node
## App flow: screen navigation + current run configuration.

signal screen_changed(name: String)

const SCREENS: Dictionary = {
	"boot": "res://scripts/ui/screens/boot_screen.gd",
	"menu": "res://scripts/ui/screens/menu_screen.gd",
	"game": "res://scripts/ui/screens/game_screen.gd",
	"settings": "res://scripts/ui/screens/settings_screen.gd",
	"shop": "res://scripts/ui/screens/shop_screen.gd",
	"pro": "res://scripts/ui/screens/pro_screen.gd",
	"daily": "res://scripts/ui/screens/daily_screen.gd",
	"missions": "res://scripts/ui/screens/missions_screen.gd",
	"stats": "res://scripts/ui/screens/stats_screen.gd",
	"modes": "res://scripts/ui/screens/modes_screen.gd",
}

var main: Node = null            # set by main.gd
var current_screen: String = ""
var mode: String = "classic"
var last_result: Dictionary = {}
var session_games: int = 0
var headless_test: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func register_main(m: Node) -> void:
	main = m

func go(screen: String, params: Dictionary = {}) -> void:
	if main == null or not SCREENS.has(screen):
		return
	current_screen = screen
	main.call("show_screen", screen, params)
	screen_changed.emit(screen)

func start_game(m: String) -> void:
	mode = m
	go("game", {"mode": m})

func toast(key: String, args: Array = []) -> void:
	if main != null:
		main.call("show_toast", LocalizationManager.t(key, args))

func make_screen(screen: String, params: Dictionary = {}) -> Control:
	var scr: GDScript = load(SCREENS[screen])
	var c: Control = scr.new()
	c.set("params", params)
	return c

func game_seed(m: String) -> int:
	if m == "daily":
		return ProgressionManager.daily_seed()
	return int(Time.get_ticks_usec() & 0x7fffffff)
