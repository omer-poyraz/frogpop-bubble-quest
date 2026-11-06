class_name K
extends RefCounted
## Global constants and static tables (no magic numbers elsewhere).

const FIELD_W: float = 1080.0
const FIELD_H: float = 1920.0
const BALL_D: float = 76.0
const BALL_R: float = 38.0
const STEP: float = 1.0 / 120.0
const MAX_STEPS_PER_FRAME: int = 10
const CONTACT_EPS: float = 2.5
const SHOT_SPEED: float = 2700.0
const RELOAD_TIME: float = 0.16
const INTRO_SPEED: float = 760.0
const BACK_SPEED: float = 520.0
const HIT_RADIUS: float = 66.0
const BOMB_RADIUS: float = 230.0
const FROG_CLEAR: float = 170.0
const PATH_STEP: float = 4.0
const MIN_RUN: int = 3

const NORMAL_COLORS: int = 8
const RAINBOW: int = 9

# Ball kinds
const KIND_NORMAL: int = 0
const KIND_BOMB: int = 1
const KIND_STONE: int = 2

const COLOR_NAMES: Array[String] = ["red", "blue", "yellow", "green", "purple", "orange", "pink", "turquoise"]
const BALL_COLORS: Array[Color] = [
	Color("ff4a5e"), Color("3d8bff"), Color("ffd23c"), Color("3fd96a"),
	Color("a65bff"), Color("ff8a2a"), Color("ff7ac8"), Color("27d6d0")]

const POWERS: Array[String] = ["rainbow", "bomb", "slow", "switch", "lightning", "shield", "backward"]
const POWER_PRICE: Dictionary = {"rainbow": 120, "bomb": 80, "slow": 60, "switch": 40, "lightning": 140, "shield": 100, "backward": 90}

const MODES: Array[String] = ["classic", "time", "zen", "daily"]
const WORLD_COUNT: int = 10
const BG_VARIANTS: int = 3

static func color_of(idx: int) -> Color:
	if idx >= 0 and idx < BALL_COLORS.size():
		return BALL_COLORS[idx]
	return Color.WHITE
