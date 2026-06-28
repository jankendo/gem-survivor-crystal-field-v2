extends RefCounted
class_name ProjectileRenderSelectionSystem

func select(
		projectiles: Array,
		camera_position: Vector2,
		visible_size: Vector2,
		limit: int,
		margin: float = 96.0
	) -> Array:
	var rect := Rect2(camera_position - visible_size * 0.5, visible_size).grow(margin)
	var signature: Array = []
	var nearby: Array = []
	var normal: Array = []
	for projectile in projectiles:
		if not rect.has_point(projectile.position):
			continue
		if bool(projectile.evolved):
			signature.append(projectile)
		elif projectile.position.distance_squared_to(camera_position) <= 320.0 * 320.0:
			nearby.append(projectile)
		else:
			normal.append(projectile)
	var result: Array = []
	_append_until(result, signature, limit)
	_append_until(result, nearby, limit)
	_append_until(result, normal, limit)
	return result

func _append_until(target: Array, source: Array, limit: int) -> void:
	for value in source:
		if target.size() >= limit:
			return
		target.append(value)

