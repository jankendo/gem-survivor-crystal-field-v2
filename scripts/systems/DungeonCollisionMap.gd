extends RefCounted
class_name DungeonCollisionMap

func is_walkable(state, position: Vector2, radius: float, skin_width: float = 3.0) -> bool:
	var effective_radius := radius + skin_width
	if position.x < effective_radius or position.y < effective_radius:
		return false
	if position.x > state.field_size.x - effective_radius or position.y > state.field_size.y - effective_radius:
		return false
	if not state.is_walkable_position(position, effective_radius):
		return false
	for wall in state.crystal_walls:
		if not wall.blocks:
			continue
		if wall.breakable and int(state.passives.get("emergency_route", 0)) > 0 and state.hp_ratio() <= 0.24:
			continue
		if _circle_intersects_rect(position, effective_radius, wall.rect()):
			return false
	return true

func _circle_intersects_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var nearest := Vector2(
		clampf(center.x, rect.position.x, rect.end.x),
		clampf(center.y, rect.position.y, rect.end.y)
	)
	return nearest.distance_squared_to(center) < radius * radius
