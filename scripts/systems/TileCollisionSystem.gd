extends RefCounted
class_name TileCollisionSystem

const SAMPLE_DIRECTIONS := [
	Vector2.ZERO,
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.UP,
	Vector2.DOWN,
	Vector2(-0.70710678, -0.70710678),
	Vector2(0.70710678, -0.70710678),
	Vector2(-0.70710678, 0.70710678),
	Vector2(0.70710678, 0.70710678)
]

func cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

func world_to_cell(map_data: Dictionary, position: Vector2) -> Vector2i:
	var tile_size = float(map_data.get("tile_size", 64.0))
	return Vector2i(floori(position.x / tile_size), floori(position.y / tile_size))

func cell_to_world(map_data: Dictionary, cell: Vector2i) -> Vector2:
	var tile_size = float(map_data.get("tile_size", 64.0))
	return (Vector2(cell) + Vector2(0.5, 0.5)) * tile_size

func is_walkable(map_data: Dictionary, position: Vector2, radius: float = 0.0) -> bool:
	var lookup: Dictionary = map_data.get("walkable_lookup", {})
	if lookup.is_empty():
		return true
	if radius <= 0.0:
		return bool(lookup.get(cell_key(world_to_cell(map_data, position)), false))
	for direction in SAMPLE_DIRECTIONS:
		var sample = position + direction * radius
		if not bool(lookup.get(cell_key(world_to_cell(map_data, sample)), false)):
			return false
	return true

func resolve_position(map_data: Dictionary, requested: Vector2, radius: float, fallback: Vector2) -> Vector2:
	if is_walkable(map_data, requested, radius):
		return requested
	if is_walkable(map_data, fallback, radius):
		var low = 0.0
		var high = 1.0
		for i in range(8):
			var middle = (low + high) * 0.5
			if is_walkable(map_data, fallback.lerp(requested, middle), radius):
				low = middle
			else:
				high = middle
		return fallback.lerp(requested, low)
	return nearest_walkable(map_data, requested, radius)

func nearest_walkable(map_data: Dictionary, position: Vector2, radius: float = 0.0, max_steps: int = 18) -> Vector2:
	var origin = world_to_cell(map_data, position)
	for step in range(max_steps + 1):
		for y in range(origin.y - step, origin.y + step + 1):
			for x in range(origin.x - step, origin.x + step + 1):
				if step > 0 and x > origin.x - step and x < origin.x + step and y > origin.y - step and y < origin.y + step:
					continue
				var candidate = cell_to_world(map_data, Vector2i(x, y))
				if is_walkable(map_data, candidate, radius):
					return candidate
	return position

func random_walkable_position(map_data: Dictionary, rng, origin: Vector2, min_distance: float, max_distance: float) -> Vector2:
	var cells: Array = map_data.get("walkable_cells", [])
	if cells.is_empty():
		return origin
	var candidates: Array = []
	for raw_cell in cells:
		var cell = _decode_cell(String(raw_cell))
		var world = cell_to_world(map_data, cell)
		var distance = world.distance_to(origin)
		if distance >= min_distance and distance <= max_distance:
			candidates.append(world)
	if candidates.is_empty():
		return nearest_walkable(map_data, origin + Vector2.RIGHT * min_distance)
	return rng.choice(candidates)

func _decode_cell(key: String) -> Vector2i:
	var parts = key.split(",")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))
