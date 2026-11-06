class_name Ball
extends RefCounted
## One bubble in the chain. s = arc-length position along the route.

static var _next_id: int = 1
var id: int = 0
var color: int = 0
var s: float = 0.0
var kind: int = K.KIND_NORMAL
var golden: bool = false
var hp: int = 1
var born: float = 0.0

func _init(c: int = 0, pos: float = 0.0, k: int = K.KIND_NORMAL, g: bool = false) -> void:
	id = _next_id
	_next_id += 1
	color = c
	s = pos
	kind = k
	golden = g
	hp = 2 if k == K.KIND_STONE else 1

func matchable() -> bool:
	return kind != K.KIND_STONE
