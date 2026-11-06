class_name ScreenBase
extends Control
## Common scaffold: themed background, header with back button + title, scrolling content column.

var params: Dictionary = {}
var bg: ThemeBackground
var content: VBoxContainer
var scroll: ScrollContainer
var header_title: LocLabel
var coin_value: Label
var back_screen: String = "menu"

func build_base(title_key: String, show_coins: bool = true, with_scroll: bool = true) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg = ThemeBackground.new()
	add_child(bg)
	var idx: int = int(hash(title_key) % 10)
	bg.apply_theme(idx, 0)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.06, 0.18, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ins: Vector4 = UI.safe_insets(get_viewport())
	root.add_theme_constant_override("margin_top", int(40 + ins.x))
	root.add_theme_constant_override("margin_bottom", int(30 + ins.y))
	_set_side_margins(root)
	resized.connect(func() -> void:
		if is_instance_valid(root):
			_set_side_margins(root))
	_set_side_margins.call_deferred(root)
	add_child(root)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 22)
	root.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 20)
	col.add_child(head)
	var back: FButton = FButton.create("", "dark", Vector2(112, 112), "back")
	back.pressed.connect(func() -> void: GameManager.go(back_screen))
	head.add_child(back)
	header_title = UI.label(title_key, 66, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(header_title)
	if show_coins:
		var pill: PanelContainer = UI.pill()
		var vp: HBoxContainer = UI.value_pill("coin", LocalizationManager.fmt_num(ProgressionManager.coins()), 40)
		coin_value = vp.get_node("value")
		pill.add_child(vp)
		head.add_child(pill)
		ProgressionManager.coins_changed.connect(func(t: int) -> void:
			if is_instance_valid(coin_value):
				coin_value.text = LocalizationManager.fmt_num(t))
	if with_scroll:
		scroll = ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		col.add_child(scroll)
		content = VBoxContainer.new()
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_theme_constant_override("separation", 20)
		scroll.add_child(content)
	else:
		content = col
	AudioManager.play_music("music_menu")

## Keep content in a 1080-wide centred column on wide screens (tablets / landscape previews).
func _set_side_margins(root: MarginContainer) -> void:
	var vw: float = size.x if size.x > 0.0 else get_viewport_rect().size.x
	var side: int = int(maxf(40.0, (vw - K.FIELD_W) * 0.5 + 40.0))
	root.add_theme_constant_override("margin_left", side)
	root.add_theme_constant_override("margin_right", side)

func clear_content() -> void:
	for c in content.get_children():
		c.queue_free()

func card(min_h: float = 150.0) -> PanelContainer:
	var p: PanelContainer = UI.panel(Color(0.1, 0.16, 0.38, 0.92), Color("4a62d6"), 36)
	p.custom_minimum_size = Vector2(0, min_h)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p
