extends RefCounted
class_name GemCollectionBatchProcessor

const ExpSystemScript = preload("res://scripts/systems/ExpSystem.gd")
const GemCollectionVisualBatchSystemScript = preload("res://scripts/systems/GemCollectionVisualBatchSystem.gd")

var exp_system = ExpSystemScript.new()
var visual_batch_system = GemCollectionVisualBatchSystemScript.new()

func collect(state, target_gems: Array, events: Array, source: String, batch_size: int = 160, value_multiplier: float = 1.0) -> Dictionary:
	var started_msec = Time.get_ticks_msec()
	if target_gems.is_empty():
		var empty_metrics = _metrics(source, 0, 0, 0, 0, 0, 0, started_msec)
		_record_source(state, source, 0, 0, 0, empty_metrics)
		events.append({"type": "global_gem_collection", "source": source, "count": 0, "exp": 0, "batches": 0, "metrics": empty_metrics})
		return {"count": 0, "exp": 0, "batches": 0, "metrics": empty_metrics}
	var picked: Dictionary = {}
	var duplicate_targets := 0
	for gem in target_gems:
		if gem != null:
			var id = gem.get_instance_id()
			if picked.has(id):
				duplicate_targets += 1
			picked[id] = gem
	var retained: Array = []
	var batch_exp := 0
	var total_exp := 0
	var collected := 0
	var batch_count := 0
	var representative_positions: Array = []
	var max_proxy = int(state.gem_collection_effects.get("global_collection", {}).get("max_proxy_nodes", 48))
	for gem in state.gems:
		if gem == null:
			continue
		if not picked.has(gem.get_instance_id()):
			retained.append(gem)
			continue
		collected += 1
		if representative_positions.size() < max_proxy:
			representative_positions.append(gem.position)
		state.gems_collected += 1
		state.gem_turret_charge = mini(999, state.gem_turret_charge + 1)
		state.pickup_combo_count += 1
		state.max_combo = maxi(state.max_combo, state.pickup_combo_count)
		state.pickup_combo_timer = state.combo_timeout()
		var value = int(round(float(gem.value) * state.get_gem_value_multiplier(gem.position) * state.get_combo_exp_multiplier() * value_multiplier))
		value = maxi(1, value)
		batch_exp += value
		total_exp += value
		state.release_runtime("gem", gem)
		if collected % maxi(1, batch_size) == 0:
			exp_system.add_exp(state, batch_exp, events)
			batch_exp = 0
			batch_count += 1
	if batch_exp > 0:
		exp_system.add_exp(state, batch_exp, events)
		batch_count += 1
	state.gems = retained
	var pickup_score = int(round(float(total_exp) * 2.0 * state.get_combo_score_multiplier()))
	state.add_score(pickup_score, state.player_position)
	var missing = maxi(0, picked.keys().size() - collected)
	var visual_batch := _append_ring_effect(state, source, representative_positions, collected, total_exp)
	var metrics = _metrics(source, picked.keys().size(), collected, total_exp, total_exp, duplicate_targets, missing, started_msec, int(visual_batch.get("representative_count", 0)))
	_record_source(state, source, collected, total_exp, batch_count, metrics)
	events.append({
		"type": "global_gem_collection",
		"source": source,
		"count": collected,
		"exp": total_exp,
		"batches": batch_count,
		"score": pickup_score,
		"metrics": metrics
	})
	return {"count": collected, "exp": total_exp, "batches": batch_count, "score": pickup_score, "metrics": metrics}

func _record_source(state, source: String, collected: int, exp: int, batches: int, metrics: Dictionary) -> void:
	state.global_gem_collections += 1 if collected > 0 else 0
	state.global_gem_collection_batches += batches
	state.global_gem_collection_exp += exp
	state.global_gem_collection_last_count = collected
	state.global_gem_collection_last_metrics = metrics
	state.global_gem_collection_metrics.append(metrics)
	while state.global_gem_collection_metrics.size() > 20:
		state.global_gem_collection_metrics.pop_front()
	match source:
		"magnet":
			state.gems_collected_by_magnet += collected
		"drone":
			state.gems_collected_by_drone += collected
		"resonance_magnet_core":
			state.gems_collected_by_passive += collected

func _metrics(source: String, expected_count: int, collected: int, expected_exp: int, actual_exp: int, duplicate_targets: int, missing: int, started_msec: int, proxy_nodes: int = 0) -> Dictionary:
	var duration_ms = maxi(0, Time.get_ticks_msec() - started_msec)
	return {
		"source": source,
		"collected": collected,
		"expected_count": expected_count,
		"expected_exp": expected_exp,
		"actual_exp": actual_exp,
		"duplicate_targets": duplicate_targets,
		"missing": missing,
		"proxy_nodes": mini(collected, proxy_nodes),
		"visual_batch_count": 1 if proxy_nodes > 0 else 0,
		"representative_gem_count": proxy_nodes,
		"duration_ms": duration_ms,
		"long_frames": 0
	}

func _append_ring_effect(state, source: String, positions: Array, collected: int, exp: int) -> Dictionary:
	if collected <= 0:
		return {}
	var config: Dictionary = state.gem_collection_effects.get("global_collection", {})
	var proxy_limit = int(config.get("max_proxy_nodes", 48))
	var visual_batch := visual_batch_system.make_batch(source, positions, collected, exp, state.player_position, proxy_limit)
	var proxies = int(visual_batch.get("representative_count", 0))
	var ring_count = clampi(int(config.get("gem_collection_ring_count", config.get("ring_count", 1))), 1, 1)
	state.gem_ring_effects.append({
		"source": source,
		"count": collected,
		"exp": exp,
		"positions": visual_batch.get("representative_positions", []),
		"proxy_nodes": proxies,
		"ring_count": ring_count,
		"start_time": state.elapsed_seconds,
		"duration": float(config.get("ring_duration", visual_batch.get("visual_duration", 0.26))),
		"collapse_start": float(config.get("collapse_start", 0.12)),
		"center": state.player_position,
		"visual_batch": visual_batch
	})
	while state.gem_ring_effects.size() > int(config.get("max_active_ring_effects", 4)):
		state.gem_ring_effects.pop_front()
	return visual_batch
