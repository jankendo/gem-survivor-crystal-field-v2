extends RefCounted
class_name GemCollectionBatchProcessor

const ExpSystemScript = preload("res://scripts/systems/ExpSystem.gd")

var exp_system = ExpSystemScript.new()

func collect(state, target_gems: Array, events: Array, source: String, batch_size: int = 160, value_multiplier: float = 1.0) -> Dictionary:
	if target_gems.is_empty():
		events.append({"type": "global_gem_collection", "source": source, "count": 0, "exp": 0, "batches": 0})
		return {"count": 0, "exp": 0, "batches": 0}
	var picked: Dictionary = {}
	for gem in target_gems:
		if gem != null:
			picked[gem.get_instance_id()] = gem
	var retained: Array = []
	var batch_exp := 0
	var total_exp := 0
	var collected := 0
	var batch_count := 0
	for gem in state.gems:
		if gem == null:
			continue
		if not picked.has(gem.get_instance_id()):
			retained.append(gem)
			continue
		collected += 1
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
	_record_source(state, source, collected, total_exp, batch_count)
	events.append({
		"type": "global_gem_collection",
		"source": source,
		"count": collected,
		"exp": total_exp,
		"batches": batch_count,
		"score": pickup_score
	})
	return {"count": collected, "exp": total_exp, "batches": batch_count, "score": pickup_score}

func _record_source(state, source: String, collected: int, exp: int, batches: int) -> void:
	state.global_gem_collections += 1 if collected > 0 else 0
	state.global_gem_collection_batches += batches
	state.global_gem_collection_exp += exp
	state.global_gem_collection_last_count = collected
	match source:
		"magnet":
			state.gems_collected_by_magnet += collected
		"drone":
			state.gems_collected_by_drone += collected
		"resonance_magnet_core":
			state.gems_collected_by_passive += collected
