class_name FButton
extends Button
## Chunky mobile button: pressed-down feel, hover/press scale tween, click sound + haptic.

const STYLES: Dictionary = {
	"green": [Color("3fd96a"), Color("1c8f45")],
	"yellow": [Color("ffd23c"), Color("c98a0a")],
	"blue": [Color("4a8dff"), Color("1f4fb8")],
	"red": [Color("ff5a6e"), Color("b21f3a")],
	"purple": [Color("a65bff"), Color("5a2aa8")],
	"gray": [Color("6c7aa8"), Color("3a4670")],
	"pink": [Color("ff7ac8"), Color("b02a82")],
	"dark": [Color("27377a"), Color("141c46")],
}
var key: String = ""
var style_name: String = "green"
var _tween: Tween = null
var click_sound: String = "click"
var text_color: Color = Color.WHITE

static func create(text_key: String, style: String = "green", min_size: Vector2 = Vector2(420, 120), icon_name: String = "", font_size: int = 46) -> FButton:
	var b := FButton.new()
	b.key = text_key
	b.style_name = style
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", UI.font(700))
	b.add_theme_font_size_override("font_size", font_size)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		b.add_theme_color_override(c, Color.WHITE if c != "font_disabled_color" else Color(1, 1, 1, 0.5))
	b.add_theme_color_override("font_outline_color", UI.NAVY)
	b.add_theme_constant_override("outline_size", maxi(int(font_size / 7.0), 3))
	if icon_name != "":
		b.icon = UI.icon(icon_name)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", int(min_size.y * 0.56))
		b.add_theme_constant_override("h_separation", 14)
	b._apply_styles()
	return b

func _ready() -> void:
	LocalizationManager.language_changed.connect(_refresh)
	_refresh()
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	pivot_offset = size / 2.0
	mouse_entered.connect(func() -> void: _scale_to(1.04, 0.12))
	mouse_exited.connect(func() -> void: _scale_to(1.0, 0.12))
	button_down.connect(func() -> void: _scale_to(0.93, 0.07))
	button_up.connect(func() -> void: _bounce())
	pressed.connect(_on_pressed)

func _refresh(_c: String = "") -> void:
	if key != "":
		text = LocalizationManager.t(key)

func set_key(k: String) -> void:
	key = k
	_refresh()

func set_style(s: String) -> void:
	style_name = s
	_apply_styles()

func _apply_styles() -> void:
	var c: Array = STYLES[style_name]
	var base: Color = c[0]
	var dark: Color = c[1]
	var radius: int = int(custom_minimum_size.y * 0.32)
	var normal: StyleBoxFlat = UI.box(base, dark, radius, 5, 10, 9)
	var hover: StyleBoxFlat = UI.box(base.lightened(0.12), dark, radius, 5, 12, 9)
	var pressed_sb: StyleBoxFlat = UI.box(base.darkened(0.06), dark, radius, 5, 4, 2)
	pressed_sb.content_margin_top = 20
	var disabled: StyleBoxFlat = UI.box(Color("5c6385"), Color("333a5a"), radius, 5, 0, 6)
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed_sb)
	add_theme_stylebox_override("focus", normal)
	add_theme_stylebox_override("disabled", disabled)

func _scale_to(s: float, d: float) -> void:
	if disabled:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(s, s), d).set_trans(Tween.TRANS_SINE)

func _bounce() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.08)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_pressed() -> void:
	AudioManager.play(click_sound)
	SettingsManager.vibrate(15)
