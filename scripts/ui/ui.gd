class_name UI
extends RefCounted
## Static UI builders: fonts, styles, labels, panels. Keeps screens short and consistent.

const NAVY: Color = Color("16224f")
const NAVY_LIGHT: Color = Color("27377a")
const WHITE: Color = Color("ffffff")
const GOLD: Color = Color("ffd23c")
const GREEN: Color = Color("3fd96a")
const PINK: Color = Color("ff7ac8")

static var _fonts: Dictionary = {}
static var _tex_cache: Dictionary = {}

static func font(weight: int = 700) -> Font:
	if _fonts.has(weight):
		return _fonts[weight]
	var base: Font = load("res://assets/fonts/Fredoka.ttf")
	var fv := FontVariation.new()
	fv.base_font = base
	var tag: int = TextServerManager.get_primary_interface().name_to_tag("weight")
	fv.variation_opentype = {tag: weight}
	_fonts[weight] = fv
	return fv

static func tex(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path]
	var t: Texture2D = load(path)
	_tex_cache[path] = t
	return t

static func icon(name: String) -> Texture2D:
	return tex("res://assets/ui/%s.png" % name)

static func style_text(l: Label, size: int, color: Color = WHITE, outline: int = 8, weight: int = 700) -> void:
	l.add_theme_font_override("font", font(weight))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", NAVY)
	l.add_theme_constant_override("outline_size", outline)

static func label(key: String, size: int = 40, color: Color = WHITE, align: int = HORIZONTAL_ALIGNMENT_CENTER, args: Array = []) -> LocLabel:
	var l := LocLabel.new(key, args)
	l.horizontal_alignment = align as HorizontalAlignment
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	style_text(l, size, color, maxi(int(size / 7.0), 2))
	return l

static func wrap_label(key: String, size: int, color: Color, width: float, args: Array = []) -> LocLabel:
	var l: LocLabel = label(key, size, color, HORIZONTAL_ALIGNMENT_CENTER, args)
	l.custom_minimum_size = Vector2(width, 0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

static func raw_label(text: String, size: int = 40, color: Color = WHITE, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align as HorizontalAlignment
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	style_text(l, size, color, maxi(int(size / 7.0), 2))
	return l

static func box(bg: Color, border: Color, radius: int = 36, border_w: int = 6, shadow: int = 12, bottom_extra: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.border_width_bottom = border_w + bottom_extra
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = shadow
	sb.shadow_offset = Vector2(0, 6)
	sb.anti_aliasing = true
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	return sb

static func panel(bg: Color = Color(0.09, 0.14, 0.33, 0.94), border: Color = Color("4a62d6"), radius: int = 44) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, border, radius, 6, 18))
	return p

static func pill(bg: Color = Color(0, 0, 0, 0.35)) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := box(bg, Color(1, 1, 1, 0.18), 40, 3, 0)
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", sb)
	return p

static func icon_rect(name: String, size: float) -> TextureRect:
	var r := TextureRect.new()
	r.texture = icon(name)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(size, size)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

## Coin / value pill: [icon] value
static func value_pill(icon_name: String, value: String, size: int = 40) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(icon_rect(icon_name, size * 1.25))
	var l := raw_label(value, size, GOLD)
	l.name = "value"
	h.add_child(l)
	return h

static func spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func hsep(w: float = 12) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 0)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

## Safe-area insets in canvas units (top, bottom, left, right).
static func safe_insets(vp: Viewport) -> Vector4:
	var win: Vector2i = DisplayServer.window_get_size()
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var vr: Vector2 = vp.get_visible_rect().size
	if win.x <= 0 or safe.size.x <= 0 or not OS.has_feature("mobile"):
		return Vector4.ZERO
	var sx: float = vr.x / float(win.x)
	var sy: float = vr.y / float(win.y)
	var top: float = maxf(float(safe.position.y) * sy, 0.0)
	var bottom: float = maxf(float(win.y - safe.position.y - safe.size.y) * sy, 0.0)
	var left: float = maxf(float(safe.position.x) * sx, 0.0)
	var right: float = maxf(float(win.x - safe.position.x - safe.size.x) * sx, 0.0)
	return Vector4(top, bottom, left, right)
