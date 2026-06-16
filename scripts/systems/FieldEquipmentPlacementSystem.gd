extends RefCounted
class_name FieldEquipmentPlacementSystem

func generate(state, map_data: Dictionary, rng) -> Array:
	var defs: Dictionary = state.field_equipment_defs
	var config: Dictionary = defs.get("config", {})
	var max_total := int(config.get("max_per_run", 8))
	var max_weapons := int(config.get("max_weapons_per_run", 4))
	var max_passives := int(config.get("max_passives_per_run", 4))
	var start_block := float(config.get("start_room_block_radius", 850.0))
	var center: Vector2 = state.field_size * 0.5
	var anchors := _reward_anchors(map_data, defs, center, start_block)
	if anchors.is_empty():
		anchors = _fallback_anchors(map_data, center, start_block)
	var results: Array = []
	var weapon_count := 0
	var passive_count := 0
	var used_items: Array = []
	while results.size() < max_total and not anchors.is_empty():
		var kind := "weapon"
		if weapon_count >= max_weapons:
			kind = "passive"
		elif passive_count >= max_passives:
			kind = "weapon"
		elif rng.chance(0.48):
			kind = "passive"
		var pool_key := "weapon_pool" if kind == "weapon" else "passive_pool"
		var entry := _choose_pool_entry(state, defs.get(pool_key, []), kind, used_items, rng)
		if entry.is_empty():
			break
		var anchor: Dictionary = rng.weighted_choice(anchors)
		var room: Dictionary = anchor.get("room", {})
		var item_id := String(entry.get("id", ""))
		var pos = _position_in_room(room, state, rng)
		var id := "field_%s_%s_%d" % [kind, item_id, results.size()]
		results.append({
			"runtime_id": id,
			"id": item_id,
			"kind": kind,
			"name_ja": "%s：%s" % ["武器" if kind == "weapon" else "パッシブ", state.weapon_name(item_id) if kind == "weapon" else state.passive_name(item_id)],
			"position": pos,
			"room_id": String(room.get("id", "")),
			"terrain_id": String(room.get("terrain_id", "")),
			"quality": String(anchor.get("quality", "common")),
			"reason_ja": String(anchor.get("reason_ja", "探索報酬")),
			"icon": String(entry.get("icon", "W" if kind == "weapon" else "P")),
			"priority": 2 if String(anchor.get("quality", "")) in ["rare", "event"] else 5,
			"radius": float(config.get("pickup_radius", 34.0)),
			"allow_over_cap": true,
			"collected": false,
			"color": entry.get("color", [0.72, 0.92, 1.0])
		})
		used_items.append("%s:%s" % [kind, item_id])
		if kind == "weapon":
			weapon_count += 1
		else:
			passive_count += 1
		anchors.erase(anchor)
	return results

func _reward_anchors(map_data: Dictionary, defs: Dictionary, center: Vector2, start_block: float) -> Array:
	var result: Array = []
	var reward_rooms: Dictionary = defs.get("reward_rooms", {})
	for room in map_data.get("rooms", []):
		var terrain_id := String(room.get("terrain_id", ""))
		if not reward_rooms.has(terrain_id):
			continue
		var pos: Vector2 = room.get("position", center)
		if pos.distance_to(center) < start_block:
			continue
		var data: Dictionary = reward_rooms[terrain_id]
		result.append({"room": room, "weight": float(data.get("weight", 1.0)), "quality": data.get("quality", "common"), "reason_ja": data.get("reason_ja", "探索報酬")})
	return result

func _fallback_anchors(map_data: Dictionary, center: Vector2, start_block: float) -> Array:
	var result: Array = []
	for room in map_data.get("rooms", []):
		var pos: Vector2 = room.get("position", center)
		if pos.distance_to(center) >= start_block:
			result.append({"room": room, "weight": 1.0, "quality": "common", "reason_ja": "遠方探索報酬"})
	return result

func _choose_pool_entry(state, pool, kind: String, used_items: Array, rng) -> Dictionary:
	var weighted: Array = []
	for entry in pool:
		if not entry is Dictionary:
			continue
		var id := String(entry.get("id", ""))
		if id == "" or used_items.has("%s:%s" % [kind, id]):
			continue
		if not is_id_run_available(state, kind, id):
			continue
		var candidate: Dictionary = entry.duplicate(true)
		candidate["weight"] = float(entry.get("weight", 1.0))
		weighted.append(candidate)
	return rng.weighted_choice(weighted) if not weighted.is_empty() else {}

func is_id_run_available(state, kind: String, id: String) -> bool:
	if id == "":
		return false
	if state.run_sealed_option_uids.has("%s:%s" % [kind, id]):
		return false
	if kind == "weapon":
		return state.weapon_defs.has(id) and state.unlocked_weapon_ids.has(id) and not state.disabled_weapon_ids.has(id)
	return state.passive_defs.has(id) and state.unlocked_passive_ids.has(id) and not state.disabled_passive_ids.has(id)

func replacement_for(state, kind: String, used_items: Array, rng) -> Dictionary:
	var pool_key := "weapon_pool" if kind == "weapon" else "passive_pool"
	return _choose_pool_entry(state, state.field_equipment_defs.get(pool_key, []), kind, used_items, rng)

func _position_in_room(room: Dictionary, state, rng) -> Vector2:
	var base: Vector2 = room.get("position", state.field_size * 0.5)
	var size: Vector2 = room.get("size", Vector2(420, 320))
	var offset = Vector2(rng.range_float(-size.x * 0.28, size.x * 0.28), rng.range_float(-size.y * 0.28, size.y * 0.28))
	return state.resolve_walkable_position(base + offset, 18.0, base)
