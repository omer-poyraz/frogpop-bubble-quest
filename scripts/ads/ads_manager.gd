extends Node
## Ad service layer. Real ads need the native AdMob plugin (see docs/MONETIZATION.md).
## Without it: ads are "unavailable". Debug builds may show a clearly labelled TEST ad.

signal rewarded_finished(success: bool)
signal availability_changed()

var config: Dictionary = {}
var plugin: Object = null
var plugin_name: String = ""
var session_interstitials: int = 0
var last_interstitial_time: float = -9999.0
var test_ads_enabled: bool = false
var instant_test_ads: bool = false   # tests: complete immediately
var in_gameplay: bool = false         # set by the game: ads are never shown while true
var _overlay: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	config = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/monetization.json"))
	plugin_name = str(config["plugins"]["admob_singleton"])
	if Engine.has_singleton(plugin_name):
		plugin = Engine.get_singleton(plugin_name)
	test_ads_enabled = OS.is_debug_build() and plugin == null and not OS.has_feature("mobile")

func has_plugin() -> bool:
	return plugin != null

## True when some ad (real or labelled test ad in debug) can be shown.
func is_available() -> bool:
	return has_plugin() or test_ads_enabled

func is_ad_free() -> bool:
	return ProgressionManager.is_pro() or bool(SaveManager.data["remove_ads"])

func rules() -> Dictionary:
	return config["ad_rules"]

## Interstitial only on game-over / menu transitions, never mid-game, never for PRO.
func can_show_interstitial() -> bool:
	if in_gameplay or is_ad_free() or not is_available():
		return false
	var r: Dictionary = rules()
	var games: int = int(SaveManager.data["games_played"])
	if games <= int(r["no_interstitial_first_games"]):
		return false
	if int(SaveManager.data["ads"]["games_since_ad"]) < int(r["interstitial_every_n_games"]):
		return false
	if session_interstitials >= int(r["max_interstitials_per_session"]):
		return false
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - last_interstitial_time < float(r["min_seconds_between_interstitials"]):
		return false
	return true

func note_game_finished() -> void:
	SaveManager.data["ads"]["games_since_ad"] = int(SaveManager.data["ads"]["games_since_ad"]) + 1
	SaveManager.mark_dirty()

func show_interstitial() -> bool:
	if not can_show_interstitial():
		return false
	session_interstitials += 1
	last_interstitial_time = Time.get_ticks_msec() / 1000.0
	SaveManager.data["ads"]["games_since_ad"] = 0
	SaveManager.mark_dirty()
	if has_plugin():
		if plugin.has_method("show_interstitial"):
			plugin.call("show_interstitial")
		return true
	_show_test_overlay(false)
	return true

## Rewarded ad is always optional and never offered to a context where gameplay is running.
func can_show_rewarded() -> bool:
	return is_available() and not in_gameplay

func show_rewarded() -> void:
	if not can_show_rewarded():
		rewarded_finished.emit(false)
		return
	if has_plugin():
		if plugin.has_method("show_rewarded"):
			plugin.call("show_rewarded")
		else:
			rewarded_finished.emit(false)
		return
	_show_test_overlay(true)

func _show_test_overlay(rewarded: bool) -> void:
	if instant_test_ads:
		if rewarded:
			rewarded_finished.emit(true)
		return
	var layer := CanvasLayer.new()
	layer.layer = 120
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.96)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var lbl := Label.new()
	lbl.text = LocalizationManager.t("test_ad_label") + "\n\n" + LocalizationManager.t("test_ad_body")
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_font_size_override("font_size", 56)
	lbl.add_theme_color_override("font_color", Color("ffd23c"))
	bg.add_child(lbl)
	get_tree().root.add_child(layer)
	var tw: Tween = layer.create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(func() -> void:
		layer.queue_free()
		if rewarded:
			rewarded_finished.emit(true))
