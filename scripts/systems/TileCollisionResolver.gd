extends RefCounted
class_name TileCollisionResolver

const DungeonCollisionMapScript = preload("res://scripts/systems/DungeonCollisionMap.gd")

var collision_map = DungeonCollisionMapScript.new()

func can_occupy(state, position: Vector2, radius: float, skin_width: float = 3.0) -> bool:
	state.ios_physics_query_count += 1
	return collision_map.is_walkable(state, position, radius, skin_width)

func sweep_axis(state, origin: Vector2, motion: Vector2, radius: float, skin_width: float = 3.0) -> Vector2:
	if motion.length_squared() <= 0.0001:
		return origin
	var low := 0.0
	var high := 1.0
	for i in range(7):
		var middle := (low + high) * 0.5
		if can_occupy(state, origin + motion * middle, radius, skin_width):
			low = middle
		else:
			high = middle
	return origin + motion * low
