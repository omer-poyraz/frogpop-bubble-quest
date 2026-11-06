class_name PowerUpManager
extends RefCounted
## Inventory + timed effects for the 7 power-ups.

const SLOW_TIME: float = 6.0
const SLOW_FACTOR: float = 0.3
const SHIELD_TIME: float = 8.0
const REVERSE_TIME: float = 2.4
const REVERSE_SPEED: float = 420.0
const LIGHTNING_COUNT: int = 9
const METER_STEP: int = 1800

var inventory: Dictionary = {}
var slow_t: float = 0.0
var shield_t: float = 0.0
var reverse_t: float = 0.0
var bomb_armed: bool = false
var meter: float = 0.0
var meter_points: int = 0
var used_count: int = 0

func setup(inv: Dictionary) -> void:
	inventory = inv.duplicate()
	for p in K.POWERS:
		if not inventory.has(p):
			inventory[p] = 0
	slow_t = 0.0
	shield_t = 0.0
	reverse_t = 0.0
	bomb_armed = false
	meter = 0.0
	meter_points = 0

func count(p: String) -> int:
	return int(inventory.get(p, 0))

func tick(dt: float) -> void:
	slow_t = maxf(slow_t - dt, 0.0)
	shield_t = maxf(shield_t - dt, 0.0)
	reverse_t = maxf(reverse_t - dt, 0.0)

func speed_factor() -> float:
	return SLOW_FACTOR if slow_t > 0.0 else 1.0

## Adds points toward the free-power meter; returns a power name when it fills.
func add_points(pts: int, rng: RandomNumberGenerator) -> String:
	meter_points += pts
	meter = float(meter_points % METER_STEP) / float(METER_STEP)
	if meter_points >= METER_STEP:
		meter_points -= METER_STEP
		meter = float(meter_points) / float(METER_STEP)
		var p: String = K.POWERS[rng.randi() % K.POWERS.size()]
		inventory[p] = count(p) + 1
		return p
	return ""

func consume(p: String) -> bool:
	if count(p) <= 0:
		return false
	inventory[p] = count(p) - 1
	used_count += 1
	return true
