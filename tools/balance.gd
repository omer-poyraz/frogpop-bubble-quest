extends SceneTree
## Bot win-rate per difficulty tier (skill 0.92 greedy bot). usage: godot --headless --path . --script tools/balance.gd
func _init() -> void:
	var out: Array[String] = []
	for wave in [1, 10, 30, 60, 100, 150, 300, 1000]:
		var wins: int = 0
		var n: int = 10
		for sd in n:
			var c := GameCore.new()
			c.start("classic", 9100 + sd * 37 + wave, {}, wave)
			var bot := Bot.new()
			bot.skill = 0.92
			bot.rng.seed = sd + wave
			var steps: int = 0
			while c.wave == wave and c.state != GameCore.State.LOST and steps < 60 * 150:
				c.update(1.0 / 60.0)
				bot.tick(c, 1.0 / 60.0)
				steps += 1
			if c.wave > wave:
				wins += 1
		out.append("wave %4d: %d/%d  (speed %.0f, balls %d, colours %d)" % [wave, wins, n, Difficulty.speed(wave), Difficulty.ball_count(wave), Difficulty.color_count(wave)])
		print(out[-1])
	quit()
