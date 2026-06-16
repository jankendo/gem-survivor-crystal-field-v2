extends RefCounted
class_name FieldEquipmentMapIconSystem

func icons_for_state(state) -> Array:
	var icons: Array = []
	for equipment in state.field_equipment:
		if bool(equipment.get("collected", false)):
			continue
		icons.append({
			"label": String(equipment.get("name_ja", equipment.get("id", ""))),
			"icon": String(equipment.get("icon", "W")),
			"position": equipment.get("position", Vector2.ZERO),
			"color": _color(equipment),
			"priority": int(equipment.get("priority", 5))
		})
	return icons

func _color(data: Dictionary) -> Color:
	var values: Array = data.get("color", [0.72, 0.92, 1.0])
	if values.size() >= 3:
		return Color(float(values[0]), float(values[1]), float(values[2]))
	return Color(0.72, 0.92, 1.0)
