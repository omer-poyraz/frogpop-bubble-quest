extends RefCounted

func test_frame_script_budget(t: Node) -> void:
	# script-side cost per frame while playing a dense late wave (rendering excluded: headless)
	var holder := Control.new()
	holder.size = Vector2(1080, 1920)
	t.add_child(holder)
	var scr: Control = GameManager.make_screen("game", {"mode": "classic", "auto_play": true, "seed": 77, "start_wave": 60})
	scr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(scr)
	await t.get_tree().process_frame
	var total: float = 0.0
	var worst: float = 0.0
	var frames: int = 0
	for i in 900:
		var t0: int = Time.get_ticks_usec()
		scr._process(1.0 / 60.0)
		scr.view._process(1.0 / 60.0)
		var dt: float = float(Time.get_ticks_usec() - t0) / 1000.0
		total += dt
		worst = maxf(worst, dt)
		frames += 1
		if scr.core.state == GameCore.State.LOST:
			break
	var avg: float = total / float(maxi(frames, 1))
	print("perf: avg %.2f ms, worst %.2f ms over %d frames, balls=%d" % [avg, worst, frames, scr.core.chain.count()])
	t.check(avg < 6.0, "average script cost per frame %.2f ms < 6 ms" % avg)
	var f: FileAccess = FileAccess.open("res://build/perf.txt", FileAccess.WRITE)
	if f:
		f.store_string("avg %.2f ms worst %.2f ms frames %d\n" % [avg, worst, frames])
	holder.queue_free()
	AdsManager.in_gameplay = false

func test_memory_stable_over_many_waves(t: Node) -> void:
	# repeatedly create/free cores: object count must not grow without bound
	var before: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	for i in 40:
		var c := GameCore.new()
		c.start("classic", i, {}, 1 + i)
		for k in 120:
			c.update(1.0 / 60.0)
	var mid: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	for i in 40:
		var c2 := GameCore.new()
		c2.start("classic", i + 100, {}, 1 + i)
		for k in 120:
			c2.update(1.0 / 60.0)
	var after: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	t.check(after - mid < 200, "no object growth across runs (before %d mid %d after %d)" % [before, mid, after])

func test_fx_pool_is_bounded(t: Node) -> void:
	var fx := FxLayer.new()
	t.add_child(fx)
	await t.get_tree().process_frame
	for i in 5000:
		fx.burst_pop(Vector2(100, 100), Color.RED, 2.0)
	fx._process(0.016)
	t.check(fx.active <= FxLayer.MAX, "particles capped at %d (active %d)" % [FxLayer.MAX, fx.active])
	fx.queue_free()
