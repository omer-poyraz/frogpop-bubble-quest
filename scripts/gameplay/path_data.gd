class_name PathData
extends RefCounted
## Densely sampled polyline with cumulative length table. s -> position is O(log n).

var pts: PackedVector2Array = PackedVector2Array()
var cum: PackedFloat32Array = PackedFloat32Array()
var length: float = 0.0
var frog_pos: Vector2 = Vector2(540, 960)
var kind: String = ""
var allow_crossing: bool = false
var enter_s: float = 0.0  # arc length where the route first enters the visible field
var cross_center: Vector2 = Vector2(-9999, -9999)
var min_radius: float = 0.0
var reach: float = 0.0
var seed_used: int = 0

func build(points: PackedVector2Array) -> void:
	pts = points
	cum = PackedFloat32Array()
	cum.resize(pts.size())
	var acc: float = 0.0
	for i in pts.size():
		if i > 0:
			acc += pts[i].distance_to(pts[i - 1])
		cum[i] = acc
	length = acc

func _idx_for(s: float) -> int:
	# index i such that cum[i] <= s < cum[i+1]
	var lo: int = 0
	var hi: int = cum.size() - 1
	while lo < hi - 1:
		var mid: int = (lo + hi) >> 1
		if cum[mid] <= s:
			lo = mid
		else:
			hi = mid
	return lo

func pos_at(s: float) -> Vector2:
	if pts.size() < 2:
		return Vector2.ZERO
	if s <= 0.0:
		return pts[0] + tangent_at(0.0) * s
	if s >= length:
		return pts[pts.size() - 1] + tangent_at(length) * (s - length)
	var i: int = _idx_for(s)
	var seg: float = cum[i + 1] - cum[i]
	if seg <= 0.00001:
		return pts[i]
	return pts[i].lerp(pts[i + 1], (s - cum[i]) / seg)

func tangent_at(s: float) -> Vector2:
	if pts.size() < 2:
		return Vector2.RIGHT
	var i: int = _idx_for(clampf(s, 0.0, length))
	i = clampi(i, 0, pts.size() - 2)
	var d: Vector2 = pts[i + 1] - pts[i]
	return d.normalized() if d.length() > 0.0001 else Vector2.RIGHT

## Nearest arc position to a point, searching around a hint window (or whole path if hint < 0).
func nearest_s(p: Vector2, hint: float = -1.0, window: float = 400.0) -> float:
	var lo: int = 0
	var hi: int = pts.size() - 1
	if hint >= 0.0:
		lo = _idx_for(clampf(hint - window, 0.0, length))
		hi = mini(_idx_for(clampf(hint + window, 0.0, length)) + 1, pts.size() - 1)
	var best_d: float = INF
	var best_s: float = 0.0
	for i in range(lo, hi):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var ab: Vector2 = b - a
		var l2: float = ab.length_squared()
		var t: float = 0.0 if l2 < 0.00001 else clampf((p - a).dot(ab) / l2, 0.0, 1.0)
		var d: float = (a + ab * t).distance_squared_to(p)
		if d < best_d:
			best_d = d
			best_s = cum[i] + sqrt(l2) * t
	return best_s

func point_in_field(p: Vector2, margin: float = 0.0) -> bool:
	return p.x >= margin and p.x <= K.FIELD_W - margin and p.y >= margin and p.y <= K.FIELD_H - margin
