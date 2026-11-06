class_name PathGenerator
extends RefCounted
## Parametric route generation + playability validation. Deterministic for (type, seed).

const TYPES: Array[String] = ["circle", "spiral", "snake", "wave", "double", "labyrinth", "heart", "cross", "boss"]
const FIELD: Rect2 = Rect2(20, 250, 1040, 1450)
const MIN_RADIUS: float = 82.0
const MIN_LENGTH: float = 2500.0
const MIN_REACH: float = 0.15
const MIN_FRONT_REACH: float = 0.55
const MAX_LEAD: float = 1500.0

## Types allowed by wave number (0-based complexity ramp).
static func types_for_wave(wave: int) -> Array[String]:
	var t: Array[String] = ["circle", "snake", "wave"]
	if wave >= 2: t.append_array(["double", "spiral"])
	if wave >= 5: t.append("labyrinth")
	if wave >= 8: t.append("heart")
	if wave >= 11: t.append("cross")
	return t

static func generate(type: String, seed_value: int) -> PathData:
	var last_reason: String = ""
	for attempt in 12:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([type, seed_value, attempt])
		var pd: PathData = _build(type, rng, attempt)
		if pd == null:
			continue
		pd.seed_used = seed_value
		last_reason = validate(pd)
		if last_reason == "":
			return pd
	# fallback: safe route
	if type != "snake":
		return generate("snake", seed_value + 7919)
	push_warning("PathGenerator fallback failed: " + last_reason)
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 1
	return _build("snake", rng2, 0)

static func _build(type: String, rng: RandomNumberGenerator, attempt: int) -> PathData:
	var raw: PackedVector2Array
	var frog: Vector2 = Vector2(540, 960)
	var cross_center: Vector2 = Vector2(-9999, -9999)
	match type:
		"circle":
			var c := Vector2(540, 940 + rng.randf_range(-30, 30))
			var r: float = rng.randf_range(380, 440)
			var a0: float = deg_to_rad(-90.0 + rng.randf_range(-22, 22)) if attempt % 2 == 0 else deg_to_rad(90.0 + rng.randf_range(-22, 22))
			raw = PackedVector2Array()
			var sweep: float = TAU * rng.randf_range(0.80, 0.90)
			var n: int = int(sweep * r / 6.0)
			for i in n + 1:
				var a: float = a0 + sweep * float(i) / float(n)
				raw.append(c + Vector2(cos(a), sin(a)) * r)
			frog = c
		"spiral":
			var c2 := Vector2(540, 930)
			var r0: float = rng.randf_range(440, 475)
			var r1: float = rng.randf_range(250, 280)
			var turns: float = (r0 - r1) / rng.randf_range(100, 118)
			var a1: float = deg_to_rad(-90.0 + rng.randf_range(-22, 22)) if attempt % 2 == 0 else deg_to_rad(90.0 + rng.randf_range(-22, 22))
			raw = PackedVector2Array()
			var total: float = TAU * turns
			var steps: int = int(total * 360.0 / 6.0 / 2.0) + 40
			for i in steps + 1:
				var f: float = float(i) / float(steps)
				var rr: float = lerpf(r0, r1, f)
				var a2: float = a1 + total * f
				raw.append(c2 + Vector2(cos(a2), sin(a2)) * rr)
			frog = c2
		"boss":
			var c3 := Vector2(540, 930)
			var r0b: float = 470.0
			var r1b: float = 275.0
			var turnsb: float = 2.05
			var a1b: float = deg_to_rad(-90.0 + rng.randf_range(-22, 22)) if attempt % 2 == 0 else deg_to_rad(90.0 + rng.randf_range(-22, 22))
			raw = PackedVector2Array()
			var totalb: float = TAU * turnsb
			var stepsb: int = 900
			var petals: int = 3 + rng.randi() % 2
			for i in stepsb + 1:
				var f2: float = float(i) / float(stepsb)
				var rr2: float = lerpf(r0b, r1b, f2) + 14.0 * sin(f2 * TAU * petals * turnsb) * (1.0 - f2 * 0.3)
				var a3: float = a1b + totalb * f2
				raw.append(c3 + Vector2(cos(a3), sin(a3)) * rr2)
			frog = c3
		"snake", "wave", "double":
			raw = _snake(type, rng, attempt)
			frog = Vector2(540, 1500)
		"labyrinth":
			raw = _labyrinth(rng)
			frog = Vector2(540, 930)
		"heart":
			raw = _heart(rng)
			frog = Vector2(540, 930)
		"cross":
			raw = _fig8(rng)
			frog = Vector2(540, 640)
			cross_center = Vector2(540, 930)
		_:
			return null
	if raw.size() < 10:
		return null
	if rng.randf() < 0.5 and type != "cross":
		raw = _mirror(raw)
		frog.x = K.FIELD_W - frog.x
	var pd := PathData.new()
	pd.kind = type
	pd.frog_pos = frog
	pd.allow_crossing = type == "cross"
	pd.cross_center = cross_center
	var full: PackedVector2Array = _with_lead_in(_resample(raw, K.PATH_STEP))
	if full.size() == 0:
		return null
	pd.build(full)
	# lead-in length = arc length until first point that is inside the field
	pd.enter_s = 0.0
	for i in pd.pts.size():
		if FIELD.grow(30).has_point(pd.pts[i]) or (pd.pts[i].x >= 0 and pd.pts[i].x <= K.FIELD_W and pd.pts[i].y >= 0 and pd.pts[i].y <= K.FIELD_H):
			pd.enter_s = pd.cum[i]
			break
	return pd

static func _mirror(a: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in a:
		out.append(Vector2(K.FIELD_W - p.x, p.y))
	return out

static func _snake(type: String, rng: RandomNumberGenerator, _attempt: int) -> PackedVector2Array:
	var rows: int = 4
	var amp: float = 0.0
	var period: float = 800.0
	var y0: float = 330.0
	var y_last: float = 1180.0
	match type:
		"snake":
			rows = 4
			y_last = rng.randf_range(1130.0, 1230.0)
		"wave":
			rows = 4 + rng.randi() % 2
			amp = rng.randf_range(55, 85)
			period = rng.randf_range(680, 860)
		"double":
			rows = 3
			y0 = 380.0
			y_last = 1100.0
	var dy: float = (y_last - y0) / float(rows - 1)
	var r: float = dy * 0.5
	var x_left: float = 70.0 + r
	var x_right: float = 1010.0 - r
	var out := PackedVector2Array()
	var dir: int = 1
	for i in rows:
		var y: float = y0 + dy * i
		var xa: float = -40.0 if i == 0 else (x_left if dir == 1 else x_right)
		var xb: float = x_right if dir == 1 else x_left
		var n: int = int(absf(xb - xa) / 6.0)
		for k in n + 1:
			var f: float = float(k) / float(n)
			var x: float = lerpf(xa, xb, f)
			var yy: float = y
			if amp > 0.0:
				var fd: float = clampf(minf(absf(x - x_left), absf(x - x_right)) / 260.0, 0.0, 1.0)
				fd = fd * fd * (3.0 - 2.0 * fd)
				yy += amp * sin(x / period * TAU) * fd
			out.append(Vector2(x, yy))
		if i < rows - 1:
			var cx: float = xb
			var cy: float = y + r
			var m: int = int(PI * r / 5.0) + 4
			for k in range(1, m):
				var a: float = float(k) / float(m) * PI
				var px: float = cx + (sin(a) * r if dir == 1 else -sin(a) * r)
				var py: float = cy - cos(a) * r
				out.append(Vector2(px, py))
		dir = -dir
	return out

## Fillet every corner of a polyline with a circular arc of (at most) radius r.
static func _fillet(src: Array, r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.append(src[0])
	for i in range(1, src.size() - 1):
		var p: Vector2 = src[i]
		var ua: Vector2 = (src[i - 1] - p)
		var ub: Vector2 = (src[i + 1] - p)
		var la: float = ua.length()
		var lb: float = ub.length()
		if la < 0.001 or lb < 0.001:
			continue
		ua /= la
		ub /= lb
		var turn: float = PI - absf(ua.angle_to(ub))
		if turn < 0.002:
			out.append(p)
			continue
		var half: float = turn * 0.5
		var t: float = r * tan(half)
		t = minf(t, minf(la, lb) * 0.5)
		var re: float = t / tan(half)
		var pa: Vector2 = p + ua * t
		var pb: Vector2 = p + ub * t
		var bis: Vector2 = (ua + ub).normalized()
		var ctr: Vector2 = p + bis * (re / cos(PI * 0.5 - half) if absf(cos(PI * 0.5 - half)) > 0.0001 else re)
		# centre distance from corner = re / sin(interior/2); interior = PI - turn
		ctr = p + bis * (re / sin((PI - turn) * 0.5))
		var a0: float = (pa - ctr).angle()
		var a1: float = (pb - ctr).angle()
		var da: float = wrapf(a1 - a0, -PI, PI)
		var steps: int = maxi(2, int(absf(da) / 0.06))
		for k in steps + 1:
			var aa: float = a0 + da * float(k) / float(steps)
			out.append(ctr + Vector2(cos(aa), sin(aa)) * re)
	out.append(src[src.size() - 1])
	return out

static func _labyrinth(rng: RandomNumberGenerator) -> PackedVector2Array:
	var gap: float = rng.randf_range(124, 136)
	var c := Vector2(540, 930)
	var hw: float = 470.0
	var hh: float = 600.0
	var corners: Array = []
	corners.append(Vector2(-60, c.y + hh))
	var k: int = 0
	while hw > 215.0 and hh > 215.0 and k < 6:
		corners.append(Vector2(c.x + hw, c.y + hh))
		corners.append(Vector2(c.x + hw, c.y - hh))
		corners.append(Vector2(c.x - hw, c.y - hh))
		hw -= gap
		hh -= gap
		corners.append(Vector2(c.x - (hw + gap), c.y + hh))
		k += 1
	corners.append(Vector2(c.x + hw, c.y + hh))
	return _fillet(corners, 100.0)

static func _catmull(pts: Array, closed: bool, per: int) -> PackedVector2Array:
	var n: int = pts.size()
	var out := PackedVector2Array()
	var segs: int = n if closed else n - 1
	for i in segs:
		var p0: Vector2 = pts[(i - 1 + n) % n] if (closed or i > 0) else pts[0]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[(i + 1) % n]
		var p3: Vector2 = pts[(i + 2) % n] if (closed or i + 2 < n) else pts[n - 1]
		for k in per:
			var t: float = float(k) / float(per)
			var t2: float = t * t
			var t3: float = t2 * t
			out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
	if not closed:
		out.append(pts[n - 1])
	return out

static func _heart_loop() -> Array:
	var rl: float = 0.55
	var off: float = 0.42
	var rf: float = 0.24
	var cl := Vector2(-off, -0.45)
	var cr := Vector2(off, -0.45)
	var cn := Vector2(0.0, -0.45 - sqrt((rl + rf) * (rl + rf) - off * off))
	var tip := Vector2(0.0, 1.0)
	var d: Vector2 = tip - cl
	var contact: float = d.angle() + acos(rl / d.length())  # lower-left contact angle on left lobe
	var pts: Array = []
	var a: float = -PI * 0.5
	var stop_r: float = (cn - cr).angle()
	while a > stop_r:
		pts.append(cr + Vector2(cos(a), sin(a)) * rl)
		a -= 0.03
	# notch fillet: arc about cn from right contact to left contact (angle increasing)
	var n0: float = (cr - cn).angle()
	var n1: float = (cl - cn).angle()
	a = n0
	while a < n1:
		pts.append(cn + Vector2(cos(a), sin(a)) * rf)
		a += 0.05
	a = (cn - cl).angle()
	var target: float = contact - TAU
	while a > target:
		pts.append(cl + Vector2(cos(a), sin(a)) * rl)
		a -= 0.03
	pts.append(tip)
	a = PI - contact
	while a > -PI * 0.5:
		pts.append(cr + Vector2(cos(a), sin(a)) * rl)
		a -= 0.03
	return pts

static func _heart(rng: RandomNumberGenerator) -> PackedVector2Array:
	var c := Vector2(540, 930)
	var sx0: float = rng.randf_range(495, 515)
	var sy0: float = sx0 * 0.80
	var shrink: float = rng.randf_range(0.63, 0.67)
	var loops: float = 1.06
	var base: Array = _heart_loop()
	var m: int = base.size()
	var total: int = int(m * loops)
	var poly: Array = []
	for i in total + 1:
		var f: float = float(i) / float(total)
		var sc: float = lerpf(1.0, shrink, f)
		var u: Vector2 = base[i % m]
		poly.append(c + Vector2(u.x * sx0 * sc, u.y * sy0 * sc))
	return _fillet(poly, 100.0)

static func _fig8(rng: RandomNumberGenerator) -> PackedVector2Array:
	var a: float = rng.randf_range(400, 430)
	var b: float = rng.randf_range(600, 640)
	var c := Vector2(540, 930)
	var out := PackedVector2Array()
	# x = A sin 2t, y = B sin t ; start at bottom lobe tip, run ~1.75 of a loop
	var t0: float = -PI * 0.5
	var t1: float = t0 + TAU * 0.83
	var n: int = 900
	for i in n + 1:
		var t: float = lerpf(t0, t1, float(i) / float(n))
		out.append(c + Vector2(a * sin(2.0 * t), -b * sin(t)))
	# make the bottom lobe tip the start: curve starts at (c.x, c.y + b) heading sideways
	return out

static func _resample(src: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.append(src[0])
	var carry: float = 0.0
	var prev: Vector2 = src[0]
	for i in range(1, src.size()):
		var cur: Vector2 = src[i]
		var seg: float = prev.distance_to(cur)
		if seg < 0.0001:
			continue
		var dir: Vector2 = (cur - prev) / seg
		var pos: float = step - carry
		while pos <= seg:
			out.append(prev + dir * pos)
			pos += step
		carry = seg - (pos - step)
		prev = cur
	return out

static func _with_lead_in(curve: PackedVector2Array) -> PackedVector2Array:
	if curve.size() < 3:
		return PackedVector2Array()
	var dir: Vector2 = (curve[2] - curve[0]).normalized()
	var start: Vector2 = curve[0]
	var lead := PackedVector2Array()
	var d: float = 0.0
	var outside_margin: float = 70.0
	var p: Vector2 = start
	while d < MAX_LEAD:
		d += K.PATH_STEP
		p = start - dir * d
		if p.x < -outside_margin or p.x > K.FIELD_W + outside_margin or p.y < -outside_margin or p.y > K.FIELD_H + outside_margin:
			break
		lead.append(p)
	if d >= MAX_LEAD:
		return PackedVector2Array()
	lead.append(p)
	lead.reverse()
	lead.append_array(curve)
	return lead

## Returns "" if playable, else the reason it is rejected.
static func validate(pd: PathData) -> String:
	var n: int = pd.pts.size()
	if pd.length - pd.enter_s < MIN_LENGTH:
		return "short"
	if pd.enter_s > MAX_LEAD:
		return "lead"
	# bounds + frog clearance
	var field_ok: Rect2 = FIELD
	for i in n:
		if pd.cum[i] < pd.enter_s + 70.0:
			continue
		var p: Vector2 = pd.pts[i]
		if not field_ok.has_point(p):
			return "bounds"
		if p.distance_to(pd.frog_pos) < K.FROG_CLEAR:
			return "frog"
	# curvature
	var stride: int = 6
	var min_r: float = INF
	for i in range(stride, n - stride, 2):
		var v1: Vector2 = pd.pts[i] - pd.pts[i - stride]
		var v2: Vector2 = pd.pts[i + stride] - pd.pts[i]
		var ang: float = absf(v1.angle_to(v2))
		if ang > 0.0001:
			min_r = minf(min_r, (stride * K.PATH_STEP) / ang)
	pd.min_radius = min_r
	if min_r < MIN_RADIUS:
		return "curvature"
	# self separation (spatial hash)
	var cell: float = 90.0
	var grid: Dictionary = {}
	var sep: float = K.BALL_D * 1.14
	var min_arc: float = K.BALL_D * 4.0
	for i in range(0, n, 2):
		if pd.cum[i] < pd.enter_s:
			continue
		var p2: Vector2 = pd.pts[i]
		var cx: int = int(floorf(p2.x / cell))
		var cy: int = int(floorf(p2.y / cell))
		for ox in range(-1, 2):
			for oy in range(-1, 2):
				var key: int = (cx + ox + 100) * 1000 + (cy + oy + 100)
				if grid.has(key):
					for j in grid[key]:
						if absf(pd.cum[i] - pd.cum[j]) > min_arc and pd.pts[j].distance_to(p2) < sep:
							if pd.allow_crossing and p2.distance_to(pd.cross_center) < 190.0 and pd.pts[j].distance_to(pd.cross_center) < 190.0:
								continue
							return "overlap"
		var k2: int = (cx + 100) * 1000 + (cy + 100)
		if not grid.has(k2):
			grid[k2] = []
		grid[k2].append(i)
	pd.reach = reachability(pd)
	if pd.reach < MIN_REACH:
		return "reach"
	if reachability(pd, pd.length * 0.7) < MIN_FRONT_REACH:
		return "front_reach"
	return ""

## Fraction of sampled route points that have an unobstructed straight line from the frog.
static func reachability(pd: PathData, from_s: float = 0.0) -> float:
	var f: Vector2 = pd.frog_pos
	var ok: int = 0
	var total: int = 0
	var s: float = maxf(pd.enter_s + 20.0, from_s)
	var coarse: Array[int] = []
	for i in range(0, pd.pts.size(), 3):
		coarse.append(i)
	while s < pd.length - 20.0:
		var p: Vector2 = pd.pos_at(s)
		var d: Vector2 = p - f
		var dl: float = d.length()
		var dn: Vector2 = d / maxf(dl, 0.001)
		var blocked: bool = false
		for i in coarse:
			if absf(pd.cum[i] - s) < K.BALL_D * 3.0:
				continue
			var q: Vector2 = pd.pts[i] - f
			var t: float = q.dot(dn)
			if t < 0.0 or t > dl - 30.0:
				continue
			var perp: float = absf(q.x * dn.y - q.y * dn.x)
			if perp < K.BALL_R * 1.15:
				blocked = true
				break
		total += 1
		if not blocked:
			ok += 1
		s += 56.0
	return float(ok) / float(maxi(total, 1))
