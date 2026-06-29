extends RefCounted
class_name FieldObjectAvailabilitySystem

func is_available_now(state, object, terminal_key: String = "collected") -> bool:
	if object == null:
		return false
	if object is Dictionary:
		if bool(object.get(terminal_key, false)):
			return false
		if bool(object.get("pending", false)):
			return false
		return float(state.elapsed_seconds) >= float(object.get("unlock_seconds", 0.0))
	return false

func available_drops(state) -> Array:
	return state.field_drops.filter(func(item): return is_available_now(state, item, "collected"))

func available_equipment(state) -> Array:
	return state.field_equipment.filter(func(item): return is_available_now(state, item, "collected"))

func available_gimmicks(state) -> Array:
	return state.field_gimmicks.filter(func(item): return is_available_now(state, item, "destroyed"))
