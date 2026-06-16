extends SceneTree

const SaveSystemScript = preload("res://scripts/systems/SaveSystem.gd")

var failures: Array = []
var assertions := 0
var original_settings: Dictionary = {}

func _initialize() -> void:
	var save := SaveSystemScript.new()
	original_settings = save.load_data().get("settings", {}).duplicate(true)
	save.update_settings({"touch_ui_mode": "auto"})
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
		"res://tests/test_touch_controls_config.gd",
		"res://tests/test_ios_no_keyboard_required.gd",
		"res://tests/test_ios_touch_selection_screens.gd",
		"res://tests/test_ios_input_text_audit.gd",
		"res://tests/test_ios_safe_area_layout.gd",
		"res://tests/test_ios_menu_layout.gd",
		"res://tests/test_ios_pause_layout.gd",
		"res://tests/test_ios_result_layout.gd",
		"res://tests/test_ios_performance_profile.gd",
		"res://tests/test_no_debug_overlay_on_ios.gd",
		"res://tests/test_ios_character_grid_density.gd",
		"res://tests/test_ios_touch_target_sizes.gd",
		"res://tests/test_ios_map_readability.gd",
		"res://tests/test_ios_hud_readability.gd",
		"res://tests/test_ios_mobile_menu_quality.gd",
		"res://tests/test_ios_ipad_layout.gd",
		"res://tests/test_ios_layout_rect_export.gd",
		"res://tests/test_ios_no_developer_overlay.gd",
		"res://tests/test_desktop_ui_not_mobile_by_default.gd",
		"res://tests/test_ios_debug_overlay_hard_off.gd",
		"res://tests/test_ios_pause_buttons_tappable.gd",
		"res://tests/test_ios_touch_scroll_all_menus.gd",
		"res://tests/test_ios_all_interactive_controls_reachable.gd",
		"res://tests/test_desktop_controls_after_ios_polish.gd",
		"res://tests/test_balance_log_system.gd",
		"res://tests/test_audio_fully_disabled.gd",
		"res://tests/test_generated_assets_complete.gd",
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
		"res://tests/test_weapon_balance_targets.gd",
		"res://tests/test_passive_balance_targets.gd",
		"res://tests/test_evolution_balance_targets.gd",
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
		,"res://tests/test_ios_dynamic_joystick_anywhere_left.gd"
		,"res://tests/test_ios_safe_area_notch_landscape.gd"
		,"res://tests/test_ios_ui_overlap_regression.gd"
		,"res://tests/test_ios_hud_layout_profiles.gd"
		,"res://tests/test_ios_menu_safe_area_overlap.gd"
		,"res://tests/test_ios_ui_update_throttling.gd"
		,"res://tests/test_ios_effect_budget_no_quality_drop.gd"
		,"res://tests/test_ios_object_pooling_stability.gd"
		,"res://tests/test_ios_spatial_optimization.gd"
		,"res://tests/test_ios_performance_logging.gd"
		,"res://tests/test_desktop_unchanged_after_ios_optimization.gd"
		,"res://tests/test_ios_energy_budget.gd"
		,"res://tests/test_ios_energy_logging.gd"
		,"res://tests/test_ios_battery_saver_settings.gd"
		,"res://tests/test_unlock_progress_display.gd"
		,"res://tests/test_progress_counters_persist.gd"
		,"res://tests/test_result_progress_delta.gd"
		,"res://tests/test_wall_collision_smooth_slide.gd"
		,"res://tests/test_blessing_effect_descriptions.gd"
		,"res://tests/test_blessing_ui_ios_readability.gd"
		,"res://tests/test_weapon_passive_toggle_menu.gd"
		,"res://tests/test_disable_slot_unlocks.gd"
		,"res://tests/test_candidate_pool_respects_disabled_items.gd"
		,"res://tests/test_weapon_passive_balance_after_toggle.gd"
		,"res://tests/test_desktop_after_progress_toggle_energy_update.gd"
		,"res://tests/test_selection_skip_seal_actions.gd"
		,"res://tests/test_exploration_reward_rooms.gd"
		,"res://tests/test_exploration_vs_camping_balance.gd"
		,"res://tests/test_event_reward_motivation.gd"
		,"res://tests/test_normal_enemy_no_projectiles_explosives_falling.gd"
		,"res://tests/test_core_pickup_choice_ui.gd"
		,"res://tests/test_field_equipment_placement.gd"
		,"res://tests/test_equipment_over_cap_field_pickup.gd"
		,"res://tests/test_field_equipment_unlocked_only.gd"
		,"res://tests/test_field_equipment_pickup_responsive.gd"
		,"res://tests/test_knockback_does_not_push_enemy_outside_map.gd"
		,"res://tests/test_map_open_pauses_game.gd"
		,"res://tests/test_status_result_ux_quality.gd"
		,"res://tests/test_equipment_grid_ui.gd"
		,"res://tests/test_ios_menu_redesign_quality.gd"
		,"res://tests/test_desktop_after_asset_ui_audio_update.gd"
		,"res://tests/test_ios_safe_play_area_letterbox.gd"
		,"res://tests/test_ios_default_lightweight_settings.gd"
	]
	for suite_path in suites:
		print("Running ", suite_path)
		var suite_script = load(suite_path)
		if suite_script == null or not suite_script.can_instantiate():
			failures.append("Suite failed to load: %s" % suite_path)
			continue
		var suite = suite_script.new()
		if suite == null or not suite.has_method("run"):
			failures.append("Suite has no run(t): %s" % suite_path)
			continue
		suite.run(self)
	save.update_settings(original_settings)
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
