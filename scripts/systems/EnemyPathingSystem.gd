extends RefCounted
class_name EnemyPathingSystem

var collision = preload("res://scripts/systems/TileCollisionSystem.gd").new()

func direction_to_target(state, from: Vector2, target: Vector2, radius: float) -> Vector2:
	var direct = (target - from).normalized()
	if direct == Vector2.ZERO:
		return Vector2.ZERO
	var probe_distance = maxf(28.0, radius * 1.8)
	if collision.is_walkable(state.map_data, from + direct * probe_distance, radius):
		return direct
	var best = Vector2.ZERO
	var best_score = INF
	for i in range(16):
		var direction = Vector2.RIGHT.rotated(TAU * float(i) / 16.0)
		var probe = from + direction * probe_distance
		if not collision.is_walkable(state.map_data, probe, radius):
			continue
		var score = probe.distance_squared_to(target)
		if score < best_score:
			best_score = score
			best = direction
	return best if best != Vector2.ZERO else direct.rotated(PI * 0.5)

func recycle_position(state, origin: Vector2, min_distance: float = 460.0, max_distance: float = 720.0) -> Vector2:
	return collision.random_walkable_position(state.map_data, state.rng, origin, min_distance, max_distance)
