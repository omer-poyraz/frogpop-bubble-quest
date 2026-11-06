extends Control
## Splash: branding image + loading shimmer, then the menu.

var params: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("0b3a46")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var tr := TextureRect.new()
	tr.texture = load("res://assets/branding/splash.png")
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.modulate.a = 0.0
	add_child(tr)
	var tw: Tween = create_tween()
	tw.tween_property(tr, "modulate:a", 1.0, 0.45)
	tw.tween_interval(0.9)
	tw.tween_callback(func() -> void: GameManager.go("menu"))
