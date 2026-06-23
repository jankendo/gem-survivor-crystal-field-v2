extends RefCounted
class_name WorldPlacementValidator

const TileCollisionSystemScript = preload("res://scripts/systems/TileCollisionSystem.gd")

var tile_collision = TileCollisionSystemScript.new()
var cache_key := ""
var reachable_lookup: Dictionary = {}
var connected_component_by_cell: Dictionary = {}
var room_id_by_cell: Dictionary = {}
var safe_cells_by_rule: Dictionary = {}
var origin_component := -1

func build_cache(map_data: Dictionary, origin: Vector2) -> void:
	var key := "%s:%d:%d:%d" % [
		str(map_data.get("seed", "")),
		int(map_data.get("walkable_cells", []).size()),
		int(origin.x),
		int(origin.y)
	]
	if key == cache_key:
		return
	cache_key = key
	reachable_lookup = {}
	connected_component_by_cell = {}
	room_id_by_cell = {}
	safe_cells_by_rule = {}
	_build_room_lookup(map_data)
	_build_components(map_data, origin)

func is_inside_map(map_data: Dictionary, position: Vector2, edge_margin: float = 0.0) -> bool:
	var width := float(map_data.get("grid_width", 0)) * float(map_data.get("tile_size", 64.0))
	var height := float(map_data.get("grid_height", 0)) * float(map_data.get("tile_size", 64.0))
	if width <= 0.0 or height <= 0.0:
		return true
	return position.x >= edge_margin and position.y >= edge_margin and position.x <= width - edge_margin and position.y <= height - edge_margin

func is_walkable(map_data: Dictionary, position: Vector2, radius: float) -> bool:
	return tile_collision.is_walkable(map_data, position, radius)

func has_wall_clearance(map_data: Dictionary, position: Vector2, radius: float, margin: float) -> bool:
	if not tile_collision.is_walkable(map_data, position, radius + margin):
		return false
	return not _overlaps_wall_spec(map_data, position, radius + margin)

func is_reachable(map_data: Dictionary, position: Vector2) -> bool:
	if reachable_lookup.is_empty():
		return true
	return bool(reachable_lookup.get(tile_collision.cell_key(tile_collision.world_to_cell(map_data, position)), false))

func get_room_id(map_data: Dictionary, position: Vector2) -> String:
	var key := tile_collision.cell_key(tile_collision.world_to_cell(map_data, position))
	return String(room_id_by_cell.get(key, "corridor" if tile_collision.is_walkable(map_data, position, 0.0) else ""))

func get_connected_component_id(map_data: Dictionary, position: Vector2) -> int:
	var key := tile_collision.cell_key(tile_collision.world_to_cell(map_data, position))
	return int(connected_component_by_cell.get(key, -1))

func validation_result(map_data: Dictionary, position: Vector2, pickup_type: String, rules: Dictionary) -> Dictionary:
	var radius := float(rules.get("radius", 22.0))
	var margin := float(rules.get("margin", 10.0))
	var edge_margin := float(rules.get("edge_margin", 96.0))
	var reasons: Array = []
	if position == Vector2.INF:
		reasons.append("invalid_position")
	if not is_inside_map(map_data, position, edge_margin):
		reasons.append("outside_map")
	if not is_walkable(map_data, position, radius):
		reasons.append("not_walkable")
	if not has_wall_clearance(map_data, position, radius, margin):
		reasons.append("wall_clearance")
	if bool(rules.get("require_reachable", true)) and not is_reachable(map_data, position):
		reasons.append("unreachable")
	if bool(rules.get("require_room_or_corridor", true)) and get_room_id(map_data, position) == "":
		reasons.append("no_room_or_corridor")
	return {
		"ok": reasons.is_empty(),
		"pickup_type": pickup_type,
		"position": position,
		"reasons": reasons,
		"room_id": get_room_id(map_data, position),
		"component_id": get_connected_component_id(map_data, position)
	}

func is_valid_pickup_position(map_data: Dictionary, position: Vector2, pickup_type: String, rules: Dictionary) -> bool:
	return bool(validation_result(map_data, position, pickup_type, rules).get("ok", false))

func safe_cells(map_data: Dictionary, pickup_type: String, rules: Dictionary) -> Array:
	var cache_id := "%s:%d:%d:%d" % [
		pickup_type,
		int(round(float(rules.get("radius", 22.0)))),
		int(round(float(rules.get("margin", 10.0)))),
		int(round(float(rules.get("edge_margin", 96.0))))
	]
	if safe_cells_by_rule.has(cache_id):
		return safe_cells_by_rule[cache_id]
	var result: Array = []
	var radius := float(rules.get("radius", 22.0))
	var margin := float(rules.get("margin", 10.0))
	var edge_margin := float(rules.get("edge_margin", 96.0))
	var require_reachable := bool(rules.get("require_reachable", true))
	var require_room_or_corridor := bool(rules.get("require_room_or_corridor", true))
	for raw_cell in map_data.get("walkable_cells", []):
		var key := String(raw_cell)
		var cell := _decode_cell(key)
		var world := tile_collision.cell_to_world(map_data, cell)
		if not is_inside_map(map_data, world, edge_margin):
			continue
		if not tile_collision.is_walkable(map_data, world, radius + margin):
			continue
		if require_reachable and not bool(reachable_lookup.get(key, false)):
			continue
		if require_room_or_corridor and String(room_id_by_cell.get(key, "")) == "":
			continue
		result.append(key)
	safe_cells_by_rule[cache_id] = result
	return result

func _build_components(map_data: Dictionary, origin: Vector2) -> void:
	var walkable: Dictionary = map_data.get("walkable_lookup", {})
	if walkable.is_empty():
		return
	var component_id := 0
	var origin_key := tile_collision.cell_key(tile_collision.world_to_cell(map_data, origin))
	if not bool(walkable.get(origin_key, false)):
		origin_key = tile_collision.cell_key(tile_collision.world_to_cell(map_data, tile_collision.nearest_walkable(map_data, origin, 0.0)))
	for raw_key in walkable.keys():
		var key := String(raw_key)
		if not bool(walkable.get(key, false)) or connected_component_by_cell.has(key):
			continue
		var queue: Array = [_decode_cell(key)]
		connected_component_by_cell[key] = component_id
		var cursor := 0
		while cursor < queue.size():
			var cell: Vector2i = queue[cursor]
			cursor += 1
			for neighbor in [Vector2i(cell.x + 1, cell.y), Vector2i(cell.x - 1, cell.y), Vector2i(cell.x, cell.y + 1), Vector2i(cell.x, cell.y - 1)]:
				var nkey := tile_collision.cell_key(neighbor)
				if not bool(walkable.get(nkey, false)) or connected_component_by_cell.has(nkey):
					continue
				connected_component_by_cell[nkey] = component_id
				queue.append(neighbor)
		if connected_component_by_cell.get(origin_key, -2) == component_id:
			origin_component = component_id
		component_id += 1
	origin_component = int(connected_component_by_cell.get(origin_key, origin_component))
	for key in connected_component_by_cell.keys():
		if int(connected_component_by_cell[key]) == origin_component:
			reachable_lookup[String(key)] = true

func _build_room_lookup(map_data: Dictionary) -> void:
	for raw_cell in map_data.get("walkable_cells", []):
		var key := String(raw_cell)
		var world := tile_collision.cell_to_world(map_data, _decode_cell(key))
		var room_id := ""
		for room in map_data.get("rooms", []):
			var center: Vector2 = room.get("position", Vector2.ZERO)
			var size: Vector2 = room.get("size", Vector2.ZERO)
			if Rect2(center - size * 0.5, size).has_point(world):
				room_id = String(room.get("id", "room"))
				break
		room_id_by_cell[key] = room_id if room_id != "" else "corridor"

func _overlaps_wall_spec(map_data: Dictionary, position: Vector2, radius: float) -> bool:
	for wall in map_data.get("wall_specs", []):
		var center: Vector2 = wall.get("position", Vector2.ZERO)
		var size: Vector2 = wall.get("size", Vector2.ZERO)
		if size == Vector2.ZERO:
			continue
		var rect := Rect2(center - size * 0.5, size)
		var nearest := Vector2(clampf(position.x, rect.position.x, rect.position.x + rect.size.x), clampf(position.y, rect.position.y, rect.position.y + rect.size.y))
		if nearest.distance_to(position) <= radius:
			return true
	return false

func _decode_cell(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))
