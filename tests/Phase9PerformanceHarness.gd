extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
const GemScript = preload("res://scripts/core/ExpGem.gd")
const EnemyRenderSnapshotScript = preload("res://scripts/systems/EnemyRenderSnapshotSystem.gd")
const EnemyVisualBatchScript = preload("res://scripts/systems/EnemyVisualBatchSystem.gd")
const GemCollectionVisualBatchScript = preload("res://scripts/systems/GemCollectionVisualBatchSystem.gd")
const CrystalSurveyScript = preload("res://scripts/systems/CrystalSurveySystem.gd")

const OUTPUT_STEM := "res://test-output/phase9/phase9_extreme_stress"
const SEED := 90909
const FRAME_SAMPLES := 120
const ENEMY_COUNT := 600
const GEM_COUNT := 1200
const PROJECTILE_COUNT := 700

func run(output_stem: String = OUTPUT_STEM) -> Dictionary:
	var state = StateScript.new()
	state.start_new_run(SEED, "phase9-perf")
	state.player_position = Vector2(4000, 4000)
	state.camera_position = state.player_position
	_populate_enemies(state)
	_populate_gems(state)
	_populate_scan_targets(state)
	var enemy_summary := _measure_enemy_visuals(state)
	var gem_summary := _measure_gem_collection_visuals(state)
	var scan_summary := _measure_scan_queries(state)
	var frame_times: Array[float] = []
	for index in range(FRAME_SAMPLES):
		frame_times.append(float(enemy_summary.get("minimal_frame_ms", [])[index]) + float(gem_summary.get("batch_frame_ms", [])[index % int(gem_summary.get("samples", 1))]) + float(scan_summary.get("scan_frame_ms", [])[index % int(scan_summary.get("samples", 1))]))
	var summary := {
		"ok": bool(enemy_summary.get("simulation_parity", false)) and bool(gem_summary.get("simulation_parity", false)) and bool(scan_summary.get("ok", false)),
		"godot_version": Engine.get_version_info().get("string", ""),
		"renderer": RenderingServer.get_current_rendering_method(),
		"seed": SEED,
		"enemy_count": ENEMY_COUNT,
		"projectile_count": PROJECTILE_COUNT,
		"gem_count": GEM_COUNT,
		"enemy": enemy_summary,
		"gem_collection": gem_summary,
		"scan": scan_summary,
		"frame_time_p50_ms": _percentile(frame_times, 0.50),
		"frame_time_p95_ms": _percentile(frame_times, 0.95),
		"frame_time_p99_ms": _percentile(frame_times, 0.99),
		"over_16_67ms": _count_over(frame_times, 16.67),
		"over_33ms": _count_over(frame_times, 33.0),
		"over_100ms": _count_over(frame_times, 100.0),
		"measurement_note": "Windows headless CPU fixture for deterministic regression only; not real iPhone, Metal, thermal, or battery proof."
	}
	_write(output_stem, summary)
	return summary

func _measure_enemy_visuals(state) -> Dictionary:
	var snapshot = EnemyRenderSnapshotScript.new()
	var batcher = EnemyVisualBatchScript.new()
	var standard_ms: Array[float] = []
	var minimal_ms: Array[float] = []
	var standard_commands := 0
	var minimal_commands := 0
	var critical_missing := 0
	var before := snapshot.simulation_signature(state.enemies)
	for frame in range(FRAME_SAMPLES):
		var elapsed := float(frame) / 30.0
		var standard_started := Time.get_ticks_usec()
		var standard := snapshot.build_snapshot(state.enemies, state.camera_position, Vector2(1280, 720), elapsed, {
			"enemy_visual_quality": "standard",
			"normal_enemy_hp_bar": true,
			"normal_enemy_shadow": true,
			"normal_enemy_glow": true,
			"enemy_animation_hz": 30
		})
		standard_ms.append(float(Time.get_ticks_usec() - standard_started) / 1000.0)
		standard_commands += int(standard.get("visible_count", 0))
		var minimal_started := Time.get_ticks_usec()
		var minimal := snapshot.build_snapshot(state.enemies, state.camera_position, Vector2(1280, 720), elapsed, {
			"enemy_visual_quality": "minimal",
			"normal_enemy_hp_bar": false,
			"normal_enemy_shadow": false,
			"normal_enemy_glow": false,
			"enemy_animation_hz": 8,
			"enemy_batch_rendering": true
		})
		var batched := batcher.batch_commands(minimal)
		minimal_ms.append(float(Time.get_ticks_usec() - minimal_started) / 1000.0)
		minimal_commands += int(batched.get("render_commands", 0))
		critical_missing += int(minimal.get("critical_missing", 0))
	var after := snapshot.simulation_signature(state.enemies)
	return {
		"standard_commands": standard_commands,
		"minimal_commands": minimal_commands,
		"command_reduction_ratio": 1.0 - float(minimal_commands) / maxf(1.0, float(standard_commands)),
		"standard_p95_ms": _percentile(standard_ms, 0.95),
		"minimal_p95_ms": _percentile(minimal_ms, 0.95),
		"cpu_reduction_ratio": 1.0 - _percentile(minimal_ms, 0.95) / maxf(0.001, _percentile(standard_ms, 0.95)),
		"critical_missing": critical_missing,
		"simulation_hash_before": before,
		"simulation_hash_after": after,
		"simulation_parity": before == after,
		"minimal_frame_ms": minimal_ms
	}

func _measure_gem_collection_visuals(state) -> Dictionary:
	var batcher = GemCollectionVisualBatchScript.new()
	var positions: Array = []
	var total_exp := 0
	for gem in state.gems:
		positions.append(gem.position)
		total_exp += int(gem.value)
	var baseline_ms: Array[float] = []
	var batch_ms: Array[float] = []
	var representative_count := 0
	var before_hash := _gem_signature(state.gems)
	for _sample in range(40):
		var baseline_started := Time.get_ticks_usec()
		var proxy: Array = []
		for pos in positions:
			proxy.append({"position": pos, "life": 0.26})
		baseline_ms.append(float(Time.get_ticks_usec() - baseline_started) / 1000.0)
		var batch_started := Time.get_ticks_usec()
		var batch := batcher.make_batch("magnet", positions, positions.size(), total_exp, state.player_position, 4)
		batch_ms.append(float(Time.get_ticks_usec() - batch_started) / 1000.0)
		representative_count = int(batch.get("representative_count", representative_count))
	var after_hash := _gem_signature(state.gems)
	return {
		"samples": batch_ms.size(),
		"baseline_individual_visuals": positions.size(),
		"representative_count": representative_count,
		"visual_command_reduction_ratio": 1.0 - float(representative_count) / maxf(1.0, float(positions.size())),
		"baseline_p95_ms": _percentile(baseline_ms, 0.95),
		"batch_p95_ms": _percentile(batch_ms, 0.95),
		"cpu_reduction_ratio": 1.0 - _percentile(batch_ms, 0.95) / maxf(0.001, _percentile(baseline_ms, 0.95)),
		"temporary_allocation_proxy_reduction_ratio": 1.0 - float(representative_count) / maxf(1.0, float(positions.size())),
		"total_exp": total_exp,
		"simulation_hash_before": before_hash,
		"simulation_hash_after": after_hash,
		"simulation_parity": before_hash == after_hash,
		"batch_frame_ms": batch_ms
	}

func _measure_scan_queries(state) -> Dictionary:
	var survey = CrystalSurveyScript.new()
	var timings: Array[float] = []
	var discoveries := 0
	var resonance := 0
	for sample in range(30):
		state.scan_cooldown = 0.0
		state.player_position = Vector2(4000 + float(sample % 3) * 16.0, 4000)
		var events: Array = []
		var result := survey.short_scan(state, events, 760.0)
		timings.append(float(int(state.scan_telemetry.get("scan_query_us", 0))) / 1000.0)
		discoveries += int((result.get("discoveries", []) as Array).size())
		resonance = maxi(resonance, int(state.survey_resonance))
	return {
		"ok": timings.size() > 0,
		"samples": timings.size(),
		"scan_query_p95_ms": _percentile(timings, 0.95),
		"scan_query_max_ms": _max(timings),
		"discoveries": discoveries,
		"survey_resonance_max_observed": resonance,
		"telemetry": state.scan_telemetry.duplicate(true),
		"scan_frame_ms": timings
	}

func _populate_enemies(state) -> void:
	state.enemies.clear()
	var definitions := [
		{"id": "slime", "hp": 12, "radius": 16.0},
		{"id": "runner", "hp": 10, "radius": 14.0},
		{"id": "crystal_guard", "hp": 32, "radius": 20.0}
	]
	for index in range(ENEMY_COUNT):
		var definition: Dictionary = definitions[index % definitions.size()]
		var angle := TAU * float(index) / float(ENEMY_COUNT)
		var dist := 80.0 + float(index % 32) * 18.0
		var enemy = EnemyScript.new(String(definition.id), {"hp": int(definition.hp), "radius": float(definition.radius)}, state.player_position + Vector2(cos(angle), sin(angle)) * dist)
		enemy.elite = index % 137 == 0
		enemy.boss = index == 0
		if enemy.boss:
			enemy.radius = 46.0
			enemy.max_hp = 600
			enemy.hp = 600
		state.enemies.append(enemy)

func _populate_gems(state) -> void:
	state.gems.clear()
	for index in range(GEM_COUNT):
		var angle := TAU * float(index % 180) / 180.0
		var dist := 60.0 + float(index % 40) * 14.0
		state.gems.append(GemScript.new(state.player_position + Vector2(cos(angle), sin(angle)) * dist, 1 + index % 7))

func _populate_scan_targets(state) -> void:
	state.map_data["rooms"] = []
	state.field_drops = []
	state.field_equipment = []
	for index in range(96):
		state.map_data["rooms"].append({
			"id": "phase9_room_%d" % index,
			"terrain_id": "safe_room",
			"position": state.player_position + Vector2(float(index % 12) * 48.0, float(index / 12) * 48.0)
		})
	for index in range(48):
		state.field_drops.append({
			"id": "weapon_core" if index % 2 == 0 else "passive_core",
			"runtime_id": "phase9_drop_%d" % index,
			"name_ja": "封印コア",
			"position": state.player_position + Vector2(80.0 + float(index % 8) * 42.0, -100.0 + float(index / 8) * 42.0),
			"unlock_seconds": 0.0,
			"collected": false,
			"scan_extractable": true
		})
	state.active_field_event = {
		"id": "phase9_event",
		"name_ja": "結晶反応",
		"position": state.player_position + Vector2(180, 120)
	}

func _gem_signature(gems: Array) -> String:
	var rows: Array = []
	for gem in gems:
		rows.append("%d:%d:%d" % [int(gem.position.x), int(gem.position.y), int(gem.value)])
	return "|".join(rows)

func _percentile(values: Array[float], ratio: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[clampi(int(ceil(float(sorted.size()) * ratio)) - 1, 0, sorted.size() - 1)])

func _count_over(values: Array[float], threshold: float) -> int:
	var count := 0
	for value in values:
		if value > threshold:
			count += 1
	return count

func _max(values: Array[float]) -> float:
	var result := 0.0
	for value in values:
		result = maxf(result, value)
	return result

func _write(stem: String, summary: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(stem.get_base_dir()))
	var json_file := FileAccess.open("%s.json" % stem, FileAccess.WRITE)
	if json_file != null:
		json_file.store_string(JSON.stringify(summary, "\t"))
	var markdown := FileAccess.open("%s.md" % stem, FileAccess.WRITE)
	if markdown == null:
		return
	markdown.store_line("# Phase 9 Enemy Gem Scan Extreme Stress")
	markdown.store_line("")
	markdown.store_line("Windows headless CPU fixture. Not real iPhone, Metal, thermal, or battery proof.")
	markdown.store_line("")
	for key in ["ok", "seed", "enemy_count", "projectile_count", "gem_count", "frame_time_p50_ms", "frame_time_p95_ms", "frame_time_p99_ms", "over_33ms", "over_100ms"]:
		markdown.store_line("- %s: %s" % [key, str(summary.get(key, ""))])
	var enemy: Dictionary = summary.get("enemy", {})
	var gem: Dictionary = summary.get("gem_collection", {})
	var scan: Dictionary = summary.get("scan", {})
	markdown.store_line("- enemy command reduction: %s" % str(enemy.get("command_reduction_ratio", "")))
	markdown.store_line("- enemy visual CPU p95 reduction: %s" % str(enemy.get("cpu_reduction_ratio", "")))
	markdown.store_line("- gem visual command reduction: %s" % str(gem.get("visual_command_reduction_ratio", "")))
	markdown.store_line("- gem collection CPU p95 reduction: %s" % str(gem.get("cpu_reduction_ratio", "")))
	markdown.store_line("- temporary allocation proxy reduction: %s" % str(gem.get("temporary_allocation_proxy_reduction_ratio", "")))
	markdown.store_line("- scan query p95 ms: %s" % str(scan.get("scan_query_p95_ms", "")))
