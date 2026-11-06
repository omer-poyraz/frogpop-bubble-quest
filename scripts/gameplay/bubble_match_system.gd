class_name BubbleMatchSystem
extends RefCounted
## Pure helpers for finding matching runs in the chain (front-first ordered Array[Ball]).

static func contiguous(a: Ball, b: Ball) -> bool:
	return a.s - b.s <= K.BALL_D + K.CONTACT_EPS

## Returns [first_index, last_index] (inclusive) of the run containing index i.
static func run_at(balls: Array, i: int, enter_s: float) -> Array:
	var c: int = (balls[i] as Ball).color
	var lo: int = i
	var hi: int = i
	while lo > 0 and _same(balls[lo - 1], balls[lo], c, enter_s):
		lo -= 1
	while hi < balls.size() - 1 and _same(balls[hi + 1], balls[hi], c, enter_s):
		hi += 1
	return [lo, hi]

static func _same(nb: Ball, cur: Ball, c: int, enter_s: float) -> bool:
	return nb.matchable() and nb.color == c and nb.s >= enter_s and contiguous(nb if nb.s > cur.s else cur, cur if nb.s > cur.s else nb)

## Length of the run that would form if a ball of colour c were inserted at list position k
## (between balls[k-1] and balls[k]).
static func preview_run(balls: Array, k: int, c: int, enter_s: float) -> int:
	var n: int = 1
	var j: int = k - 1
	var prev_s: float = INF
	while j >= 0:
		var b: Ball = balls[j]
		if b.matchable() and b.color == c and b.s >= enter_s:
			n += 1
			j -= 1
		else:
			break
	j = k
	while j < balls.size():
		var b2: Ball = balls[j]
		if b2.matchable() and b2.color == c and b2.s >= enter_s:
			n += 1
			j += 1
		else:
			break
	return n
