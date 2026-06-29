extends RefCounted
class_name FieldDropSpawnSystem

func process(state, delta: float, events: Array) -> void:
	state.dynamic_drop_rate_timer = maxf(0.0, state.dynamic_drop_rate_timer - delta)
	state.rare_drop_bonus_timer = maxf(0.0, state.rare_drop_bonus_timer - delta)
	_process_respawns(state, delta, events)
	var config: Dictionary = state.field_drop_spawn_config
	if config.is_empty():
		return
	if not bool(config.get("time_spawn_enabled", false)):
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
	var spawn_rng = candidate.get("rng", state.rng)
	var pos = _spawn_position(state, def, spawn_rng)
	if pos == Vector2.INF:
		events.append({"type": "dynamic_drop_skip", "id": id, "reason": "no_safe_pickup_position"})
		return {}
	var distance = pos.distance_to(state.player_position)
	var drop = {
		"runtime_id": "dynamic_drop_%s_%d" % [id, state.dynamic_drops_spawned],
		"id": id,
		"name_ja": String(def.get("name_ja", id)),
		"position": pos,
		"unlock_seconds": state.elapsed_seconds,
		"radius": 24.0,
		"collected": false,
		"value": int(def.get("value", 1)),
		"priority": int(def.get("priority", 9)),
		"color": def.get("color", [1.0, 1.0, 1.0]),
		"generated_icon": String(def.get("generated_icon", "")),
		"dynamic": true,
		"persistent": true,
		"spawn_time": state.elapsed_seconds,
		"spawn_distance": distance,
		"spawn_in_danger": state.is_position_in_danger_zone(pos)
	}
	state.field_drops.append(drop)
	state.dynamic_drops_spawned += 1
	state.dynamic_drop_counts[id] = int(state.dynamic_drop_counts.get(id, 0)) + 1
	state.dynamic_drop_last_spawn[id] = state.elapsed_seconds
	state.field_drop_spawn_counts[id] = int(state.field_drop_spawn_counts.get(id, 0)) + 1
	var reason = String(candidate.get("reason", "interval_roll"))
	if reason == "respawn":
		state.field_drop_respawns_spawned += 1
	var biome = state.biome_system.biome_id_for_position(state, pos)
	var log_row = {
		"time": state.elapsed_seconds,
		"drop_id": id,
		"position": pos,
		"distance_from_player": distance,
		"biome": biome,
		"reason": reason,
		"despawn_time": 0.0
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
		"despawn_time": 0.0
	})
	return drop

func _process_respawns(state, delta: float, events: Array) -> void:
	if state.field_drop_respawn_queue.is_empty():
		return
	state.field_drop_respawn_check_timer = maxf(0.0, state.field_drop_respawn_check_timer - delta)
	if state.field_drop_respawn_check_timer > 0.0:
		return
	state.field_drop_respawn_check_timer = float(state.field_drop_spawn_config.get("respawn_check_interval", 0.25))
	var remaining: Array = []
	for entry in state.field_drop_respawn_queue:
		var id = String(entry.get("id", ""))
		var def: Dictionary = state.field_drop_defs.get(id, {})
		if id == "" or def.is_empty() or not bool(def.get("respawn_enabled", false)):
			continue
		if state.elapsed_seconds < float(entry.get("respawn_at", 0.0)):
			remaining.append(entry)
			continue
		if int(state.field_drop_spawn_counts.get(id, 0)) >= int(def.get("max_spawned_per_run", state.field_drop_spawn_counts.get(id, 0))):
			continue
		var max_active = int(def.get("max_active", 1))
		if _active_count(state, id) >= max_active:
			entry["respawn_at"] = state.elapsed_seconds + 1.0
			remaining.append(entry)
			continue
		var serial = int(entry.get("serial", state.field_drop_spawn_counts.get(id, 0)))
		var rng = state.rng.stream_rng("field_drop_respawn", "%s:%d:%d" % [id, serial, int(state.field_drop_spawn_counts.get(id, 0))])
		_spawn_drop(state, id, {"id": id, "def": def, "reason": "respawn", "rng": rng}, events)
	state.field_drop_respawn_queue = remaining

func _active_count(state, id: String) -> int:
	var count := 0
	for drop in state.field_drops:
		if String(drop.get("id", "")) == id and not bool(drop.get("collected", false)):
			count += 1
	return count

func _spawn_position(state, def: Dictionary, rng = null) -> Vector2:
	var local_rng = state.rng if rng == null else rng
	var min_distance = float(def.get("min_distance", 900.0))
	if bool(def.get("rare", false)):
		min_distance = maxf(min_distance, 1600.0)
	var max_distance = minf(state.field_size.x, state.field_size.y) * 0.44
	var walkable = state.tile_collision_system.random_walkable_position(state.map_data, local_rng, state.player_position, min_distance, max_distance)
	var resolved: Dictionary = state.resolve_pickup_position({
		"pickup_type": "field_drop",
		"position": walkable,
		"radius": 24.0,
		"origin": state.player_position,
		"min_distance": min_distance,
		"max_distance": max_distance,
		"rng": local_rng
	})
	if bool(resolved.get("ok", false)):
		return resolved.get("position", walkable)
	for attempt in range(32):
		var pos: Vector2
		var danger_chance = 0.58 if bool(def.get("rare", false)) else 0.34
		if not state.danger_zones.is_empty() and local_rng.chance(danger_chance):
			var zone: Dictionary = local_rng.choice(state.danger_zones)
			pos = (zone.get("position", state.player_position) as Vector2) + Vector2.RIGHT.rotated(local_rng.range_float(0.0, TAU)) * local_rng.range_float(60.0, float(zone.get("radius", 400.0)) * 0.65)
		else:
			pos = state.player_position + Vector2.RIGHT.rotated(local_rng.range_float(0.0, TAU)) * local_rng.range_float(min_distance, max_distance)
		pos.x = clampf(pos.x, 160.0, state.field_size.x - 160.0)
		pos.y = clampf(pos.y, 160.0, state.field_size.y - 160.0)
		resolved = state.resolve_pickup_position({
			"pickup_type": "field_drop",
			"position": pos,
			"radius": 24.0,
			"origin": state.player_position,
			"min_distance": min_distance,
			"max_distance": max_distance,
			"rng": local_rng
		})
		if bool(resolved.get("ok", false)):
			return resolved.get("position", pos)
	resolved = state.resolve_pickup_position({
		"pickup_type": "field_drop",
		"radius": 24.0,
		"origin": state.player_position,
		"min_distance": min_distance,
		"max_distance": max_distance,
		"rng": local_rng
	})
	return resolved.get("position", Vector2.INF) if bool(resolved.get("ok", false)) else Vector2.INF

func _expire_old_drops(state, events: Array) -> void:
	if not bool(state.field_drop_spawn_config.get("time_despawn_enabled", false)):
		return
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
