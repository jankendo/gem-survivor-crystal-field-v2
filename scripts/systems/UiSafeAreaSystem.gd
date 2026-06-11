extends RefCounted
class_name UiSafeAreaSystem

func safe_rect(viewport_size: Vector2, layout: Dictionary = {}) -> Rect2:
	var margin = float(layout.get("safe_margin", 24.0))
	return Rect2(Vector2(margin, margin), Vector2(maxf(1.0, viewport_size.x - margin * 2.0), maxf(1.0, viewport_size.y - margin * 2.0)))

func ui_scale_for(viewport_size: Vector2, requested: float, layout: Dictionary = {}) -> float:
	var min_scale = float(layout.get("ui_scale_min", 0.86))
	var max_scale = float(layout.get("ui_scale_max", 1.18))
	var size_scale = clampf(viewport_size.y / 900.0, min_scale, 1.0)
	return clampf(requested * size_scale, min_scale, max_scale)

func rect_inside_safe(rect: Rect2, viewport_size: Vector2, layout: Dictionary = {}) -> bool:
	return safe_rect(viewport_size, layout).encloses(rect)

