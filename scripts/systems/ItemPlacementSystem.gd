extends RefCounted
class_name ItemPlacementSystem

const WorldPlacementValidatorScript = preload("res://scripts/systems/WorldPlacementValidator.gd")
const ItemPlacementTelemetryScript = preload("res://scripts/systems/ItemPlacementTelemetry.gd")
const TileCollisionSystemScript = preload("res://scripts/systems/TileCollisionSystem.gd")

var validator = WorldPlacementValidatorScript.new()
var tile_collision = TileCollisionSystemScript.new()
var telemetry = ItemPlacementTelemetryScript.new()

func resolve_valid_pickup_position(state, map_data: Dictionary, request: Dictionary) -> Dictionary:
	var pickup_type := String(request.get("pickup_type", "field_drop"))
	var rules := _rules_for(state, pickup_type, request)
	var origin: Vector2 = request.get("origin", state.player_position)
	validator.build_cache(map_data, origin)
	var candidate: Vector2 = request.get("position", Vector2.INF)
	var min_distance := float(request.get("min_distance", -1.0))
	var max_distance := float(request.get("max_distance", INF))
	var required_room := String(request.get("room_id", ""))
	var result := {
		"ok": false,
		"pickup_type": pickup_type,
		"position": Vector2.INF,
		"candidate_valid": false,
		"repaired": false,
		"rerolls": 0,
		"reason": ""
	}
	if candidate != Vector2.INF and _candidate_allowed(map_data, candidate, pickup_type, rules, origin, min_distance, max_distance, required_room):
		result["ok"] = true
		result["position"] = candidate
		result["candidate_valid"] = true
		result["reason"] = "candidate"
		_record(state, result)
		return result
	var rng = request.get("rng", state.rng)
	var pool := _filtered_pool(map_data, pickup_type, rules, origin, min_distance, max_distance, required_room)
	if pool.is_empty() and required_room != "":
		pool = _filtered_pool(map_data, pickup_type, rules, origin, min_distance, max_distance, "")
	if pool.is_empty():
		result["reason"] = "no_safe_cell"
		_record(state, result)
		return result
	var attempts := mini(int(rules.get("reroll_attempts", 32)), pool.size())
	for i in range(attempts):
		var key := String(pool[rng.next_int(pool.size())])
		var pos := tile_collision.cell_to_world(map_data, _decode_cell(key))
		result["rerolls"] = i + 1
		if _candidate_allowed(map_data, pos, pickup_type, rules, origin, min_distance, max_distance, required_room):
			result["ok"] = true
			result["position"] = pos
			result["repaired"] = true
			result["reason"] = "reroll_safe_cell"
			_record(state, result)
			return result
	var deterministic := _deterministic_fallback(map_data, pool, origin)
	if deterministic != Vector2.INF and _candidate_allowed(map_data, deterministic, pickup_type, rules, origin, min_distance, max_distance, required_room):
		result["ok"] = true
		result["position"] = deterministic
		result["repaired"] = true
		result["reason"] = "deterministic_safe_cell"
	else:
		result["reason"] = "fallback_failed"
	_record(state, result)
	return result

func validate_active_pickups(state) -> Dictionary:
	var summary := {
		"checked": 0,
		"repaired": 0,
		"skipped": 0,
		"invalid_after_repair": 0,
		"by_type": {}
	}
	_validate_array(state, state.gems, "exp_gem", "position", summary)
	_validate_array(state, state.chests, "chest", "position", summary)
	_validate_dictionary_array(state, state.field_drops, "field_drop", summary)
	_validate_dictionary_array(state, state.field_equipment, "field_equipment", summary)
	_validate_dictionary_array(state, state.field_gimmicks, "field_gimmick", summary)
	return summary

func is_valid_pickup_position(state, position: Vector2, pickup_type: String, radius: float = -1.0) -> bool:
	var rules := _rules_for(state, pickup_type, {"radius": radius} if radius > 0.0 else {})
	validator.build_cache(state.map_data, state.player_position)
	return validator.is_valid_pickup_position(state.map_data, position, pickup_type, rules)

func validation_result(state, position: Vector2, pickup_type: String, radius: float = -1.0) -> Dictionary:
	var rules := _rules_for(state, pickup_type, {"radius": radius} if radius > 0.0 else {})
	validator.build_cache(state.map_data, state.player_position)
	return validator.validation_result(state.map_data, position, pickup_type, rules)

func _validate_dictionary_array(state, items: Array, pickup_type: String, summary: Dictionary) -> void:
	for item in items:
		if not item is Dictionary or bool(item.get("collected", false)) or bool(item.get("destroyed", false)):
			continue
		summary["checked"] = int(summary.get("checked", 0)) + 1
		var pos: Vector2 = item.get("position", Vector2.INF)
		var result := resolve_valid_pickup_position(state, state.map_data, {
			"pickup_type": pickup_type,
			"position": pos,
			"radius": float(item.get("radius", -1.0)),
			"origin": state.player_position,
			"rng": state.rng.stream_rng("item_repair", "%s:%s:%d" % [pickup_type, String(item.get("id", "")), summary["checked"]])
		})
		if bool(result.get("ok", false)):
			if bool(result.get("repaired", false)):
				item["position"] = result.get("position", pos)
				summary["repaired"] = int(summary.get("repaired", 0)) + 1
		else:
			item["collected"] = true
			item["placement_invalid"] = true
			summary["skipped"] = int(summary.get("skipped", 0)) + 1
			continue
		if not is_valid_pickup_position(state, item.get("position", Vector2.INF), pickup_type, float(item.get("radius", -1.0))):
			summary["invalid_after_repair"] = int(summary.get("invalid_after_repair", 0)) + 1

func _validate_array(state, items: Array, pickup_type: String, property: String, summary: Dictionary) -> void:
	for item in items:
		if item == null:
			continue
		summary["checked"] = int(summary.get("checked", 0)) + 1
		var pos: Vector2 = item.get(property) if item.has_method("get") else item.position
		var result := resolve_valid_pickup_position(state, state.map_data, {
			"pickup_type": pickup_type,
			"position": pos,
			"origin": state.player_position,
			"rng": state.rng.stream_rng("item_repair", "%s:%d" % [pickup_type, summary["checked"]])
		})
		if bool(result.get("ok", false)):
			if bool(result.get("repaired", false)):
				item.position = result.get("position", pos)
				summary["repaired"] = int(summary.get("repaired", 0)) + 1
		else:
			summary["skipped"] = int(summary.get("skipped", 0)) + 1

func _filtered_pool(map_data: Dictionary, pickup_type: String, rules: Dictionary, origin: Vector2, min_distance: float, max_distance: float, required_room: String) -> Array:
	var result: Array = []
	for key in validator.safe_cells(map_data, pickup_type, rules):
		var pos := tile_collision.cell_to_world(map_data, _decode_cell(String(key)))
		if _distance_allowed(pos, origin, min_distance, max_distance) and (required_room == "" or validator.get_room_id(map_data, pos) == required_room):
			result.append(String(key))
	return result

func _candidate_allowed(map_data: Dictionary, position: Vector2, pickup_type: String, rules: Dictionary, origin: Vector2, min_distance: float, max_distance: float, required_room: String) -> bool:
	if not _distance_allowed(position, origin, min_distance, max_distance):
		return false
	if required_room != "" and validator.get_room_id(map_data, position) != required_room:
		return false
	return validator.is_valid_pickup_position(map_data, position, pickup_type, rules)

func _distance_allowed(position: Vector2, origin: Vector2, min_distance: float, max_distance: float) -> bool:
	var distance := position.distance_to(origin)
	if min_distance >= 0.0 and distance < min_distance:
		return false
	if max_distance < INF and distance > max_distance:
		return false
	return true

func _deterministic_fallback(map_data: Dictionary, pool: Array, origin: Vector2) -> Vector2:
	if pool.is_empty():
		return Vector2.INF
	var best_key := String(pool[0])
	var best_distance := -1.0
	for key in pool:
		var pos := tile_collision.cell_to_world(map_data, _decode_cell(String(key)))
		var distance := pos.distance_to(origin)
		if distance > best_distance:
			best_key = String(key)
			best_distance = distance
	return tile_collision.cell_to_world(map_data, _decode_cell(best_key))

func _rules_for(state, pickup_type: String, overrides: Dictionary = {}) -> Dictionary:
	var all_rules: Dictionary = state.item_placement_rules if state.item_placement_rules is Dictionary else {}
	var rules: Dictionary = all_rules.get("default", {}).duplicate(true)
	if all_rules.has(pickup_type):
		rules.merge(all_rules[pickup_type], true)
	if overrides.has("radius") and float(overrides.get("radius", -1.0)) > 0.0:
		rules["radius"] = float(overrides["radius"])
	if overrides.has("margin") and float(overrides.get("margin", -1.0)) >= 0.0:
		rules["margin"] = float(overrides["margin"])
	if overrides.has("edge_margin") and float(overrides.get("edge_margin", -1.0)) >= 0.0:
		rules["edge_margin"] = float(overrides["edge_margin"])
	return rules

func _record(state, result: Dictionary) -> void:
	telemetry.record(result)
	if state.item_placement_telemetry != null:
		state.item_placement_telemetry.record(result)

func _decode_cell(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))
