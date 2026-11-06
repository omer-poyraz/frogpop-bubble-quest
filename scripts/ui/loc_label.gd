class_name LocLabel
extends Label
## Label whose text is a localisation key; re-translates itself on language change.

var key: String = ""
var args: Array = []

func _init(k: String = "", a: Array = []) -> void:
	key = k
	args = a

func _ready() -> void:
	if custom_minimum_size.x > 0.0:
		autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	LocalizationManager.language_changed.connect(_refresh)
	_refresh()

func set_key(k: String, a: Array = []) -> void:
	key = k
	args = a
	_refresh()

func _refresh(_c: String = "") -> void:
	if key != "":
		text = LocalizationManager.t(key, args)
