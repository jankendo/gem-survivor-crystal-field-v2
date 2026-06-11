extends RefCounted
class_name ProceduralMapSystem

var connectivity = preload("res://scripts/systems/MapConnectivitySystem.gd").new()
var true_dungeon = preload("res://scripts/systems/TrueDungeonMapGenerator.gd").new()

func generate_layout(state, rng, config: Dictionary, room_config: Dictionary) -> Dictionary:
	return true_dungeon.generate(state, rng, config, room_config)

func generate_legacy_layout(state, rng, config: Dictionary, room_config: Dictionary) -> Dictionary:
	var center = state.field_size * 0.5
	var branch_count = int(config.get("branch_count", 4))
	var rooms_per_branch = int(config.get("rooms_per_branch", 3))
	var terrain_sequence: Array = room_config.get("required_sequence", []).duplicate()
	var rotation = rng.range_int(0, maxi(0, terrain_sequence.size() - 1)) if not terrain_sequence.is_empty() else 0
	var rooms: Array = [{
		"id": "room_00",
		"terrain_id": "safe_room",
		"name_ja": "安全拠点",
		"position": center,
		"size": Vector2(1080.0, 860.0),
		"branch": -1,
		"depth": 0,
		"important": true
	}]
	var connections: Array = []
	var room_index = 1
	var angle_offset = rng.range_float(-0.12, 0.12)
	for branch in range(branch_count):
		var previous_id = "room_00"
		var base_angle = angle_offset + TAU * float(branch) / float(branch_count)
		for depth in range(1, rooms_per_branch + 1):
			var distance = float(config.get("first_room_distance", 1120.0)) + float(depth - 1) * float(config.get("room_distance_step", 920.0))
			var angle = base_angle + rng.range_float(-0.10, 0.10)
			var position = center + Vector2(cos(angle), sin(angle)) * distance
			position.x = clampf(position.x, 520.0, state.field_size.x - 520.0)
			position.y = clampf(position.y, 520.0, state.field_size.y - 520.0)
			var terrain_id = String(terrain_sequence[(room_index - 1 + rotation) % terrain_sequence.size()]) if not terrain_sequence.is_empty() else "crystal_corridor"
			var room_id = "room_%02d" % room_index
			var room_size = Vector2(
				rng.range_float(float(config.get("room_width_min", 680.0)), float(config.get("room_width_max", 920.0))),
				rng.range_float(float(config.get("room_height_min", 560.0)), float(config.get("room_height_max", 780.0)))
			)
			if terrain_id == "boss_arena":
				room_size = Vector2(1060.0, 860.0)
			rooms.append({
				"id": room_id,
				"terrain_id": terrain_id,
				"position": position,
				"size": room_size,
				"branch": branch,
				"depth": depth,
				"important": room_config.get("important_types", []).has(terrain_id),
				"dead_end": depth == rooms_per_branch
			})
			connections.append({"from": previous_id, "to": room_id, "kind": "corridor"})
			previous_id = room_id
			room_index += 1
	var corridors = _build_corridors(rooms, connections, float(config.get("corridor_width", 250.0)))
	var wall_specs = _build_room_walls(rooms, config, rng)
	wall_specs.push_front({
		"id": "start_test_crystal",
		"position": center + Vector2(720.0, 720.0),
		"size": Vector2(124.0, 86.0),
		"hp": 60,
		"type": "wall_crystal",
		"breakable": true,
		"kind": "room_crystal",
		"biome": "void_zone"
	})
	var shortcuts = _build_shortcuts(rooms, config, rng)
	wall_specs.append_array(shortcuts)
	var important_room_ids: Array = []
	for room in rooms:
		if bool(room.get("important", false)):
			important_room_ids.append(String(room.get("id", "")))
	var result = {
		"rooms": rooms,
		"connections": connections,
		"corridors": corridors,
		"wall_specs": wall_specs,
		"shortcut_walls": shortcuts,
		"important_room_ids": important_room_ids,
		"open_corridors": connectivity.exit_count({"rooms": rooms, "connections": connections}, "room_00")
	}
	result["connected"] = connectivity.all_rooms_reachable(result)
	result["important_reachable"] = connectivity.important_rooms_reachable(result)
	return result

func _build_corridors(rooms: Array, connections: Array, width: float) -> Array:
	var lookup := {}
	for room in rooms:
		lookup[String(room.get("id", ""))] = room
	var corridors: Array = []
	for edge in connections:
		var from_room: Dictionary = lookup.get(String(edge.get("from", "")), {})
		var to_room: Dictionary = lookup.get(String(edge.get("to", "")), {})
		var a: Vector2 = from_room.get("position", Vector2.ZERO)
		var b: Vector2 = to_room.get("position", Vector2.ZERO)
		var bend = Vector2(b.x, a.y)
		var rects: Array = []
		if absf(bend.x - a.x) > 2.0:
			rects.append({"position": Vector2((a.x + bend.x) * 0.5, a.y), "size": Vector2(absf(bend.x - a.x) + width, width)})
		if absf(b.y - bend.y) > 2.0:
			rects.append({"position": Vector2(b.x, (bend.y + b.y) * 0.5), "size": Vector2(width, absf(b.y - bend.y) + width)})
		corridors.append({"from": edge.get("from", ""), "to": edge.get("to", ""), "rects": rects})
	return corridors

func _build_room_walls(rooms: Array, config: Dictionary, rng) -> Array:
	var specs: Array = []
	var gap = float(config.get("door_gap", 210.0))
	var hp = int(config.get("structural_wall_hp", 999999))
	for room in rooms:
		if String(room.get("terrain_id", "")) == "safe_room":
			continue
		var center: Vector2 = room.get("position", Vector2.ZERO)
		var size: Vector2 = room.get("size", Vector2(760, 620))
		var horizontal = maxf(90.0, (size.x - gap) * 0.5)
		var vertical = maxf(90.0, (size.y - gap) * 0.5)
		var id = String(room.get("id", "room"))
		for side in [-1.0, 1.0]:
			for half in [-1.0, 1.0]:
				specs.append({
					"id": "%s_h_%s_%s" % [id, str(side), str(half)],
					"position": center + Vector2(half * (gap * 0.5 + horizontal * 0.5), side * size.y * 0.5),
					"size": Vector2(horizontal, 34.0),
					"hp": hp,
					"type": "ancient_wall",
					"breakable": false,
					"kind": "structural",
					"biome": _biome_for_position(center, rooms[0].get("position", Vector2.ZERO))
				})
				specs.append({
					"id": "%s_v_%s_%s" % [id, str(side), str(half)],
					"position": center + Vector2(side * size.x * 0.5, half * (gap * 0.5 + vertical * 0.5)),
					"size": Vector2(34.0, vertical),
					"hp": hp,
					"type": "ancient_wall",
					"breakable": false,
					"kind": "structural",
					"biome": _biome_for_position(center, rooms[0].get("position", Vector2.ZERO))
				})
		var crystal_count = rng.range_int(1, 3)
		for crystal_index in range(crystal_count):
			var crystal_pos = center + Vector2(rng.range_float(-size.x * 0.30, size.x * 0.30), rng.range_float(-size.y * 0.28, size.y * 0.28))
			specs.append({
				"id": "%s_crystal_%d" % [id, crystal_index],
				"position": crystal_pos,
				"size": Vector2(rng.range_float(80.0, 150.0), rng.range_float(62.0, 110.0)),
				"hp": rng.range_int(55, 130),
				"type": _crystal_type(String(room.get("terrain_id", "")), rng),
				"breakable": true,
				"kind": "room_crystal",
				"biome": _biome_for_position(center, rooms[0].get("position", Vector2.ZERO))
			})
	return specs

func _build_shortcuts(rooms: Array, config: Dictionary, rng) -> Array:
	var shortcuts: Array = []
	var count = mini(int(config.get("shortcut_count", 4)), 4)
	for i in range(count):
		var a: Dictionary = rooms[1 + i * 3]
		var b: Dictionary = rooms[1 + ((i + 1) % 4) * 3]
		var pos: Vector2 = (a.get("position", Vector2.ZERO) as Vector2).lerp(b.get("position", Vector2.ZERO), 0.5)
		shortcuts.append({
			"id": "shortcut_%02d" % i,
			"position": pos,
			"size": Vector2(170.0, 64.0).rotated(0.0),
			"hp": int(config.get("shortcut_wall_hp", 145)) + i * 20,
			"type": "shortcut_wall",
			"breakable": true,
			"kind": "shortcut",
			"biome": "star_plain",
			"connects": [String(a.get("id", "")), String(b.get("id", ""))]
		})
	return shortcuts

func _crystal_type(terrain_id: String, rng) -> String:
	if terrain_id in ["danger_den", "sealed_room"] and rng.chance(0.52):
		return "cursed_crystal"
	if terrain_id in ["mine_chamber", "relic_vault", "boss_arena"] and rng.chance(0.62):
		return "rich_crystal"
	return "small_crystal"

func _biome_for_position(pos: Vector2, center: Vector2) -> String:
	if pos.x >= center.x and pos.y >= center.y:
		return "void_zone"
	if pos.y >= center.y:
		return "red_mine"
	if pos.x >= center.x:
		return "amethyst_forest"
	return "star_plain"
