extends RefCounted
class_name IosSafePlayAreaSystem

func safe_play_rect(viewport_size: Vector2, settings: Dictionary = {}, ios_touch: bool = true, base_safe_rect: Rect2 = Rect2()) -> Rect2:
	var protect := bool(settings.get("notch_protection", true))
	if not ios_touch or not protect:
		return base_safe_rect if base_safe_rect.size.x > 0.0 else Rect2(Vector2.ZERO, viewport_size)
	var extra_margin := float(settings.get("safe_area_margin", 16.0))
	var side_bar := _symmetric_side_bar(viewport_size, extra_margin)
	var top := maxf(extra_margin, base_safe_rect.position.y if base_safe_rect.size.y > 0.0 else extra_margin)
	var bottom := maxf(extra_margin + _home_indicator_margin(viewport_size), viewport_size.y - (base_safe_rect.end.y if base_safe_rect.size.y > 0.0 else viewport_size.y))
	return Rect2(
		Vector2(side_bar, top),
		Vector2(maxf(1.0, viewport_size.x - side_bar * 2.0), maxf(1.0, viewport_size.y - top - bottom))
	)

func letterbox_bars(viewport_size: Vector2, play_rect: Rect2) -> Array:
	var bars: Array = []
	if play_rect.position.x > 0.0:
		bars.append(Rect2(Vector2.ZERO, Vector2(play_rect.position.x, viewport_size.y)))
	if play_rect.end.x < viewport_size.x:
		bars.append(Rect2(Vector2(play_rect.end.x, 0.0), Vector2(viewport_size.x - play_rect.end.x, viewport_size.y)))
	return bars

func contains_input(point: Vector2, viewport_size: Vector2, settings: Dictionary = {}, ios_touch: bool = true, base_safe_rect: Rect2 = Rect2()) -> bool:
	return safe_play_rect(viewport_size, settings, ios_touch, base_safe_rect).has_point(point)

func _symmetric_side_bar(viewport_size: Vector2, extra_margin: float) -> float:
	var is_tablet := viewport_size.y >= 1500.0
	var notch_guard := clampf(viewport_size.x * (0.018 if is_tablet else 0.052), 42.0 if is_tablet else 86.0, 164.0)
	return maxf(extra_margin, notch_guard)

func _home_indicator_margin(viewport_size: Vector2) -> float:
	return clampf(viewport_size.y * 0.018, 18.0, 38.0)
