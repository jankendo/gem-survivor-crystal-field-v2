extends RefCounted
class_name GemRegistry

func active_gems(state) -> Array:
	var result: Array = []
	for gem in state.gems:
		if gem != null:
			result.append(gem)
	return result

func gems_in_radius(state, center: Vector2, radius: float) -> Array:
	var result: Array = []
	var radius_sq = radius * radius
	for gem in state.gems:
		if gem != null and gem.position.distance_squared_to(center) <= radius_sq:
			result.append(gem)
	return result

func active_count(state) -> int:
	return state.gems.size()
