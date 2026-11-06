class_name FloatingText
extends Node2D
## Pooled floating score/combo labels.

const POOL: int = 10
var _labels: Array[Label] = []
var _next: int = 0

func _ready() -> void:
	for i in POOL:
		var l := Label.new()
		l.visible = false
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(700, 100)
		l.pivot_offset = Vector2(350, 50)
		l.z_index = 50
		add_child(l)
		_labels.append(l)

func show_text(text: String, pos: Vector2, color: Color = Color.WHITE, size: int = 52, rise: float = 110.0, life: float = 0.9) -> void:
	var l: Label = _labels[_next]
	_next = (_next + 1) % POOL
	UI.style_text(l, size, color, maxi(int(size / 6.0), 4))
	l.text = text
	l.position = pos - Vector2(350, 50)
	l.scale = Vector2(0.4, 0.4)
	l.modulate.a = 1.0
	l.visible = true
	var tw: Tween = l.create_tween().set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y - rise, life).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, life * 0.4).set_delay(life * 0.6)
	tw.chain().tween_callback(func() -> void: l.visible = false)
