extends SceneTree
func _init() -> void:
	var t0: int = Time.get_ticks_msec()
	for wv in [1, 5, 15, 40]:
		var wins: int = 0
		var total: int = 3
		for sd in total:
			var core := GameCore.new()
			core.start("classic", 100 + sd, {}, wv)
			var bot := Bot.new()
			var steps: int = 0
			var start_wave: int = core.wave
			while core.state != GameCore.State.LOST and core.state != GameCore.State.ENDED and steps < 60 * 200:
				core.update(1.0 / 60.0)
				bot.tick(core, 1.0 / 60.0)
				var inv: String = core.chain.check_invariants()
				if inv != "":
					print("INVARIANT ", inv)
					break
				steps += 1
				if core.wave > start_wave:
					break
			var cleared: bool = core.wave > start_wave
			if cleared: wins += 1
			print("wave %d seed %d: cleared=%s state=%d steps=%d balls=%d score=%d route=%s" % [wv, sd, cleared, core.state, steps, core.chain.count(), core.score_mgr.score, core.path.kind])
		print("wave %d win %d/%d" % [wv, wins, total])
	print("ms ", Time.get_ticks_msec() - t0)
	quit()
