extends RefCounted
class_name TrueDungeonMapGenerator

var connectivity = preload("res://scripts/systems/DungeonConnectivitySystem.gd").new()
var tile_collision = preload("res://scripts/systems/TileCollisionSystem.gd").new()

const ROOM_SHAPES := [
	"rectangle_room", "wide_hall_room", "vertical_room", "l_shape_room",
	"round_room", "cave_room", "tiny_room", "vault_room"
]
const CORRIDOR_SHAPES := ["straight", "l_corridor", "zigzag", "narrow", "wide"]

func generate(state, rng, config: Dictionary, room_config: Dictionary) -> Dictionary:
	var grid_width = int(config.get("grid_width", 120))
	var grid_height = int(config.get("grid_height", 120))
	var tile_size = int(config.get("tile_size", 64))
	var room_count = rng.range_int(int(config.get("room_count_min", 12)), int(config.get("room_count_max", 20)))
	var terrain_sequence: Array = room_config.get("required_sequence", []).duplicate()
	var rooms: Array = []
	var occupied_rects: Array = []
	var start = _make_room("room_00", "safe_room", "arena_room", Vector2i(grid_width / 2 - 9, grid_height / 2 - 7), Vector2i(18, 14), tile_size, true)
	rooms.append(start)
	occupied_rects.append(_room_rect(start).grow(3))
	for index in range(1, room_count):
		var terrain_id = String(terrain_sequence[(index - 1) % terrain_sequence.size()]) if not terrain_sequence.is_empty() else "crystal_corridor"
		var shape = "arena_room" if terrain_id == "boss_arena" else ROOM_SHAPES[(index + rng.next_int(ROOM_SHAPES.size())) % ROOM_SHAPES.size()]
		var placed = _place_room(index, terrain_id, shape, rooms, occupied_rects, grid_width, grid_height, tile_size, rng)
		if placed.is_empty():
			placed = _fallback_room(index, terrain_id, shape, rooms, occupied_rects, grid_width, grid_height, tile_size)
		rooms.append(placed)
		occupied_rects.append(_room_rect(placed).grow(3))
	var connections = _build_connection_graph(rooms, rng, float(config.get("loop_connection_chance", 0.25)))
	_ensure_start_exits(rooms, connections, 4)
	var walkable := {}
	for room in rooms:
		for key in room.get("floor_cells", []):
			walkable[String(key)] = true
	var corridors: Array = []
	for edge in connections:
		var corridor = _carve_corridor(rooms, edge, rng, tile_size)
		corridors.append(corridor)
		for key in corridor.get("cells", []):
			walkable[String(key)] = true
	var shortcuts = _build_shortcuts(rooms, connections, walkable, rng, config, tile_size)
	for shortcut in shortcuts:
		var connects: Array = shortcut.get("connects", ["", ""])
		corridors.append({
			"from": connects[0],
			"to": connects[1],
			"kind": "secret_shortcut",
			"shape": "secret_shortcut",
			"width_tiles": 1,
			"cells": shortcut.get("cells", []),
			"rects": []
		})
		connections.append({"from": connects[0], "to": connects[1], "kind": "secret_shortcut"})
	var boundary_cells = _boundary_cells(walkable, grid_width, grid_height)
	var wall_specs = _wall_specs(rooms, boundary_cells, shortcuts, rng, config, tile_size)
	var important_room_ids: Array = []
	for room in rooms:
		if bool(room.get("important", false)):
			important_room_ids.append(String(room.get("id", "")))
	var walkable_cells = walkable.keys()
	walkable_cells.sort()
	var layout = {
		"grid_width": grid_width,
		"grid_height": grid_height,
		"tile_size": tile_size,
		"rooms": rooms,
		"connections": connections,
		"corridors": corridors,
		"walkable_lookup": walkable,
		"walkable_cells": walkable_cells,
		"boundary_cells": boundary_cells,
		"wall_specs": wall_specs,
		"shortcut_walls": shortcuts,
		"important_room_ids": important_room_ids,
		"open_corridors": _exit_count(connections, "room_00"),
		"room_shape_count": _unique_count(rooms, "shape"),
		"corridor_shape_count": _unique_count(corridors, "shape"),
		"walkable_ratio": float(walkable.size()) / float(grid_width * grid_height),
		"cross_like": false
	}
	var validation = connectivity.validate(layout)
	layout["connected"] = bool(validation.get("all_reachable", false))
	layout["important_reachable"] = bool(validation.get("important_reachable", false))
	layout["branch_count"] = int(validation.get("branch_count", 0))
	layout["loop_count"] = int(validation.get("loop_count", 0))
	return layout

func _place_room(index: int, terrain_id: String, shape: String, rooms: Array, occupied: Array, grid_width: int, grid_height: int, tile_size: int, rng) -> Dictionary:
	for attempt in range(100):
		var size = _shape_size(shape, rng)
		var parent: Dictionary = rng.choice(rooms)
		var parent_rect = _room_rect(parent)
		var direction = rng.range_int(0, 7)
		var gap = rng.range_int(5, 11)
		var x = parent_rect.position.x
		var y = parent_rect.position.y
		match direction:
			0:
				x = parent_rect.end.x + gap
				y += rng.range_int(-size.y, parent_rect.size.y)
			1:
				x = parent_rect.position.x - size.x - gap
				y += rng.range_int(-size.y, parent_rect.size.y)
			2:
				y = parent_rect.end.y + gap
				x += rng.range_int(-size.x, parent_rect.size.x)
			3:
				y = parent_rect.position.y - size.y - gap
				x += rng.range_int(-size.x, parent_rect.size.x)
			4:
				x = parent_rect.end.x + gap
				y = parent_rect.end.y + gap
			5:
				x = parent_rect.position.x - size.x - gap
				y = parent_rect.end.y + gap
			6:
				x = parent_rect.end.x + gap
				y = parent_rect.position.y - size.y - gap
			_:
				x = parent_rect.position.x - size.x - gap
				y = parent_rect.position.y - size.y - gap
		var rect = Rect2i(x, y, size.x, size.y)
		if rect.position.x < 3 or rect.position.y < 3 or rect.end.x >= grid_width - 3 or rect.end.y >= grid_height - 3:
			continue
		var overlaps = false
		for used in occupied:
			if (used as Rect2i).intersects(rect):
				overlaps = true
				break
		if not overlaps:
			return _make_room("room_%02d" % index, terrain_id, shape, rect.position, rect.size, tile_size, true)
	return {}

func _fallback_room(index: int, terrain_id: String, shape: String, rooms: Array, occupied: Array, grid_width: int, grid_height: int, tile_size: int) -> Dictionary:
	var size = Vector2i(7 + index % 4, 6 + index % 3)
	for y in range(4, grid_height - size.y - 4, 4):
		for x in range(4, grid_width - size.x - 4, 4):
			var rect = Rect2i(x, y, size.x, size.y)
			var overlaps = false
			for used in occupied:
				if (used as Rect2i).intersects(rect):
					overlaps = true
					break
			if not overlaps:
				return _make_room("room_%02d" % index, terrain_id, shape, rect.position, rect.size, tile_size, true)
	return _make_room("room_%02d" % index, terrain_id, "tiny_room", Vector2i(4 + index, 4 + index), Vector2i(6, 6), tile_size, true)

func _make_room(id: String, terrain_id: String, shape: String, origin: Vector2i, size: Vector2i, tile_size: int, important: bool) -> Dictionary:
	var cells = _shape_cells(shape, origin, size)
	var center_cell = origin + Vector2i(size.x / 2, size.y / 2)
	return {
		"id": id,
		"terrain_id": terrain_id,
		"shape": shape,
		"cell_rect": [origin.x, origin.y, size.x, size.y],
		"floor_cells": cells,
		"position": (Vector2(center_cell) + Vector2(0.5, 0.5)) * tile_size,
		"size": Vector2(size) * tile_size,
		"important": important,
		"dead_end": terrain_id in ["relic_vault", "sealed_room", "boss_arena"]
	}

func _shape_cells(shape: String, origin: Vector2i, size: Vector2i) -> Array:
	var result: Array = []
	var center = Vector2(size) * 0.5
	for y in range(size.y):
		for x in range(size.x):
			var include = true
			match shape:
				"l_shape_room":
					include = x < maxi(3, size.x / 2) or y >= size.y / 2
				"round_room":
					var normalized = (Vector2(x + 0.5, y + 0.5) - center) / Vector2(maxf(1.0, center.x), maxf(1.0, center.y))
					include = normalized.length_squared() <= 1.0
				"cave_room":
					include = not ((x + y * 3 + size.x) % 11 == 0 and x > 1 and y > 1 and x < size.x - 2 and y < size.y - 2)
				_:
					include = true
			if include:
				result.append("%d,%d" % [origin.x + x, origin.y + y])
	return result

func _shape_size(shape: String, rng) -> Vector2i:
	match shape:
		"wide_hall_room":
			return Vector2i(rng.range_int(12, 17), rng.range_int(5, 8))
		"vertical_room":
			return Vector2i(rng.range_int(5, 8), rng.range_int(12, 17))
		"tiny_room":
			return Vector2i(rng.range_int(5, 7), rng.range_int(5, 7))
		"vault_room":
			return Vector2i(rng.range_int(6, 9), rng.range_int(6, 9))
		"arena_room":
			return Vector2i(rng.range_int(15, 19), rng.range_int(12, 16))
		_:
			return Vector2i(rng.range_int(7, 13), rng.range_int(7, 12))

func _build_connection_graph(rooms: Array, rng, loop_chance: float) -> Array:
	var edges: Array = []
	for i in range(1, rooms.size()):
		var nearest = 0
		var best = INF
		for j in range(i):
			var distance = (rooms[i].get("position", Vector2.ZERO) as Vector2).distance_squared_to(rooms[j].get("position", Vector2.ZERO))
			if distance < best:
				best = distance
				nearest = j
		edges.append({"from": rooms[nearest].get("id", ""), "to": rooms[i].get("id", ""), "kind": "corridor"})
	for i in range(rooms.size()):
		if not rng.chance(loop_chance):
			continue
		var candidates: Array = []
		for j in range(rooms.size()):
			if i != j and not _has_edge(edges, String(rooms[i].get("id", "")), String(rooms[j].get("id", ""))):
				candidates.append(j)
		if not candidates.is_empty():
			var j = int(rng.choice(candidates))
			edges.append({"from": rooms[i].get("id", ""), "to": rooms[j].get("id", ""), "kind": "loop"})
	return edges

func _ensure_start_exits(rooms: Array, edges: Array, minimum: int) -> void:
	var candidates: Array = []
	for i in range(1, rooms.size()):
		candidates.append({"index": i, "distance": (rooms[i].get("position", Vector2.ZERO) as Vector2).distance_squared_to(rooms[0].get("position", Vector2.ZERO))})
	candidates.sort_custom(func(a, b): return float(a.get("distance", INF)) < float(b.get("distance", INF)))
	for row in candidates:
		if _exit_count(edges, "room_00") >= minimum:
			break
		var target = String(rooms[int(row.get("index", 0))].get("id", ""))
		if not _has_edge(edges, "room_00", target):
			edges.append({"from": "room_00", "to": target, "kind": "loop"})

func _carve_corridor(rooms: Array, edge: Dictionary, rng, tile_size: int) -> Dictionary:
	var a = _room_center_cell(_room_by_id(rooms, String(edge.get("from", ""))))
	var b = _room_center_cell(_room_by_id(rooms, String(edge.get("to", ""))))
	var shape = CORRIDOR_SHAPES[rng.next_int(CORRIDOR_SHAPES.size())]
	var points: Array = [a]
	if shape == "zigzag":
		var middle_x = int(round(lerpf(float(a.x), float(b.x), rng.range_float(0.28, 0.72))))
		var middle_y = int(round(lerpf(float(a.y), float(b.y), rng.range_float(0.28, 0.72))))
		points.append(Vector2i(middle_x, a.y))
		points.append(Vector2i(middle_x, middle_y))
		points.append(Vector2i(b.x, middle_y))
	elif shape != "straight":
		points.append(Vector2i(b.x, a.y) if rng.chance(0.5) else Vector2i(a.x, b.y))
	points.append(b)
	var width = 1 if shape == "narrow" else (3 if shape == "wide" else 2)
	var cell_lookup := {}
	for i in range(points.size() - 1):
		_carve_segment(cell_lookup, points[i], points[i + 1], width)
	var cells = cell_lookup.keys()
	cells.sort()
	return {
		"from": edge.get("from", ""),
		"to": edge.get("to", ""),
		"kind": edge.get("kind", "corridor"),
		"shape": "loop" if String(edge.get("kind", "")) == "loop" else shape,
		"width_tiles": width,
		"points": points,
		"cells": cells,
		"rects": _point_rects(points, width, tile_size)
	}

func _build_shortcuts(rooms: Array, connections: Array, walkable: Dictionary, rng, config: Dictionary, tile_size: int) -> Array:
	var result: Array = []
	var count = int(config.get("secret_shortcut_count", 4))
	for index in range(count):
		var a: Dictionary = rooms[1 + index % maxi(1, rooms.size() - 1)]
		var b: Dictionary = rooms[1 + (index * 3 + 5) % maxi(1, rooms.size() - 1)]
		if String(a.get("id", "")) == String(b.get("id", "")):
			continue
		var edge = {"from": a.get("id", ""), "to": b.get("id", ""), "kind": "secret_shortcut"}
		var corridor = _carve_corridor(rooms, edge, rng, tile_size)
		for key in corridor.get("cells", []):
			walkable[String(key)] = true
		var cells: Array = corridor.get("cells", [])
		var middle_key = _farthest_cell_key(cells, rooms[0].get("position", Vector2.ZERO), tile_size)
		if middle_key == "":
			middle_key = String(a.get("floor_cells", [])[0])
		var cell = _decode_cell(middle_key)
		result.append({
			"id": "shortcut_%02d" % index,
			"position": (Vector2(cell) + Vector2(0.5, 0.5)) * tile_size,
			"size": Vector2(tile_size * 0.9, tile_size * 0.35),
			"hp": int(config.get("shortcut_wall_hp", 145)) + index * 20,
			"type": "shortcut_wall",
			"breakable": true,
			"kind": "shortcut",
			"biome": "star_plain",
			"connects": [String(a.get("id", "")), String(b.get("id", ""))],
			"cells": cells
		})
	return result

func _wall_specs(rooms: Array, boundary_cells: Array, shortcuts: Array, rng, config: Dictionary, tile_size: int) -> Array:
	var specs: Array = []
	var structural_count = mini(18, boundary_cells.size())
	for i in range(structural_count):
		var key = String(boundary_cells[int(float(i) * float(boundary_cells.size()) / float(maxi(1, structural_count)))])
		var cell = _decode_cell(key)
		specs.append({
			"id": "abyss_edge_%02d" % i,
			"position": (Vector2(cell) + Vector2(0.5, 0.5)) * tile_size,
			"size": Vector2(tile_size * 0.72, tile_size * 0.72),
			"hp": int(config.get("structural_wall_hp", 999999)),
			"type": "ancient_wall",
			"breakable": false,
			"kind": "structural",
			"biome": "void_zone"
		})
	for room in rooms:
		if String(room.get("id", "")) == "room_00":
			continue
		var floor_cells: Array = room.get("floor_cells", [])
		for crystal_index in range(rng.range_int(1, 2)):
			if floor_cells.is_empty():
				continue
			var cell = _decode_cell(String(rng.choice(floor_cells)))
			var crystal_position = (Vector2(cell) + Vector2(0.5, 0.5)) * tile_size
			if crystal_position.distance_to(rooms[0].get("position", Vector2.ZERO)) < float(config.get("safe_radius", 600.0)):
				continue
			var terrain_id = String(room.get("terrain_id", ""))
			var crystal_type = "wall_crystal"
			if terrain_id in ["danger_den", "sealed_room"]:
				crystal_type = "cursed_crystal"
			elif terrain_id in ["mine_chamber", "relic_vault", "boss_arena"]:
				crystal_type = "rich_crystal"
			elif terrain_id == "event_room":
				crystal_type = "small_crystal"
			specs.append({
				"id": "%s_crystal_%d" % [String(room.get("id", "room")), crystal_index],
				"position": crystal_position,
				"size": Vector2(tile_size * 0.9, tile_size * 0.65),
				"hp": rng.range_int(60, 135),
				"type": crystal_type,
				"breakable": true,
				"kind": "room_crystal",
				"biome": "star_plain"
			})
	specs.append_array(shortcuts)
	return specs

func _boundary_cells(walkable: Dictionary, grid_width: int, grid_height: int) -> Array:
	var boundary := {}
	for raw_key in walkable.keys():
		var cell = _decode_cell(String(raw_key))
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor = cell + direction
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= grid_width or neighbor.y >= grid_height:
				continue
			var key = "%d,%d" % [neighbor.x, neighbor.y]
			if not walkable.has(key):
				boundary[key] = true
	var result = boundary.keys()
	result.sort()
	return result

func _carve_segment(lookup: Dictionary, a: Vector2i, b: Vector2i, width: int) -> void:
	var current = a
	var step = Vector2i(signi(b.x - a.x), signi(b.y - a.y))
	while current != b:
		_carve_width(lookup, current, width)
		if current.x != b.x:
			current.x += step.x
		elif current.y != b.y:
			current.y += step.y
	_carve_width(lookup, b, width)

func _carve_width(lookup: Dictionary, cell: Vector2i, width: int) -> void:
	for y in range(-width + 1, width):
		for x in range(-width + 1, width):
			lookup["%d,%d" % [cell.x + x, cell.y + y]] = true

func _point_rects(points: Array, width: int, tile_size: int) -> Array:
	var rects: Array = []
	for i in range(points.size() - 1):
		var a: Vector2i = points[i]
		var b: Vector2i = points[i + 1]
		var center = (Vector2(a + b) * 0.5 + Vector2(0.5, 0.5)) * tile_size
		var size = Vector2(absf(float(b.x - a.x)) + float(width * 2 - 1), absf(float(b.y - a.y)) + float(width * 2 - 1)) * tile_size
		rects.append({"position": center, "size": size})
	return rects

func _room_rect(room: Dictionary) -> Rect2i:
	var data: Array = room.get("cell_rect", [0, 0, 1, 1])
	return Rect2i(int(data[0]), int(data[1]), int(data[2]), int(data[3]))

func _room_center_cell(room: Dictionary) -> Vector2i:
	var rect = _room_rect(room)
	return rect.position + Vector2i(rect.size.x / 2, rect.size.y / 2)

func _room_by_id(rooms: Array, id: String) -> Dictionary:
	for room in rooms:
		if String(room.get("id", "")) == id:
			return room
	return rooms[0] if not rooms.is_empty() else {}

func _has_edge(edges: Array, a: String, b: String) -> bool:
	for edge in edges:
		var from_id = String(edge.get("from", ""))
		var to_id = String(edge.get("to", ""))
		if (from_id == a and to_id == b) or (from_id == b and to_id == a):
			return true
	return false

func _exit_count(edges: Array, id: String) -> int:
	var count = 0
	for edge in edges:
		if String(edge.get("from", "")) == id or String(edge.get("to", "")) == id:
			count += 1
	return count

func _unique_count(rows: Array, key: String) -> int:
	var unique := {}
	for row in rows:
		unique[String(row.get(key, ""))] = true
	return unique.size()

func _decode_cell(key: String) -> Vector2i:
	var parts = key.split(",")
	return Vector2i(int(parts[0]), int(parts[1])) if parts.size() == 2 else Vector2i.ZERO

func _farthest_cell_key(cells: Array, origin: Vector2, tile_size: int) -> String:
	var best_key = ""
	var best_distance = -1.0
	for raw_key in cells:
		var key = String(raw_key)
		var position = (Vector2(_decode_cell(key)) + Vector2(0.5, 0.5)) * tile_size
		var distance = position.distance_squared_to(origin)
		if distance > best_distance:
			best_distance = distance
			best_key = key
	return best_key
