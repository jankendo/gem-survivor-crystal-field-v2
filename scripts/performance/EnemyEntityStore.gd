extends RefCounted
class_name EnemyEntityStore

const ID_INDEX_SPACE := 1048576

var positions := PackedVector2Array()
var velocities := PackedVector2Array()
var hp := PackedInt32Array()
var max_hp := PackedInt32Array()
var radii := PackedFloat32Array()
var speeds := PackedFloat32Array()
var generations := PackedInt32Array()
var alive_flags := PackedInt32Array()
var types := PackedStringArray()
var free_indices: Array = []
var alive_count := 0
var created_count := 0
var reused_count := 0
var removed_count := 0

func allocate(enemy_type: String, position: Vector2, hit_points: int, radius: float, speed: float) -> int:
	var index := 0
	if free_indices.is_empty():
		index = positions.size()
		_resize(index + 1)
		created_count += 1
	else:
		index = int(free_indices.pop_back())
		reused_count += 1
	positions[index] = position
	velocities[index] = Vector2.ZERO
	hp[index] = maxi(1, hit_points)
	max_hp[index] = maxi(1, hit_points)
	radii[index] = radius
	speeds[index] = speed
	types[index] = enemy_type
	alive_flags[index] = 1
	alive_count += 1
	return _make_id(index)

func remove(id: int) -> bool:
	if not is_alive(id):
		return false
	var index := index_from_id(id)
	alive_flags[index] = 0
	generations[index] += 1
	free_indices.append(index)
	alive_count = maxi(0, alive_count - 1)
	removed_count += 1
	return true

func is_alive(id: int) -> bool:
	var index := index_from_id(id)
	if index < 0 or index >= alive_flags.size():
		return false
	return int(alive_flags[index]) == 1 and int(generations[index]) == generation_from_id(id)

func index_from_id(id: int) -> int:
	return id % ID_INDEX_SPACE

func generation_from_id(id: int) -> int:
	return int(floor(float(id) / float(ID_INDEX_SPACE)))

func active_indices() -> Array:
	var result: Array = []
	for index in range(alive_flags.size()):
		if int(alive_flags[index]) == 1:
			result.append(index)
	return result

func active_ids() -> Array:
	var result: Array = []
	for index in active_indices():
		result.append(_make_id(index))
	return result

func move_by(id: int, delta_position: Vector2) -> bool:
	if not is_alive(id):
		return false
	var index := index_from_id(id)
	positions[index] += delta_position
	return true

func set_velocity(id: int, velocity: Vector2) -> bool:
	if not is_alive(id):
		return false
	velocities[index_from_id(id)] = velocity
	return true

func damage(id: int, amount: int) -> bool:
	if not is_alive(id):
		return false
	var index := index_from_id(id)
	hp[index] -= maxi(0, amount)
	return hp[index] <= 0

func position_of(id: int) -> Vector2:
	return positions[index_from_id(id)] if is_alive(id) else Vector2.INF

func stats() -> Dictionary:
	return {
		"capacity": positions.size(),
		"alive": alive_count,
		"free": free_indices.size(),
		"created": created_count,
		"reused": reused_count,
		"removed": removed_count
	}

func _make_id(index: int) -> int:
	return int(generations[index]) * ID_INDEX_SPACE + index

func _resize(size: int) -> void:
	positions.resize(size)
	velocities.resize(size)
	hp.resize(size)
	max_hp.resize(size)
	radii.resize(size)
	speeds.resize(size)
	generations.resize(size)
	alive_flags.resize(size)
	types.resize(size)

