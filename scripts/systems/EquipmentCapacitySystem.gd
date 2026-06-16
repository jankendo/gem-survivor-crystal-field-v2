extends RefCounted
class_name EquipmentCapacitySystem

func normal_cap(state, kind: String) -> int:
	if kind == "weapon":
		return int(state.balance_data.get("normal_owned_weapons_cap", state.balance_data.get("max_owned_weapons", 5)))
	return int(state.balance_data.get("normal_owned_passives_cap", state.balance_data.get("max_owned_passives", 5)))

func max_total_cap(state, kind: String) -> int:
	return normal_cap(state, kind) + int(state.balance_data.get("field_over_cap_max_bonus", 3))

func over_cap_count(state, kind: String) -> int:
	var count: int = state.weapons.size() if kind == "weapon" else state.passives.size()
	return maxi(0, count - normal_cap(state, kind))

func display_text(state, kind: String) -> String:
	var count: int = state.weapons.size() if kind == "weapon" else state.passives.size()
	var cap := normal_cap(state, kind)
	var extra := maxi(0, count - cap)
	return "%d/%d%s" % [count, cap, " +%d" % extra if extra > 0 else ""]

func can_take(state, kind: String, id: String, allow_over_cap: bool = false) -> bool:
	if id == "":
		return false
	var owned: Dictionary = state.weapons if kind == "weapon" else state.passives
	var defs: Dictionary = state.weapon_defs if kind == "weapon" else state.passive_defs
	var max_level := int(defs.get(id, {}).get("max_level", 8 if kind == "weapon" else 5))
	if kind == "weapon" and state.is_weapon_evolved(id):
		return false
	if int(owned.get(id, 0)) > 0:
		return int(owned.get(id, 0)) < max_level
	if kind == "weapon":
		if state.disabled_weapon_ids.has(id):
			return false
		if not state.unlocked_weapon_ids.is_empty() and not state.unlocked_weapon_ids.has(id):
			return false
	else:
		if state.disabled_passive_ids.has(id):
			return false
		if not state.unlocked_passive_ids.is_empty() and not state.unlocked_passive_ids.has(id):
			return false
	if state.run_sealed_option_uids.has("%s:%s" % [kind, id]):
		return false
	if owned.size() < normal_cap(state, kind):
		return true
	return allow_over_cap and bool(state.balance_data.get("field_pickup_can_exceed_cap", true)) and owned.size() < max_total_cap(state, kind)
