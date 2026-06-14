extends RefCounted
class_name IosSafeAreaGuardSystem

func violations(named_rects: Dictionary, safe_rect: Rect2) -> Array:
	var result: Array = []
	for name in named_rects:
		var rect: Rect2 = named_rects[name]
		if not safe_rect.encloses(rect):
			result.append(String(name))
	return result

func clamp_rect(rect: Rect2, safe_rect: Rect2) -> Rect2:
	var size := Vector2(minf(rect.size.x, safe_rect.size.x), minf(rect.size.y, safe_rect.size.y))
	var position := Vector2(
		clampf(rect.position.x, safe_rect.position.x, safe_rect.end.x - size.x),
		clampf(rect.position.y, safe_rect.position.y, safe_rect.end.y - size.y)
	)
	return Rect2(position, size)
