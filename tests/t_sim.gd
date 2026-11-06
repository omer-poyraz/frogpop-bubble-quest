extends RefCounted

func test_bot_never_violates_invariants_all_routes(t: Node) -> void:
	for wave in [1, 3, 6, 9, 12, 20, 30, 50]:
		var c := GameCore.new()
		c.start("classic", 900 + wave, {}, wave)
		var bot := Bot.new()
		var steps: int = 0
		var bad: String = ""
		while c.state != GameCore.State.LOST and c.state != GameCore.State.ENDED and steps < 60 * 90:
			c.update(1.0 / 60.0)
			bot.tick(c, 1.0 / 60.0)
			bad = c.chain.check_invariants()
			if bad != "":
				break
			steps += 1
		t.check(bad == "", "wave %d route %s invariant: %s" % [wave, c.path.kind, bad])

func test_bot_wins_early_waves(t: Node) -> void:
	var wins: int = 0
	var total: int = 0
	for wave in [1, 2, 3, 4, 5, 6]:
		for sd in 3:
			var c := GameCore.new()
			c.start("classic", 400 + sd * 13 + wave, {}, wave)
			var bot := Bot.new()
			var steps: int = 0
			while c.wave == wave and c.state != GameCore.State.LOST and steps < 60 * 150:
				c.update(1.0 / 60.0)
				bot.tick(c, 1.0 / 60.0)
				steps += 1
			total += 1
			if c.wave > wave:
				wins += 1
	t.check(wins >= total - 4, "bot wins most early waves (%d/%d)" % [wins, total])

func test_thousand_waves_params_and_routes(t: Node) -> void:
	# 1000 waves: generate route + sequence, check validity and bounded size (cheap, no play)
	var prev_type: String = ""
	for wave in range(1, 1001):
		var p: Dictionary = Difficulty.params(wave, "classic")
		var rt: String = Difficulty.route_type(wave, 4242, prev_type)
		t.check(rt != prev_type or PathGenerator.types_for_wave(wave).size() == 1, "route differs from previous at %d" % wave)
		prev_type = rt
		if wave % 25 == 0 or Difficulty.is_boss(wave) and wave % 100 == 0:
			var pd: PathData = PathGenerator.generate(rt, hash([4242, wave]))
			t.check(PathGenerator.validate(pd) == "", "wave %d route valid" % wave)
			var rng := RandomNumberGenerator.new()
			rng.seed = wave
			var seq: Dictionary = Difficulty.make_sequence(p, rng, int(0.6 * (pd.length - pd.enter_s) / K.BALL_D))
			t.check((seq["colors"] as Array).size() <= 90, "bounded chain %d" % wave)
			# no accidental triples in the initial layout
			var cols: Array = seq["colors"]
			var kinds: Array = seq["kinds"]
			var triple: bool = false
			for i in range(2, cols.size()):
				if cols[i] == cols[i - 1] and cols[i] == cols[i - 2] and (kinds[i] & 3) != K.KIND_STONE and (kinds[i - 1] & 3) != K.KIND_STONE and (kinds[i - 2] & 3) != K.KIND_STONE:
					triple = true
			t.check(not triple, "no initial triples at wave %d" % wave)

func test_bot_1000_waves_stress(t: Node) -> void:
	# Fast-forward through 1000 waves of parameters with short bot bursts: no crash / invariant break.
	var broken: int = 0
	for wave in range(1, 1001, 7):
		var c := GameCore.new()
		c.start("classic", wave, {}, wave)
		var bot := Bot.new()
		for i in 240:
			c.update(1.0 / 30.0)
			bot.tick(c, 1.0 / 30.0)
			if c.chain.check_invariants() != "":
				broken += 1
				break
			if c.state == GameCore.State.LOST:
				break
	t.check(broken == 0, "no invariant violations across ~143 sampled waves (%d)" % broken)

func test_balance_win_rate_by_tier(t: Node) -> void:
	# Records bot win rate per difficulty tier into build/balance.txt (informational + sanity bound).
	var lines: Array[String] = []
	var tiers: Array = [1, 5, 10, 20, 40, 80, 150]
	for wave in tiers:
		var wins: int = 0
		var n: int = 4
		for sd in n:
			var c := GameCore.new()
			c.start("classic", 7000 + sd * 31 + wave, {}, wave)
			var bot := Bot.new()
			bot.skill = 0.92
			bot.rng.seed = sd + wave
			var steps: int = 0
			while c.wave == wave and c.state != GameCore.State.LOST and steps < 60 * 120:
				c.update(1.0 / 60.0)
				bot.tick(c, 1.0 / 60.0)
				steps += 1
			if c.wave > wave:
				wins += 1
		lines.append("wave %d: bot clears %d/%d" % [wave, wins, n])
		t.check(wins >= 1, "tier %d is winnable (%d/%d)" % [wave, wins, n])
	var f: FileAccess = FileAccess.open("res://build/balance.txt", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines))
