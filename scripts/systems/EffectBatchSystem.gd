extends RefCounted
class_name EffectBatchSystem

func visible_items(items: Array, camera_position: Vector2, visible_size: Vector2, margin: float = 96.0) -> Array:
	var rect := Rect2(camera_position - visible_size * 0.5, visible_size).grow(margin)
	var result: Array = []
	for item in items:
		var pos: Vector2 = item.get("pos", item.get("position", item.get("start", camera_position)))
		var end: Vector2 = item.get("end", pos)
		if rect.has_point(pos) or rect.has_point(end):
			result.append(item)
	return result

func merge_damage_numbers(items: Array, grid_size: float = 48.0) -> Array:
	var merged: Dictionary = {}
	var passthrough: Array = []
	for item in items:
		var text := String(item.get("text", ""))
		if not text.is_valid_int():
			passthrough.append(item)
			continue
		var pos: Vector2 = item.get("pos", Vector2.ZERO)
		var key := Vector2i(floori(pos.x / grid_size), floori(pos.y / grid_size))
		if not merged.has(key):
			merged[key] = item
		else:
			merged[key]["text"] = str(int(merged[key]["text"]) + int(text))
			merged[key]["life"] = maxf(float(merged[key].get("life", 0.0)), float(item.get("life", 0.0)))
	passthrough.append_array(merged.values())
	return passthrough
