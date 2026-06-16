extends RefCounted
class_name SafePlayInputMapper

func accepts(point: Vector2, play_rect: Rect2) -> bool:
	return play_rect.has_point(point)

func map_point(point: Vector2, play_rect: Rect2) -> Vector2:
	return Vector2(
		clampf(point.x, play_rect.position.x, play_rect.end.x),
		clampf(point.y, play_rect.position.y, play_rect.end.y)
	)
