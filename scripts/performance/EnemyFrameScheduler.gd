extends RefCounted
class_name EnemyFrameScheduler

var frame_index := 0
var cursor := 0

func begin_frame() -> void:
	frame_index += 1

func select_indices(active_indices: Array, max_updates: int) -> Array:
	if active_indices.is_empty() or max_updates <= 0:
		return []
	var count = mini(active_indices.size(), max_updates)
	var result: Array = []
	for i in range(count):
		result.append(active_indices[(cursor + i) % active_indices.size()])
	cursor = (cursor + count) % active_indices.size()
	return result

func update_interval_for_distance(distance: float, is_boss: bool = false) -> float:
	if is_boss:
		return 0.0
	if distance <= 720.0:
		return 0.05
	if distance <= 1280.0:
		return 0.20
	return 0.35

