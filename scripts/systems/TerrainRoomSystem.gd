extends RefCounted
class_name TerrainRoomSystem

func room_at_position(map_data: Dictionary, position: Vector2) -> Dictionary:
	var tile_size = float(map_data.get("tile_size", 64.0))
	var cell_key = "%d,%d" % [floori(position.x / tile_size), floori(position.y / tile_size)]
	for room in map_data.get("rooms", []):
		if (room.get("floor_cells", []) as Array).has(cell_key):
			return room
	for corridor in map_data.get("corridors", []):
		if (corridor.get("cells", []) as Array).has(cell_key):
			return {
				"id": "corridor",
				"terrain_id": "crystal_corridor",
				"name_ja": "結晶回廊",
				"position": position,
				"size": Vector2(tile_size, tile_size)
			}
	for room in map_data.get("rooms", []):
		var center: Vector2 = room.get("position", Vector2.ZERO)
		var size: Vector2 = room.get("size", Vector2.ZERO)
		if Rect2(center - size * 0.5, size).has_point(position):
			return room
	for corridor in map_data.get("corridors", []):
		for rect_data in corridor.get("rects", []):
			var center: Vector2 = rect_data.get("position", Vector2.ZERO)
			var size: Vector2 = rect_data.get("size", Vector2.ZERO)
			if Rect2(center - size * 0.5, size).has_point(position):
				return {
					"id": "corridor",
					"terrain_id": "crystal_corridor",
					"name_ja": "結晶回廊",
					"position": center,
					"size": size
				}
	return {}

func update_state(state, events: Array) -> void:
	var room = room_at_position(state.map_data, state.player_position)
	var terrain_id = String(room.get("terrain_id", "crystal_corridor"))
	var definition: Dictionary = state.terrain_type_defs.get(terrain_id, {})
	state.current_terrain_id = terrain_id
	state.current_terrain_name = String(definition.get("name_ja", room.get("name_ja", "結晶回廊")))
	var room_id = String(room.get("id", ""))
	if room_id != "" and room_id != "corridor" and not state.explored_room_ids.has(room_id):
		state.explored_room_ids.append(room_id)
		state.rooms_discovered += 1
		events.append({"type": "room_discovered", "room": room_id, "terrain": terrain_id, "name": state.current_terrain_name})

func terrain_value(state, key: String, fallback: float = 1.0) -> float:
	return float(state.terrain_type_defs.get(state.current_terrain_id, {}).get(key, fallback))

func guide_for_current(state) -> String:
	var data: Dictionary = state.terrain_type_defs.get(state.current_terrain_id, {})
	return "%s　危険度%d/5\n%s" % [
		String(data.get("name_ja", state.current_terrain_name)),
		int(data.get("danger", 1)),
		String(data.get("description_ja", "周囲を確認して進む。"))
	]
