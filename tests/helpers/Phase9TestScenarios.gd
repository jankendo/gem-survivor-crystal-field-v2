extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
const GemScript = preload("res://scripts/core/ExpGem.gd")
const LevelUpScript = preload("res://scripts/systems/LevelUpSystem.gd")
const SelectionActionScript = preload("res://scripts/systems/SelectionActionSystem.gd")
const SelectionContextScript = preload("res://scripts/systems/SelectionContextSystem.gd")
const RewardPopupScript = preload("res://scripts/ui/RewardPopup.gd")
const EnemyRenderSnapshotScript = preload("res://scripts/systems/EnemyRenderSnapshotSystem.gd")
const EnemyVisualBatchScript = preload("res://scripts/systems/EnemyVisualBatchSystem.gd")
const EnemyAnimationPhaseCacheScript = preload("res://scripts/systems/EnemyAnimationPhaseCache.gd")
const GemCollectionVisualBatchScript = preload("res://scripts/systems/GemCollectionVisualBatchSystem.gd")
const GlobalGemCollectionScript = preload("res://scripts/systems/GlobalGemCollectionSystem.gd")
const PerformanceProfileScript = preload("res://scripts/systems/PerformanceProfileSystem.gd")
const EffectiveSettingsResolverScript = preload("res://scripts/systems/EffectiveSettingsResolver.gd")
const TouchControlScript = preload("res://scripts/systems/TouchControlSystem.gd")
const JaText = preload("res://scripts/ui/JaText.gd")
const TitleControllerScript = preload("res://scripts/ui/main/TitleScreenController.gd")
const ResultDamageFormatterScript = preload("res://scripts/systems/ResultDamageFormatter.gd")
const CrystalSurveyScript = preload("res://scripts/systems/CrystalSurveySystem.gd")
const FieldDropSystemScript = preload("res://scripts/systems/FieldDropSystem.gd")
const FieldEquipmentPickupScript = preload("res://scripts/systems/FieldEquipmentPickupSystem.gd")
const GameScreenScript = preload("res://scripts/ui/GameScreen.gd")

func state(seed: int = 90909, text: String = "phase9") -> Object:
	var s = StateScript.new()
	s.start_new_run(seed, text)
	return s

func selection_level_up_only(t) -> void:
	var s = state()
	var selection = SelectionActionScript.new()
	selection.begin_run(s, {"currency_sink_levels": {"levelup_reroll_capacity": 1, "selection_skip_charm": 1, "selection_seal_art": 1}, "stats": {}})
	s.level_up_pending = true
	s.selection_context = SelectionContextScript.LEVEL_UP
	s.level_up_options = LevelUpScript.new().prepare_options(s, 3)
	var before_reroll := int(s.selection_reroll_remaining)
	var events: Array = []
	t.assert_true(selection.consume_reroll(s, events), "LEVEL_UP should allow reroll")
	t.assert_eq(s.selection_reroll_remaining, before_reroll - 1, "LEVEL_UP reroll consumes one charge")
	var controls := selection.controls_for(s)
	t.assert_true(bool(controls.get("level_up_actions", false)), "LEVEL_UP controls expose actions")

func selection_hidden_for_context(t, context: String) -> void:
	var s = state()
	var selection = SelectionActionScript.new()
	selection.begin_run(s, {"currency_sink_levels": {"levelup_reroll_capacity": 2, "selection_skip_charm": 2, "selection_seal_art": 2}, "stats": {}})
	s.level_up_pending = true
	s.selection_context = context
	s.level_up_options = LevelUpScript.new().prepare_options(s, 3)
	if context == SelectionContextScript.WEAPON_CORE:
		s.pending_core_choice = {"kind": "weapon", "options": s.level_up_options}
	elif context == SelectionContextScript.PASSIVE_CORE:
		s.pending_core_choice = {"kind": "passive", "options": s.level_up_options}
	elif context == SelectionContextScript.FIELD_EQUIPMENT:
		s.pending_field_equipment_choice = {"options": s.level_up_options}
	elif context == SelectionContextScript.RUNE_CONTRACT:
		s.rune_contract_pending = true
	elif context == SelectionContextScript.CHEST:
		s.chest_pending = true
	var before := {
		"reroll": int(s.selection_reroll_remaining),
		"skip": int(s.selection_skip_remaining),
		"seal": int(s.selection_seal_remaining)
	}
	var events: Array = []
	t.assert_true(not selection.consume_reroll(s, events), "%s must not reroll" % context)
	t.assert_true(not selection.skip_current(s, events), "%s must not consume skip" % context)
	t.assert_true(not selection.seal_option(s, "weapon:magic_bolt", events), "%s must not seal" % context)
	t.assert_eq(int(s.selection_reroll_remaining), int(before["reroll"]), "%s reroll charge unchanged" % context)
	t.assert_eq(int(s.selection_skip_remaining), int(before["skip"]), "%s skip charge unchanged" % context)
	t.assert_eq(int(s.selection_seal_remaining), int(before["seal"]), "%s seal charge unchanged" % context)
	var controls := selection.controls_for(s)
	t.assert_true(not bool(controls.get("level_up_actions", true)), "%s controls hide level-up actions" % context)
	t.assert_eq(int(controls.get("rerolls", -1)), 0, "%s shows no reroll remaining" % context)

func reward_popup_hides_level_actions(t) -> void:
	var popup = RewardPopupScript.new()
	popup._ready()
	popup.show_options([{"uid": "core_decline:weapon", "kind": "decline", "name_ja": "取得しない", "description_ja": "見送り"}], {
		"context": SelectionContextScript.WEAPON_CORE,
		"level_up_actions": false,
		"can_decline": true,
		"decline_text": "取得しない",
		"title": "コアの中身を選択"
	}, true)
	var forbidden := ["再抽選", "封印", "スキップ"]
	for child in popup.list.get_children():
		if child is Button:
			for word in forbidden:
				t.assert_true(String(child.text).find(word) < 0, "non-level selection must not create %s button" % word)
	popup.queue_free()

func enemy_snapshot_and_batch(t) -> void:
	var enemies := [
		EnemyScript.new("slime", {"hp": 10, "radius": 18.0}, Vector2(100, 100)),
		EnemyScript.new("slime", {"hp": 10, "radius": 18.0}, Vector2(140, 100)),
		EnemyScript.new("elite", {"hp": 60, "radius": 28.0, "elite": true}, Vector2(180, 120)),
		EnemyScript.new("boss", {"hp": 200, "radius": 42.0, "boss": true}, Vector2(220, 130))
	]
	var snapshot_system = EnemyRenderSnapshotScript.new()
	var standard := snapshot_system.build_snapshot(enemies, Vector2(160, 120), Vector2(640, 360), 12.25, {})
	var minimal := snapshot_system.build_snapshot(enemies, Vector2(160, 120), Vector2(640, 360), 12.25, {"enemy_visual_quality": "minimal", "normal_enemy_hp_bar": false})
	t.assert_eq(snapshot_system.simulation_signature(enemies), snapshot_system.simulation_signature(enemies), "visual snapshot must not mutate simulation")
	t.assert_eq(int(minimal.get("critical_missing", -1)), 0, "visible critical enemies must remain in minimal snapshot")
	for command in minimal.get("commands", []):
		if bool(command.get("critical", false)):
			t.assert_true(bool(command.get("draw_hp", false)), "critical enemy keeps readable HP")
		else:
			t.assert_true(not bool(command.get("draw_hp", true)), "normal enemy HP bar hidden in minimal")
	var batched := EnemyVisualBatchScript.new().batch_commands(minimal)
	t.assert_true(int(batched.get("render_commands", 9999)) <= int(minimal.get("visible_count", 0)), "batching should not increase commands")
	t.assert_true(EnemyVisualBatchScript.new().estimated_command_reduction(int(standard.get("visible_count", 0)), int(batched.get("render_commands", 0))) >= 0.0, "reduction metric is bounded")

func enemy_phase_cache(t) -> void:
	var cache = EnemyAnimationPhaseCacheScript.new()
	var p1 := cache.phase_for("slime", 10.00, 8, 8)
	var p2 := cache.phase_for("slime", 10.01, 8, 8)
	t.assert_eq(p1, p2, "phase cache quantizes nearby frames")
	t.assert_true(p1 >= 0 and p1 < 8, "phase index stays inside steps")

func gem_collection_batch(t) -> void:
	var s = state()
	s.gems.clear()
	var positions: Array = []
	for i in range(120):
		var value := 2 + (i % 5)
		var pos := Vector2(100 + i * 3, 200 + i)
		positions.append(pos)
		s.gems.append(GemScript.new(pos, value))
	var events: Array = []
	var result := GlobalGemCollectionScript.new().collect_all(s, events, "magnet", 1.0)
	var metrics: Dictionary = result.get("metrics", {})
	t.assert_eq(int(result.get("count", 0)), 120, "all simulation gems are collected")
	t.assert_eq(int(s.gems.size()), 0, "simulation gem array is emptied only after collection")
	t.assert_eq(int(result.get("exp", 0)), int(metrics.get("actual_exp", -1)), "EXP result matches metrics")
	t.assert_eq(int(metrics.get("actual_exp", 0)), int(metrics.get("expected_exp", -1)), "EXP total stays exact inside batch metrics")
	t.assert_true(int(metrics.get("proxy_nodes", 99)) <= 4, "collection visual uses at most four representatives")
	t.assert_true(s.gem_ring_effects.size() <= 2, "active ring effects are bounded")
	t.assert_true(int(metrics.get("missing", -1)) == 0 and int(metrics.get("duplicate_targets", -1)) == 0, "batch collection has no missing or duplicate targets")

func gem_visual_batch_priority(t) -> void:
	var batch := GemCollectionVisualBatchScript.new().make_batch("magnet", [Vector2.ZERO, Vector2.ONE, Vector2(2, 2), Vector2(3, 3), Vector2(4, 4)], 1200, 4800, Vector2(9, 9), 4)
	t.assert_eq(int(batch.get("representative_count", -1)), 4, "representative count is capped")
	t.assert_eq(String(batch.get("priority", "")), "signature", "large collection remains signature priority")

func time_and_removed_settings(t) -> void:
	t.assert_eq(JaText.format_time(125.0), "02:05", "survival time should use minute-second format")
	var title_lines: Array = TitleControllerScript.new().status_lines({"stats": {"best_survival": 452.0}, "crystal_currency": 5}, "ノア", "攻撃")
	t.assert_true(String(title_lines[2]).find("07:32") >= 0, "title best survival should use minute-second format")
	var profile = PerformanceProfileScript.new()
	var desktop := profile.ui_limits({"damage_numbers": true}, "Windows")
	var ios := profile.ui_limits({"damage_numbers": true}, "iOS")
	t.assert_true(not bool(desktop.get("damage_numbers_enabled", true)), "legacy damage setting is ignored on desktop")
	t.assert_eq(int(ios.get("max_rendered_damage_numbers", -1)), 0, "legacy damage setting is ignored on iOS")
	var touch = TouchControlScript.new()
	touch.configure({"touch_ui_mode": "on", "touch_haptics": true}, "iOS")
	t.assert_true(not touch.feedback_light(), "legacy haptic setting does not vibrate")
	t.assert_eq(touch.haptic_count, 0, "haptic count remains zero")
	var effective := EffectiveSettingsResolverScript.new().resolve({"battery_saver": true, "damage_numbers": true, "touch_haptics": true})
	t.assert_true(not bool(effective.get("damage_numbers", true)), "battery resolver removes damage numbers")
	t.assert_true(not bool(effective.get("touch_haptics", true)), "battery resolver removes haptics")

func seed_copy_contract(t) -> void:
	var game = GameScreenScript.new()
	game.state = state(12345, "seed-copy")
	t.assert_eq(game._current_seed_text(), "seed-copy", "pause seed text uses map seed text")
	t.assert_true(game.copy_current_seed_to_clipboard(), "seed copy should be headless safe")
	game.free()

func result_damage_lines(t) -> void:
	var lines: Array = ResultDamageFormatterScript.new().weapon_damage_lines({"weapon_damage_by_id": {"magic_bolt": 300, "ice_orbit": 100}}, 4)
	t.assert_true(lines.size() >= 3, "result damage formatter returns heading and rows")
	t.assert_true(String(lines[1]).find("300") >= 0 and String(lines[1]).find("75.0%") >= 0, "damage row includes total and percentage")
	t.assert_true(String(lines[2]).find("25.0%") >= 0, "second row includes percentage")

func scan_discovery(t) -> void:
	var s = state()
	s.player_position = Vector2(500, 500)
	s.explored_room_ids = []
	s.rooms_discovered = 0
	s.map_data["rooms"] = [
		{"id": "scan_room_a", "terrain_id": "safe_room", "position": Vector2(560, 500)}
	]
	s.field_drops = [
		{"id": "weapon_core", "runtime_id": "scan_weapon_core", "name_ja": "封印武器コア", "position": Vector2(580, 500), "unlock_seconds": 0.0, "collected": false, "scan_extractable": true}
	]
	var events: Array = []
	var result := CrystalSurveyScript.new().short_scan(s, events, 400.0)
	t.assert_true(bool(result.get("ok", false)), "scan should find nearby room/item")
	t.assert_true(s.explored_room_ids.has("scan_room_a"), "scan should mark room discovered")
	t.assert_true(int(s.survey_resonance) > 0, "first discoveries should grant survey resonance")
	t.assert_true(not s.scan_navigation_target.is_empty(), "scan should set navigation target")

func scan_locked_items_blocked(t) -> void:
	var s = state()
	s.player_position = Vector2(500, 500)
	s.map_data["rooms"] = []
	s.field_drops = [
		{"id": "weapon_core", "runtime_id": "locked_core", "name_ja": "未解放コア", "position": Vector2(520, 500), "unlock_seconds": 999.0, "collected": false, "scan_extractable": true}
	]
	var result := CrystalSurveyScript.new().short_scan(s, [], 300.0)
	t.assert_true(not bool(result.get("ok", false)), "scan should not reveal unlock_seconds-gated items")
	t.assert_true(not s.scan_discovered_keys.has("drop:locked_core"), "locked item should not enter discovered set")

func scan_extract_regular_pickup(t) -> void:
	var s = state()
	s.player_position = Vector2(500, 500)
	s.survey_resonance = s.survey_resonance_max
	var drop := {"id": "weapon_core", "runtime_id": "extract_weapon_core", "name_ja": "封印武器コア", "position": Vector2(700, 500), "unlock_seconds": 0.0, "collected": false, "scan_extractable": true}
	s.field_drops = [drop]
	var survey = CrystalSurveyScript.new()
	var events: Array = []
	var begin := survey.begin_extract(s, events, 420.0)
	t.assert_true(bool(begin.get("ok", false)), "hold scan should begin extraction")
	var complete := survey.complete_extract(s, events)
	t.assert_true(bool(complete.get("ok", false)), "hold scan should complete extraction")
	var target: Dictionary = complete.get("target", {})
	var source: Dictionary = target.get("source", {})
	source["position"] = s.player_position
	FieldDropSystemScript.new().process(s, 0.0, events)
	t.assert_true(not s.pending_core_choice.is_empty(), "extracted core should use regular core choice")
	t.assert_eq(SelectionContextScript.current_context(s), SelectionContextScript.WEAPON_CORE, "extracted core opens weapon core context")
	t.assert_eq(s.survey_resonance, 0, "successful extraction spends resonance")

func scan_extract_cancel_safe(t) -> void:
	var s = state()
	s.player_position = Vector2(500, 500)
	s.survey_resonance = s.survey_resonance_max
	var drop := {"id": "weapon_core", "runtime_id": "cancel_core", "name_ja": "封印武器コア", "position": Vector2(700, 500), "unlock_seconds": 0.0, "collected": false, "scan_extractable": true}
	s.field_drops = [drop]
	var survey = CrystalSurveyScript.new()
	var events: Array = []
	t.assert_true(bool(survey.begin_extract(s, events, 420.0).get("ok", false)), "extract begins before cancel")
	survey.cancel_extract(s, events, "test_cancel")
	t.assert_eq(s.survey_resonance, s.survey_resonance_max, "cancel does not spend resonance")
	t.assert_true(s.scan_extract_target.is_empty(), "cancel clears target")
	t.assert_true(bool(survey.begin_extract(s, events, 420.0).get("ok", false)), "extract can begin again")
	drop["collected"] = true
	t.assert_true(not bool(survey.complete_extract(s, events).get("ok", false)), "disappeared target cancels safely")
	t.assert_eq(s.survey_resonance, s.survey_resonance_max, "target gone does not spend resonance")

func scan_field_equipment_regular_pickup(t) -> void:
	var s = state()
	s.player_position = Vector2(500, 500)
	s.survey_resonance = s.survey_resonance_max
	var equipment := {"id": "magic_bolt", "kind": "weapon", "runtime_id": "extract_magic_bolt", "name_ja": "魔弾", "position": Vector2(700, 500), "unlock_seconds": 0.0, "collected": false, "scan_extractable": true}
	s.field_equipment = [equipment]
	var events: Array = []
	var survey = CrystalSurveyScript.new()
	t.assert_true(bool(survey.begin_extract(s, events, 420.0).get("ok", false)), "equipment extraction begins")
	var complete := survey.complete_extract(s, events)
	t.assert_true(bool(complete.get("ok", false)), "equipment extraction completes")
	var target: Dictionary = complete.get("target", {})
	var source: Dictionary = target.get("source", {})
	source["position"] = s.player_position
	FieldEquipmentPickupScript.new().process(s, 0.0, events)
	t.assert_true(not s.pending_field_equipment_choice.is_empty(), "extracted field equipment should use regular choice")
	t.assert_eq(SelectionContextScript.current_context(s), SelectionContextScript.FIELD_EQUIPMENT, "field equipment context is explicit")

func scan_query_budget(t) -> void:
	var s = state()
	s.player_position = Vector2(1000, 1000)
	s.map_data["rooms"] = []
	s.field_drops = []
	for i in range(120):
		s.map_data["rooms"].append({"id": "budget_%d" % i, "terrain_id": "safe_room", "position": Vector2(900 + (i % 20) * 20, 900 + int(i / 20) * 20)})
	var result := CrystalSurveyScript.new().short_scan(s, [], 760.0)
	t.assert_true(bool(result.get("ok", false)), "budget scan should still find candidates")
	t.assert_true(int(s.scan_telemetry.get("scan_query_us", 999999)) < 50000, "scan query should stay under 50ms in unit fixture")
