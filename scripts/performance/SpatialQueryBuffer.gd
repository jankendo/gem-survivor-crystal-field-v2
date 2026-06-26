extends RefCounted
class_name SpatialQueryBuffer

var items: Array = []

func clear() -> void:
	items.clear()

func append(value) -> void:
	items.append(value)

func size() -> int:
	return items.size()

func is_empty() -> bool:
	return items.is_empty()

func values() -> Array:
	return items

