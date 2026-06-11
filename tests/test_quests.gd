extends RefCounted

const MetaProgressionSystemScript = preload("res://scripts/systems/MetaProgressionSystem.gd")

func run(t) -> void:
	test_quests_complete_and_reward_after_run(t)
	test_quest_rewards_unlock_characters(t)

func _fresh_save() -> SaveSystem:
	var save := SaveSystem.new("user://test_quests.save")
	save.save_data({})
	save.reset_play_data("RESET")
	return save

func _summary() -> Dictionary:
	return {
		"score": 500000,
		"survival_time": 1200.0,
		"kills": 5000,
		"crystals_destroyed": 300,
		"chests_opened": 12,
		"max_combo": 500,
		"boss_defeats": 1,
		"boss_defeated_ids": ["boss_30"],
		"rune_contracts": ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"],
		"weapon_levels": {"magic_bolt": 8},
		"weapon_kill_counts": {"mirror_shard": 1000},
		"evolved_weapon_ids": ["magic_bolt"],
		"evolved_weapon_count": 1,
		"enemy_seen": ["normal"],
		"title_badges": ["終末突破"]
	}

func test_quests_complete_and_reward_after_run(t) -> void:
	var save := _fresh_save()
	var meta = MetaProgressionSystemScript.new()
	var result: Dictionary = meta.update_after_run(save, _summary())
	var completed: Array = result.get("quests_completed", [])
	t.assert_true(completed.has("survive_10"), "10 minute survival quest should complete")
	t.assert_true(completed.has("survive_20"), "20 minute survival quest should complete")
	t.assert_true(completed.has("kill_5000"), "kill quest should complete")
	t.assert_true(completed.has("boss_30"), "boss quest should complete")

func test_quest_rewards_unlock_characters(t) -> void:
	var save := _fresh_save()
	var meta = MetaProgressionSystemScript.new()
	meta.update_after_run(save, _summary())
	var data := save.load_data()
	t.assert_true((data["unlocked_characters"] as Array).has("atlas"), "survive 20 quest should unlock Atlas")
	t.assert_true((data["unlocked_characters"] as Array).has("gantz"), "crystal quest should unlock Gantz")
	t.assert_true((data["unlocked_characters"] as Array).has("nero"), "contract quest should unlock Nero")
	t.assert_true((data["unlocked_characters"] as Array).has("zero"), "boss quest should unlock Zero")
	t.assert_true((data["unlocked_characters"] as Array).has("collector"), "max combo should unlock Collector")
