extends RefCounted
class_name FieldEquipmentRewardSystem

var placement = preload("res://scripts/systems/FieldEquipmentPlacementSystem.gd").new()

func generate_for_map(state, map_data: Dictionary, rng) -> Array:
	return placement.generate(state, map_data, rng)

func sanitize_for_state(state, rng = null) -> Dictionary:
	var used_items: Array = []
	var kept := 0
	var replaced := 0
	var conversion_only := 0
	for equipment in state.field_equipment:
		if not equipment is Dictionary:
			continue
		var kind := String(equipment.get("kind", "weapon"))
		var item_id := String(equipment.get("id", ""))
		var key := "%s:%s" % [kind, item_id]
		if not bool(equipment.get("collected", false)) and placement.is_id_run_available(state, kind, item_id) and not used_items.has(key):
			used_items.append(key)
			kept += 1
			continue
		var replacement := placement.replacement_for(state, kind, used_items, rng if rng != null else state.rng)
		if not replacement.is_empty():
			var new_id := String(replacement.get("id", ""))
			equipment["id"] = new_id
			equipment["kind"] = kind
			equipment["name_ja"] = "%s：%s" % ["武器" if kind == "weapon" else "パッシブ", state.weapon_name(new_id) if kind == "weapon" else state.passive_name(new_id)]
			equipment["icon"] = String(replacement.get("icon", "W" if kind == "weapon" else "P"))
			equipment["color"] = replacement.get("color", [0.72, 0.92, 1.0])
			equipment["pending"] = false
			equipment["collected"] = false
			equipment.erase("invalid_conversion_only")
			used_items.append("%s:%s" % [kind, new_id])
			replaced += 1
		else:
			equipment["invalid_conversion_only"] = true
			equipment["pending"] = false
			conversion_only += 1
	state.field_equipment_sanitized_count += replaced
	state.field_equipment_conversion_only_count += conversion_only
	return {"kept": kept, "replaced": replaced, "conversion_only": conversion_only}

func exploration_reward_score(state) -> int:
	var chain_bonus = int(state.exploration_chain_max) * 80
	var equipment_bonus = int(state.field_equipment_collected) * 450
	var room_bonus = int(state.reward_room_pickups) * 240
	return chain_bonus + equipment_bonus + room_bonus

func camping_score_estimate(minutes: float) -> int:
	return int(minutes * 120.0)
