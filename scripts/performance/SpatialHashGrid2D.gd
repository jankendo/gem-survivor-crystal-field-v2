extends RefCounted
class_name SpatialHashGrid2D

var cell_size := 160.0
var cells: Dictionary = {}
var item_cells: Dictionary = {}
var query_candidates_last := 0

func _init(configured_cell_size: float = 160.0) -> void:
	cell_size = maxf(32.0, configured_cell_size)

func clear() -> void:
	cells.clear()
	item_cells.clear()
	query_candidates_last = 0

func rebuild(items: Array) -> void:
	clear()
	for item in items:
		insert(item, _position_of(item))

func insert(item, position: Vector2) -> void:
	var key := _coords(position)
	if not cells.has(key):
		cells[key] = []
	cells[key].append(item)
	item_cells[_item_key(item)] = key

func insert_id(id: int, position: Vector2) -> void:
	var key := _coords(position)
	if not cells.has(key):
		cells[key] = []
	cells[key].append({"id": id, "position": position})
	item_cells[id] = key

func query_radius(position: Vector2, radius: float, buffer = null) -> Array:
	var result: Array = [] if buffer == null else buffer.values()
	if buffer != null:
		buffer.clear()
	var radius_sq := radius * radius
	var min_cell := _coords(position - Vector2.ONE * radius)
	var max_cell := _coords(position + Vector2.ONE * radius)
	query_candidates_last = 0
	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			for item in cells.get(Vector2i(x, y), []):
				query_candidates_last += 1
				if _position_of(item).distance_squared_to(position) <= radius_sq:
					result.append(item)
	return result

func query_ids_radius(position: Vector2, radius: float, buffer = null) -> Array:
	var raw := query_radius(position, radius, buffer)
	var ids: Array = []
	for item in raw:
		ids.append(int(item.get("id", -1)) if item is Dictionary else int(_item_key(item)))
	return ids

func _position_of(item) -> Vector2:
	if item is Dictionary:
		return item.get("position", item.get("pos", Vector2.ZERO))
	var value = item.get("position")
	return value if value is Vector2 else Vector2.ZERO

func _item_key(item):
	if item is Object:
		return item.get_instance_id()
	return hash(item)

func _coords(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / cell_size), floori(position.y / cell_size))
