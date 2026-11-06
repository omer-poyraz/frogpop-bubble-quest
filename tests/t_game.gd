extends RefCounted

func _core(mode: String = "classic", sd: int = 5, wave: int = 1) -> GameCore:
	var c := GameCore.new()
	var inv: Dictionary = {}
	for p in K.POWERS:
		inv[p] = 3
	c.start(mode, sd, inv, wave)
	return c

func _advance(c: GameCore, seconds: float) -> void:
	var n: int = int(seconds * 60.0)
	for i in n:
		c.update(1.0 / 60.0)

func test_intro_then_playing(t: Node) -> void:
	var c: GameCore = _core()
	t.check(c.state == GameCore.State.INTRO, "starts in intro")
	_advance(c, 25.0)
	t.check(c.state == GameCore.State.PLAYING or c.state == GameCore.State.LOST, "after intro")
	t.check(c.chain.fully_entered(), "chain fully entered")

func test_fire_creates_projectile_and_reloads(t: Node) -> void:
	var c: GameCore = _core()
	_advance(c, 3.0)
	var ammo: int = c.ammo
	t.check(c.fire(c.frog_pos + Vector2(0, -300)), "fire ok")
	t.check(c.projectiles.size() == 1, "projectile")
	t.check(not c.fire(c.frog_pos + Vector2(0, -300)), "reload blocks second shot")
	t.check(c.ammo != -1 and ammo != -1, "ammo valid")

func test_hole_loses_without_shield(t: Node) -> void:
	var c: GameCore = _core()
	var over: Array = []
	c.game_over.connect(func(i: Dictionary) -> void: over.append(i))
	_advance(c, 300.0)
	t.check(over.size() == 1 and over[0]["reason"] == "hole", "lost by reaching the hole")
	t.check(c.state == GameCore.State.LOST, "state lost")

func test_zen_never_loses(t: Node) -> void:
	var c: GameCore = _core("zen")
	_advance(c, 300.0)
	t.check(c.state != GameCore.State.LOST and c.state != GameCore.State.ENDED, "zen has no loss")
	t.check(c.chain.check_invariants() == "", "zen invariants")

func test_time_attack_ends(t: Node) -> void:
	var c: GameCore = _core("time")
	var over: Array = []
	c.game_over.connect(func(i: Dictionary) -> void: over.append(i))
	_advance(c, 95.0)
	t.check(over.size() == 1 and (over[0]["reason"] == "time" or over[0]["reason"] == "hole"), "time attack finished")

func test_shield_prevents_loss(t: Node) -> void:
	var c: GameCore = _core()
	_advance(c, 3.0)
	c.power.inventory["shield"] = 5
	t.check(c.use_power("shield"), "shield used")
	t.check(c.power.shield_t > 0.0, "shield active")
	c.chain.balls[0].s = c.path.length - 200.0
	_advance(c, 6.0)
	t.check(c.state != GameCore.State.LOST, "shield blocks the hole")

func test_all_powers_work(t: Node) -> void:
	var c: GameCore = _core("classic", 9, 3)
	_advance(c, 20.0)
	t.check(c.state == GameCore.State.PLAYING, "playing (%d)" % c.state)
	var before: int = c.chain.count()
	# rainbow
	var col: int = c.best_color()
	var of_col: int = c.chain.balls_of_color(col).size()
	t.check(c.use_power("rainbow", col), "rainbow")
	t.check(c.chain.count() == before - of_col, "rainbow removed all of that colour")
	# bomb
	t.check(c.use_power("bomb") and c.power.bomb_armed, "bomb armed")
	c.fire(c.chain.world_pos(c.chain.balls[c.chain.balls.size() / 2]))
	var n0: int = c.chain.count()
	_advance(c, 1.2)
	t.check(c.chain.count() < n0, "bomb projectile blew up balls")
	# slow
	t.check(c.use_power("slow") and c.power.speed_factor() < 1.0, "slow")
	# switch
	var a0: int = c.ammo
	t.check(c.use_power("switch"), "switch")
	t.check(c.ammo >= 0, "switch ammo valid %d->%d" % [a0, c.ammo])
	# lightning removes front balls
	var f0: int = c.chain.count()
	t.check(c.use_power("lightning"), "lightning")
	t.check(c.chain.count() < f0, "lightning cleared front")
	# shield
	t.check(c.use_power("shield") and c.power.shield_t > 0.0, "shield")
	# backward moves chain back
	c.power.shield_t = 0.0
	var fs: float = c.chain.front_s()
	t.check(c.use_power("backward"), "backward")
	_advance(c, 1.0)
	t.check(c.chain.front_s() < fs, "chain moved back")
	t.check(c.power.used_count >= 7, "usage counted")
	t.check(c.chain.check_invariants() == "", "invariants after powers")

func test_power_needs_stock(t: Node) -> void:
	var c: GameCore = GameCore.new()
	c.start("classic", 4, {})
	_advance(c, 20.0)
	t.check(not c.use_power("lightning"), "no stock => refused")

func test_score_rules(t: Node) -> void:
	var sm := ScoreManager.new()
	var balls: Array = []
	for i in 3:
		balls.append(Ball.new(1, 0.0))
	var info: Dictionary = {"balls": balls, "run": 3, "level": 0, "source": "shot"}
	var a0: Dictionary = sm.award(info, 1, 0.0)
	info["level"] = 2
	var a1: Dictionary = sm.award(info, 1, 0.0)
	t.check(a1["points"] > a0["points"], "chain reaction pays more")
	info["level"] = 0
	var a2: Dictionary = sm.award(info, 6, 0.0)
	t.check(a2["points"] > a0["points"], "streak pays more")
	var a3: Dictionary = sm.award(info, 1, 0.95)
	t.check("sc_last_second" in a3["labels"], "last second save")
	balls[0].golden = true
	var a4: Dictionary = sm.award(info, 1, 0.0)
	t.check("sc_golden" in a4["labels"], "golden burst")

func test_difficulty_curve_monotonic_bounded(t: Node) -> void:
	var ps: float = 0.0
	var pc: int = 0
	var pcol: int = 0
	for w in range(1, 2001):
		var s: float = Difficulty.speed(w)
		var c: int = Difficulty.ball_count(w)
		var col: int = Difficulty.color_count(w)
		t.check(s >= ps - 0.0001 and c >= pc and col >= pcol, "monotonic wave %d" % w)
		t.check(s <= Difficulty.SPEED_MAX and c <= Difficulty.COUNT_MAX and col <= K.NORMAL_COLORS, "bounded wave %d" % w)
		ps = s
		pc = c
		pcol = col
	t.check(Difficulty.color_count(1) == 4 and Difficulty.color_count(500) == 8, "colours 4 -> 8")

func test_world_order_no_repeat(t: Node) -> void:
	var prev: int = -1
	for wave in range(1, 400):
		var w: int = ThemeManager.world_for_wave(wave, 77)
		var grp: int = (wave - 1) / 3
		if wave > 1 and (wave - 1) % 3 == 0:
			t.check(w != prev, "world changes between groups at wave %d" % wave)
		if (wave - 1) % 3 != 0:
			t.check(w == prev, "world constant inside group")
		prev = w
	t.check(ThemeManager.count() == 10, "10 worlds")

func test_daily_mode_three_waves(t: Node) -> void:
	var c: GameCore = _core("daily", 123)
	var over: Array = []
	c.game_over.connect(func(i: Dictionary) -> void: over.append(i))
	var bot := Bot.new()
	var steps: int = 0
	while over.is_empty() and steps < 60 * 400:
		c.update(1.0 / 60.0)
		bot.tick(c, 1.0 / 60.0)
		steps += 1
	t.check(not over.is_empty(), "daily finishes")
	if not over.is_empty():
		t.check(over[0]["reason"] in ["daily_done", "hole"], "daily reason %s" % over[0]["reason"])

func test_revive_clears_front(t: Node) -> void:
	var c: GameCore = _core()
	_advance(c, 300.0)
	t.check(c.state == GameCore.State.LOST, "lost first")
	c.revive()
	t.check(c.state == GameCore.State.PLAYING and c.continued, "revived once")
	t.check(c.chain.front_s() < c.path.length - 300.0, "front cleared")
