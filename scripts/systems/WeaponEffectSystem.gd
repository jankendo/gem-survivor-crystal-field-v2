extends RefCounted
class_name WeaponEffectSystem

func effect_for(state, weapon_id: String, evolved: bool = false) -> Dictionary:
	var data: Dictionary = state.weapon_effect_defs.get(weapon_id, {})
	if data.is_empty():
		return {}
	var result: Dictionary = data.get("evolved", {}) if evolved else data.get("normal", {})
	result = result.duplicate(true)
	for key in ["effect_type", "primary_color", "secondary_color", "hit_effect", "evolved_effect_type", "screen_priority", "opacity", "lifetime", "max_effect_count", "melee_arc", "lightning_line", "shock_icon"]:
		if data.has(key) and not result.has(key):
			result[key] = data[key]
	return result

func has_required_visibility(data: Dictionary) -> bool:
	for key in ["effect_type", "primary_color", "secondary_color", "hit_effect", "evolved_effect_type", "screen_priority", "opacity", "lifetime", "max_effect_count"]:
		if not data.has(key):
			return false
	return data.has("normal") and data.has("evolved")

