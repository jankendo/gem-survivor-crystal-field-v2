extends RefCounted
class_name FieldDropSpawnSystem

func process(state, delta: float, events: Array) -> void:
	state.dynamic_drop_rate_timer = maxf(0.0, state.dynamic_drop_rate_timer - delta)
	state.rare_drop_bonus_timer = maxf(0.0, state.rare_drop_bonus_timer - delta)
	_expire_old_drops(state, events)
	var config: Dictionary = state.field_drop_spawn_config
	if config.is_empty():
		return
	if state.next_dynamic_drop_time <= 0.0:
		state.next_dynamic_drop_time = float(config.get("initial_delay", 45.0))
	if state.elapsed_seconds < state.next_dynamic_drop_time:
		return
	state.next_dynamic_drop_time += float(config.get("roll_interval", 30.0))
	if state.dynamic_drops_spawned >= int(config.get("max_dynamic_per_run", 12)):
		return
	var chance = float(config.get("base_spawn_chance", 0.58))
	if state.dynamic_drop_rate_timer > 0.0:
		chance *= state.dynamic_drop_rate_multiplier
	if not state.rng.chance(minf(chance, 0.95)):
		events.append({"type": "dynamic_drop_roll", "success": false, "time": state.elapsed_seconds})
		return
	var candidate = _choose_drop(state)
	if candidate.is_empty():
		return
	_spawn_drop(state, String(candidate.get("id", "")), candidate, events)

func force_spawn(state, id: String, events: Array, reason: String = "test") -> Dictionary:
	var def: Dictionary = state.field_drop_defs.get(id, {})
	if def.is_empty():
		return {}
	return _spawn_drop(state, id, {"id": id, "def": def, "reason": reason}, events)

func _choose_drop(state) -> Dictionary:
	var weighted: Array = []
	for raw_id in state.field_drop_defs.keys():
		var id = String(raw_id)
		var def: Dictionary = state.field_drop_defs[id]
		if state.elapsed_seconds < float(def.get("unlock_seconds", 0.0)):
			continue
		if int(state.dynamic_drop_counts.get(id, 0)) >= int(def.get("dynamic_max_per_run", 0)):
			continue
		if state.elapsed_seconds - float(state.dynamic_drop_last_spawn.get(id, -9999.0)) < float(def.get("dynamic_cooldown", 60.0)):
			continue
		var weight = float(def.get("dynamic_weight", 0.0))
		if bool(def.get("rare", false)) and state.rare_drop_bonus_timer > 0.0:
			weight *= state.rare_drop_multiplier
		if weight > 0.0:
			weighted.append({"id": id, "def": def, "weight": weight, "reason": "interval_roll"})
	return state.rng.weighted_choice(weighted)

func _spawn_drop(state, id: String, candidate: Dictionary, events: Array) -> Dictionary:
	var def: Dictionary = candidate.get("def", state.field_drop_defs.get(id, {}))
	var pos = _spawn_position(state, def)
	var despawn_seconds = float(state.field_drop_spawn_config.get("despawn_seconds", 180.0))
	var distance = pos.distance_to(state.player_position)
	var drop = {
		"id": id,
		"name_ja": String(def.get("name_ja", id)),
		"position": pos,
		"unlock_seconds": state.elapsed_seconds,
		"radius": 24.0,
		"collected": false,
		"value": int(def.get("value", 1)),
		"priority": int(def.get("priority", 9)),
		"color": def.get("color", [1.0, 1.0, 1.0]),
		"dynamic": true,
		"spawn_time": state.elapsed_seconds,
		"despawn_time": state.elapsed_seconds + despawn_seconds,
		"spawn_distance": distance,
		"spawn_in_danger": state.is_position_in_danger_zone(pos)
	}
	state.field_drops.append(drop)
	state.dynamic_drops_spawned += 1
	state.dynamic_drop_counts[id] = int(state.dynamic_drop_counts.get(id, 0)) + 1
	state.dynamic_drop_last_spawn[id] = state.elapsed_seconds
	var biome = state.biome_system.biome_id_for_position(state, pos)
	var reason = String(candidate.get("reason", "interval_roll"))
	var log_row = {
		"time": state.elapsed_seconds,
		"drop_id": id,
		"position": pos,
		"distance_from_player": distance,
		"biome": biome,
		"reason": reason,
		"despawn_time": drop["despawn_time"]
	}
	state.dynamic_drop_log.append(log_row)
	_append_log_if_enabled(state, log_row)
	events.append({
		"type": "dynamic_drop_spawn",
		"id": id,
		"name": drop["name_ja"],
		"pos": pos,
		"distance": distance,
		"biome": biome,
		"reason": reason,
		"despawn_time": drop["despawn_time"]
	})
	return drop

func _spawn_position(state, def: Dictionary) -> Vector2:
	var min_distance = float(def.get("min_distance", 900.0))
	if bool(def.get("rare", false)):
		min_distance = maxf(min_distance, 1600.0)
	var max_distance = minf(state.field_size.x, state.field_size.y) * 0.44
	var walkable = state.random_walkable_position(state.player_position, min_distance, max_distance)
	if state.is_walkable_position(walkable, 22.0):
		return walkable
	for attempt in range(32):
		var pos: Vector2
		var danger_chance = 0.58 if bool(def.get("rare", false)) else 0.34
		if not state.danger_zones.is_empty() and state.rng.chance(danger_chance):
			var zone: Dictionary = state.rng.choice(state.danger_zones)
			pos = (zone.get("position", state.player_position) as Vector2) + Vector2.RIGHT.rotated(state.rng.range_float(0.0, TAU)) * state.rng.range_float(60.0, float(zone.get("radius", 400.0)) * 0.65)
		else:
			pos = state.player_position + Vector2.RIGHT.rotated(state.rng.range_float(0.0, TAU)) * state.rng.range_float(min_distance, max_distance)
		pos.x = clampf(pos.x, 160.0, state.field_size.x - 160.0)
		pos.y = clampf(pos.y, 160.0, state.field_size.y - 160.0)
		if pos.distance_to(state.player_position) >= min_distance and pos.distance_to(state.field_size * 0.5) >= min_distance * 0.72:
			return state.resolve_walkable_position(pos, 22.0, state.player_position)
	return state.resolve_walkable_position(Vector2(
		clampf(state.player_position.x + min_distance, 160.0, state.field_size.x - 160.0),
		state.player_position.y
	), 22.0, state.player_position)

func _expire_old_drops(state, events: Array) -> void:
	for drop in state.field_drops:
		if not bool(drop.get("dynamic", false)) or bool(drop.get("collected", false)):
			continue
		if state.elapsed_seconds >= float(drop.get("despawn_time", INF)):
			drop["collected"] = true
			drop["expired"] = true
			events.append({"type": "dynamic_drop_expired", "id": drop.get("id", ""), "name": drop.get("name_ja", ""), "pos": drop.get("position", Vector2.ZERO)})

func _append_log_if_enabled(state, row: Dictionary) -> void:
	if not bool(state.field_drop_spawn_config.get("spawn_log_enabled", false)):
		return
	var path = String(state.field_drop_spawn_config.get("spawn_log_path", "user://dynamic_field_drops.csv"))
	var exists = FileAccess.file_exists(path)
	var file = FileAccess.open(path, FileAccess.READ_WRITE)
	if file == null:
		return
	file.seek_end()
	if not exists or file.get_length() == 0:
		file.store_line("time,drop_id,position,distance_from_player,biome,reason,despawn_time")
	file.store_line("%.2f,%s,\"%s\",%.2f,%s,%s,%.2f" % [
		float(row.get("time", 0.0)),
		String(row.get("drop_id", "")),
		str(row.get("position", Vector2.ZERO)),
		float(row.get("distance_from_player", 0.0)),
		String(row.get("biome", "")),
		String(row.get("reason", "")),
		float(row.get("despawn_time", 0.0))
	])
