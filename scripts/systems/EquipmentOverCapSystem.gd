extends RefCounted
class_name EquipmentOverCapSystem

var capacity = preload("res://scripts/systems/EquipmentCapacitySystem.gd").new()

func grant(state, kind: String, id: String, events: Array, source: String = "level_up", allow_over_cap: bool = false) -> bool:
	if not capacity.can_take(state, kind, id, allow_over_cap):
		return false
	if kind == "weapon":
		var before := int(state.weapons.get(id, 0))
		var was_new := before <= 0
		var over_cap_new: bool = was_new and state.weapons.size() >= capacity.normal_cap(state, "weapon")
		state.weapons[id] = before + 1
		state.weapon_pick_counts[id] = int(state.weapon_pick_counts.get(id, 0)) + 1
		if over_cap_new:
			state.field_weapon_over_cap_ids.append(id)
			state.field_over_cap_pickups += 1
		events.append({"type": "equipment_grant", "kind": kind, "id": id, "source": source, "level": int(state.weapons[id]), "over_cap": over_cap_new})
		return true
	if kind == "passive":
		var before_passive := int(state.passives.get(id, 0))
		var was_new_passive := before_passive <= 0
		var over_cap_new_passive: bool = was_new_passive and state.passives.size() >= capacity.normal_cap(state, "passive")
		state.passives[id] = before_passive + 1
		state.passive_pick_counts[id] = int(state.passive_pick_counts.get(id, 0)) + 1
		if id == "max_hp":
			state.max_hp += 18
			state.hp = mini(state.max_hp, state.hp + 18)
		if over_cap_new_passive:
			state.field_passive_over_cap_ids.append(id)
			state.field_over_cap_pickups += 1
		events.append({"type": "equipment_grant", "kind": kind, "id": id, "source": source, "level": int(state.passives[id]), "over_cap": over_cap_new_passive})
		return true
	return false
