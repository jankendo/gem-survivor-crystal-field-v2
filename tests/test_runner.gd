extends SceneTree

var failures: Array = []
var assertions := 0

func _initialize() -> void:
	var suites := [
		"res://tests/test_player_movement.gd",
		"res://tests/test_weapon_system.gd",
		"res://tests/test_exp_gem_system.gd",
		"res://tests/test_level_up_system.gd",
		"res://tests/test_level_up_no_freeze.gd",
		"res://tests/test_infinite_upgrades.gd",
		"res://tests/test_auto_infinite_option.gd",
		"res://tests/test_enemy_spawner.gd",
		"res://tests/test_spawn_30min_curve.gd",
		"res://tests/test_difficulty_scaling.gd",
		"res://tests/test_difficulty_curve_stronger.gd",
		"res://tests/test_boss_spawn_pacing.gd",
		"res://tests/test_chest_pacing.gd",
		"res://tests/test_boss_chest_spawn_limits.gd",
		"res://tests/test_exp_curve_rebalanced.gd",
		"res://tests/test_overclock_system.gd",
		"res://tests/test_field_events.gd",
		"res://tests/test_rune_contracts.gd",
		"res://tests/test_recall_drone.gd",
		"res://tests/test_chest_evolution_system.gd",
		"res://tests/test_weapon_evolutions_extended.gd",
		"res://tests/test_evolved_weapon_behavior.gd",
		"res://tests/test_crystal_field.gd",
		"res://tests/test_crystal_scaling.gd",
		"res://tests/test_field_size_and_biomes.gd",
		"res://tests/test_treasure_indicator.gd",
		"res://tests/test_boss_patterns.gd",
		"res://tests/test_hp_ui.gd",
		"res://tests/test_performance_limits.gd",
		"res://tests/test_rng.gd",
		"res://tests/test_layout_settings.gd",
		"res://tests/test_export_preset.gd",
		"res://tests/test_audio_assets.gd",
		"res://tests/test_japanese_text.gd",
		"res://tests/test_first_time_help.gd",
		"res://tests/test_character_unlocks.gd",
		"res://tests/test_character_traits.gd",
		"res://tests/test_currency_system.gd",
		"res://tests/test_pause_menu.gd",
		"res://tests/test_evolution_condition_ui.gd",
		"res://tests/test_meta_upgrades.gd",
		"res://tests/test_quests.gd",
		"res://tests/test_save_reset.gd",
		"res://tests/test_collection.gd",
		"res://tests/test_weapon_effect_metadata.gd",
		"res://tests/test_weapon_effect_visibility.gd",
		"res://tests/test_weapon_category_balance.gd",
		"res://tests/test_field_drops.gd",
		"res://tests/test_field_gimmicks.gd",
		"res://tests/test_build_synergies.gd",
		"res://tests/test_melee_rush.gd",
		"res://tests/test_shock_stack.gd",
		"res://tests/test_objective_indicators.gd",
		"res://tests/test_ui_safe_area.gd",
		"res://tests/test_character_assets.gd",
		"res://tests/test_ui_mouse_navigation.gd",
		"res://tests/test_levelup_evolution_hints.gd",
		"res://tests/test_pause_menu_mouse_tabs.gd",
		"res://tests/test_random_map_generation.gd",
		"res://tests/test_map_seed_reproducibility.gd",
		"res://tests/test_vertical_text_bug.gd",
		"res://tests/test_menu_layout_regression.gd",
		"res://tests/test_field_tooltips.gd",
		"res://tests/test_field_help_scan.gd",
		"res://tests/test_dynamic_field_drop_spawn.gd",
		"res://tests/test_weapon_unlocks.gd",
		"res://tests/test_passive_unlocks.gd",
		"res://tests/test_field_events_extended.gd",
		"res://tests/test_exploration_mastery.gd",
		"res://tests/test_exploration_chain.gd"
		,"res://tests/test_no_trash_enemy_projectiles.gd",
		"res://tests/test_procedural_map_generation.gd",
		"res://tests/test_map_connectivity.gd"
		,"res://tests/test_currency_sinks.gd",
		"res://tests/test_added_characters_weapons_passives_evolutions.gd",
		"res://tests/test_collection_filters.gd",
		"res://tests/test_shop_category_ui.gd",
		"res://tests/test_terrain_difficulty_balance.gd"
		,"res://tests/test_speed_hold_system.gd"
		,"res://tests/test_true_dungeon_generation.gd"
		,"res://tests/test_dungeon_collision_pathing.gd"
		,"res://tests/test_notification_log_system.gd"
		,"res://tests/test_boss_alert_system.gd"
		,"res://tests/test_equipment_hud_system.gd"
		,"res://tests/test_effect_completeness.gd"
	]
	for suite_path in suites:
		var suite = load(suite_path).new()
		print("Running ", suite_path)
		suite.run(self)
	if failures.is_empty():
		print("All tests passed: ", assertions)
		quit(0)
	else:
		push_error("%d tests failed." % failures.size())
		for failure in failures:
			push_error(failure)
		quit(1)

func assert_true(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)

func assert_eq(actual, expected, message: String) -> void:
	assertions += 1
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])
