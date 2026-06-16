extends RefCounted
class_name SafePlayViewportSystem

func world_view_size(base_world_size: Vector2, viewport_size: Vector2, play_rect: Rect2) -> Vector2:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return base_world_size
	return Vector2(
		base_world_size.x * viewport_size.x / maxf(1.0, play_rect.size.x),
		base_world_size.y * viewport_size.y / maxf(1.0, play_rect.size.y)
	)

func screen_to_safe(point: Vector2, play_rect: Rect2) -> Vector2:
	return Vector2(
		clampf(point.x, play_rect.position.x, play_rect.end.x),
		clampf(point.y, play_rect.position.y, play_rect.end.y)
	)
