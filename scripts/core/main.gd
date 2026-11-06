extends Control
## Root scene: hosts the active screen, transition fade and toasts.

var screen_holder: Control
var overlay: CanvasLayer
var fade: ColorRect
var toast_label: Label
var current: Control = null
var _busy: bool = false
var skip_boot: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	GameManager.register_main(self)
	screen_holder = Control.new()
	screen_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen_holder)
	overlay = CanvasLayer.new()
	overlay.layer = 100
	add_child(overlay)
	fade = ColorRect.new()
	fade.color = Color("0b1536")
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.modulate.a = 0.0
	overlay.add_child(fade)
	toast_label = Label.new()
	UI.style_text(toast_label, 40, Color.WHITE, 8)
	toast_label.position = Vector2(0, 160)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.custom_minimum_size = Vector2(900, 80)
	toast_label.modulate.a = 0.0
	overlay.add_child(toast_label)
	get_tree().root.size_changed.connect(_on_resize)
	var all_args: PackedStringArray = OS.get_cmdline_args()
	if OS.has_feature("pc") and DisplayServer.get_name() != "headless" and not ("--write-movie" in all_args) and not ("--resolution" in all_args):
		get_window().size = Vector2i(540, 960)   # comfortable desktop preview window
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var screen: String = ""
	var prm: Dictionary = {}
	for a in args:
		if a.begins_with("--screen="):
			screen = a.substr(9)
		elif a.begins_with("--mode="):
			prm["mode"] = a.substr(7)
		elif a.begins_with("--wave="):
			prm["start_wave"] = int(a.substr(7))
		elif a.begins_with("--seed="):
			prm["seed"] = int(a.substr(7))
		elif a.begins_with("--bot-think="):
			prm["bot_think"] = float(a.substr(12))
		elif a.begins_with("--bot-skill="):
			prm["bot_skill"] = float(a.substr(12))
		elif a.begins_with("--demo="):
			prm["demo"] = a.substr(7)
		elif a.begins_with("--tab="):
			prm["tab"] = a.substr(6)
		elif a == "--autoplay":
			prm["auto_play"] = true
		elif a.begins_with("--lang="):
			LocalizationManager.set_language(a.substr(7), false)
		elif a.begins_with("--skin="):
			SaveManager.data["selected_skin"] = a.substr(7)
			if not (SaveManager.data["unlocked_skins"] as Array).has(a.substr(7)):
				(SaveManager.data["unlocked_skins"] as Array).append(a.substr(7))
	if screen != "":
		GameManager.mode = str(prm.get("mode", "classic"))
		GameManager.go(screen, prm)
	elif "--skip-boot" in args or skip_boot:
		GameManager.go("menu")
	else:
		GameManager.go("boot")

func _on_resize() -> void:
	toast_label.position.x = (get_viewport_rect().size.x - 900.0) * 0.5

func show_screen(name: String, params: Dictionary) -> void:
	if _busy:
		return
	_busy = true
	if current != null:
		var tw: Tween = create_tween()
		tw.tween_property(fade, "modulate:a", 1.0, 0.16)
		await tw.finished
		current.queue_free()
		current = null
	var scr: Control = GameManager.make_screen(name, params)
	scr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_holder.add_child(scr)
	current = scr
	var tw2: Tween = create_tween()
	tw2.tween_property(fade, "modulate:a", 0.0, 0.22)
	_busy = false

func show_toast(text: String) -> void:
	toast_label.text = text
	toast_label.position.x = (get_viewport_rect().size.x - 900.0) * 0.5
	var tw: Tween = create_tween()
	tw.tween_property(toast_label, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.6)
	tw.tween_property(toast_label, "modulate:a", 0.0, 0.4)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if GameManager.current_screen == "menu":
			get_tree().quit()
		elif GameManager.current_screen != "game":
			GameManager.go("menu")
