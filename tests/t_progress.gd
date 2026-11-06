extends RefCounted

func _fresh() -> void:
	SaveManager.path_override = "user://test_"
	SaveManager.delete_files()
	SaveManager.load_game()
	ProgressionManager.time_offset_for_tests = 0

func test_save_roundtrip(t: Node) -> void:
	_fresh()
	SaveManager.data["high_score"] = 4242
	SaveManager.data["coins"] = 777
	(SaveManager.data["unlocked_skins"] as Array).append("royal")
	t.check(SaveManager.save(), "save ok")
	SaveManager.data = {}
	SaveManager.load_game()
	t.check(int(SaveManager.data["high_score"]) == 4242 and int(SaveManager.data["coins"]) == 777, "values restored")
	t.check((SaveManager.data["unlocked_skins"] as Array).has("royal"), "skins restored")

func test_save_backup_recovery(t: Node) -> void:
	_fresh()
	SaveManager.data["high_score"] = 100
	SaveManager.save()
	SaveManager.data["high_score"] = 200
	SaveManager.save()   # first file becomes the backup
	# corrupt the main file
	var f: FileAccess = FileAccess.open("user://test_frogpop_save.json", FileAccess.WRITE)
	f.store_string("{ this is not json")
	f.close()
	SaveManager.load_game()
	t.check(SaveManager.recovered_from_backup, "recovered from backup")
	t.check(int(SaveManager.data["high_score"]) == 100, "backup value used (%d)" % int(SaveManager.data["high_score"]))

func test_save_tamper_and_garbage(t: Node) -> void:
	_fresh()
	SaveManager.data["coins"] = 50
	SaveManager.save()
	# hand-edit a value without fixing the checksum
	var txt: String = FileAccess.get_file_as_string("user://test_frogpop_save.json").replace("\"coins\":50", "\"coins\":999999")
	var f: FileAccess = FileAccess.open("user://test_frogpop_save.json", FileAccess.WRITE)
	f.store_string(txt)
	f.close()
	SaveManager.delete_files_backup_only()
	SaveManager.load_game()
	t.check(SaveManager.corrupt_detected, "tamper detected")
	t.check(int(SaveManager.data["coins"]) == 200, "falls back to defaults, not tampered value")
	# garbage everywhere -> defaults, no crash
	var g: FileAccess = FileAccess.open("user://test_frogpop_save.json", FileAccess.WRITE)
	g.store_string("\u0000\u0001garbage")
	g.close()
	SaveManager.load_game()
	t.check(int(SaveManager.data["games_played"]) == 0, "defaults after garbage")

func test_validate_clamps(t: Node) -> void:
	var bad: Dictionary = {"coins": -50, "high_score": "abc", "settings": {"music": 9.0, "quality": 77}, "selected_skin": "nope", "powers": {"bomb": -3}}
	var v: Dictionary = SaveManager.validate(bad)
	t.check(int(v["coins"]) == 0, "negative coins clamped")
	t.check(float(v["settings"]["music"]) == 1.0 and int(v["settings"]["quality"]) == 2, "settings clamped")
	t.check(v["selected_skin"] == "classic", "invalid skin reset")
	t.check(int(v["powers"]["bomb"]) == 0, "powers clamped")

func test_daily_reward_once_per_day(t: Node) -> void:
	_fresh()
	var info: Dictionary = ProgressionManager.daily_info()
	t.check(info["can_claim"], "claimable first time")
	var coins0: int = ProgressionManager.coins()
	var r: Dictionary = ProgressionManager.claim_daily()
	t.check(not r.is_empty() and ProgressionManager.coins() > coins0, "reward paid")
	t.check(ProgressionManager.claim_daily().is_empty(), "second claim same day refused")

func test_daily_streak_and_clock_rollback(t: Node) -> void:
	_fresh()
	ProgressionManager.claim_daily()
	# next day -> streak continues
	ProgressionManager.time_offset_for_tests = 86400 + 60
	var i2: Dictionary = ProgressionManager.daily_info()
	t.check(i2["can_claim"], "claimable next day")
	ProgressionManager.claim_daily()
	t.check(int(SaveManager.data["daily"]["streak"]) == 2, "streak 2")
	# user sets the clock back by 3 days -> no reward, flagged
	ProgressionManager.time_offset_for_tests = -3 * 86400
	var i3: Dictionary = ProgressionManager.daily_info()
	t.check(not i3["can_claim"] and i3["rolled_back"], "rollback blocks reward")
	t.check(ProgressionManager.claim_daily().is_empty(), "no claim during rollback")
	# skipping a day resets the streak
	ProgressionManager.time_offset_for_tests = 4 * 86400
	ProgressionManager.claim_daily()
	t.check(int(SaveManager.data["daily"]["streak"]) == 1, "missed days reset streak")
	ProgressionManager.time_offset_for_tests = 0

func test_missions_progress_and_claim(t: Node) -> void:
	_fresh()
	ProgressionManager.ensure_missions()
	var list: Array = SaveManager.data["missions"]["list"]
	t.check(list.size() == 3, "3 daily missions")
	t.check((SaveManager.data["missions"]["weekly"] as Array).size() == 2, "2 weekly")
	var info: Dictionary = {"score": 999999, "wave": 99, "time": 60.0, "balls": 99999, "best_chain": 9, "best_combo": 99, "coins": 10, "powers_used": 99, "reason": "hole", "mode": "classic"}
	var res: Dictionary = ProgressionManager.report_game(info)
	t.check(res["record"], "record flagged")
	var c0: int = ProgressionManager.coins()
	var claimed: int = 0
	for i in list.size():
		if ProgressionManager.claim_mission(false, i):
			claimed += 1
	t.check(claimed >= 1 and ProgressionManager.coins() > c0, "missions claimable (%d)" % claimed)
	t.check(not ProgressionManager.claim_mission(false, 0), "cannot claim twice")

func test_achievements_and_unlocks(t: Node) -> void:
	_fresh()
	var info: Dictionary = {"score": 6000, "wave": 12, "time": 120.0, "balls": 150, "best_chain": 3, "best_combo": 6, "coins": 5, "powers_used": 0, "reason": "hole", "mode": "classic"}
	var res: Dictionary = ProgressionManager.report_game(info)
	t.check("ach_wave_10" in res["achievements"] and "ach_pop_100" in res["achievements"], "achievements unlocked")
	t.check(ProgressionManager.is_skin_unlocked("pirate"), "pirate costume unlocked by wave 10")
	t.check((SaveManager.data["unlocked_themes"] as Array).size() >= 4, "worlds unlocked by progress")

func test_skin_purchase_and_pro_gating(t: Node) -> void:
	_fresh()
	SaveManager.data["coins"] = 100
	t.check(not ProgressionManager.buy_skin("royal"), "cannot afford")
	SaveManager.data["coins"] = 5000
	t.check(ProgressionManager.buy_skin("royal") and ProgressionManager.select_skin("royal"), "buy + select")
	t.check(int(SaveManager.data["coins"]) == 5000 - 600, "coins deducted")
	t.check(not ProgressionManager.select_skin("galaxy"), "galaxy is PRO only")
	ProgressionManager.set_pro(true, "lifetime")
	t.check(ProgressionManager.select_skin("galaxy"), "PRO unlocks galaxy")
	t.check(ProgressionManager.select_theme(-1), "auto theme")
	(SaveManager.data["unlocked_themes"] as Array).append(9)
	t.check(ProgressionManager.select_theme(9), "PRO can pick galaxy world")
	ProgressionManager.set_pro(false)
	t.check(not ProgressionManager.select_theme(9), "free cannot pick PRO world")
	t.check(ProgressionManager.selected_skin() == "classic", "skin falls back when PRO ends")

func test_powers_inventory(t: Node) -> void:
	_fresh()
	SaveManager.data["coins"] = 1000
	var n0: int = ProgressionManager.power_count("bomb")
	t.check(ProgressionManager.buy_power("bomb"), "buy power")
	t.check(ProgressionManager.power_count("bomb") == n0 + 1, "inventory +1")

func test_pro_purchase_flow_and_ads(t: Node) -> void:
	_fresh()
	AdsManager.in_gameplay = false
	AdsManager.session_interstitials = 0
	AdsManager.last_interstitial_time = -9999.0
	AdsManager.test_ads_enabled = true
	SaveManager.data["games_played"] = 10
	SaveManager.data["ads"]["games_since_ad"] = 5
	t.check(AdsManager.can_show_interstitial(), "interstitial allowed at game end for free user")
	AdsManager.in_gameplay = true
	t.check(not AdsManager.can_show_interstitial(), "never during gameplay")
	AdsManager.in_gameplay = false
	SaveManager.data["games_played"] = 2
	t.check(not AdsManager.can_show_interstitial(), "not in the first 3 games")
	SaveManager.data["games_played"] = 10
	SaveManager.data["ads"]["games_since_ad"] = 1
	t.check(not AdsManager.can_show_interstitial(), "frequency cap")
	SaveManager.data["ads"]["games_since_ad"] = 5
	AdsManager.session_interstitials = 99
	t.check(not AdsManager.can_show_interstitial(), "session cap")
	AdsManager.session_interstitials = 0
	PurchaseManager.grant("frogpop_pro_monthly")
	t.check(ProgressionManager.is_pro(), "PRO granted")
	t.check(not AdsManager.can_show_interstitial(), "PRO sees no ads")
	PurchaseManager.revoke_subscription()
	t.check(not ProgressionManager.is_pro(), "subscription revoked")
	PurchaseManager.grant("frogpop_pro_lifetime")
	PurchaseManager.revoke_subscription()
	t.check(ProgressionManager.is_pro(), "lifetime survives revoke")
	AdsManager.test_ads_enabled = false

func test_no_fake_store_or_ads_without_plugin(t: Node) -> void:
	# In a build without the native plugins the services must report unavailable
	t.check(not PurchaseManager.is_available(), "store unavailable without billing plugin")
	var seen: Array = []
	PurchaseManager.purchase_result.connect(func(p: String, ok: bool, k: String) -> void: seen.append([p, ok, k]), CONNECT_ONE_SHOT)
	PurchaseManager.purchase("frogpop_pro_monthly")
	t.check(seen.size() == 1 and seen[0][1] == false and seen[0][2] == "store_unavailable", "purchase refuses without plugin")
	var was: bool = AdsManager.test_ads_enabled
	AdsManager.test_ads_enabled = false
	t.check(not AdsManager.is_available() and not AdsManager.can_show_rewarded(), "ads unavailable without plugin (release)")
	AdsManager.test_ads_enabled = was

func test_rewarded_continue_flow(t: Node) -> void:
	_fresh()
	AdsManager.in_gameplay = false
	AdsManager.test_ads_enabled = true
	AdsManager.instant_test_ads = true
	var got: Array = []
	AdsManager.rewarded_finished.connect(func(ok: bool) -> void: got.append(ok), CONNECT_ONE_SHOT)
	AdsManager.show_rewarded()
	t.check(got == [true], "rewarded test ad completes")
	AdsManager.in_gameplay = true
	var got2: Array = []
	AdsManager.rewarded_finished.connect(func(ok: bool) -> void: got2.append(ok), CONNECT_ONE_SHOT)
	AdsManager.show_rewarded()
	t.check(got2 == [false], "rewarded refused mid-game")
	AdsManager.in_gameplay = false
	AdsManager.instant_test_ads = false
	AdsManager.test_ads_enabled = false

func test_settings_apply(t: Node) -> void:
	_fresh()
	SettingsManager.set_setting("music", 0.3)
	SettingsManager.set_setting("mute", true)
	var bus: int = AudioServer.get_bus_index("Master")
	t.check(AudioServer.is_bus_mute(bus), "mute applied")
	t.approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))), 0.3, 0.01, "music volume applied")
	SettingsManager.set_setting("mute", false)
	t.check(SettingsManager.particle_scale() > 0.0, "quality scale")
