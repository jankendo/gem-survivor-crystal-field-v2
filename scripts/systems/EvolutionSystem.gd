extends RefCounted
class_name EvolutionSystem

func available_evolutions(state) -> Array:
	var results: Array = []
	for raw_id in state.evolution_defs.keys():
		var evolution_id = String(raw_id)
		var data = state.evolution_defs[evolution_id]
		var weapon_id = String(data.get("weapon", ""))
		var passive_id = String(data.get("passive", ""))
		if weapon_id == "" or passive_id == "":
			continue
		if state.is_weapon_evolved(weapon_id):
			continue
		if int(state.weapons.get(weapon_id, 0)) < int(data.get("weapon_level", 8)):
			continue
		if int(state.passives.get(passive_id, 0)) < int(data.get("passive_level", 1)):
			continue
		var copy = data.duplicate(true)
		copy["id"] = evolution_id
		results.append(copy)
	return results

func apply_first_available_evolution(state, events: Array) -> bool:
	var candidates = available_evolutions(state)
	if candidates.is_empty():
		return false
	return _apply_evolution(state, candidates[0], events)

func can_evolve_magic_bolt(state) -> bool:
	if state.is_weapon_evolved("magic_bolt"):
		return false
	var evolution = state.evolution_for_weapon("magic_bolt")
	if evolution.is_empty():
		return false
	return int(state.weapons.get("magic_bolt", 0)) >= int(evolution.get("weapon_level", 8)) and int(state.passives.get(String(evolution.get("passive", "")), 0)) >= int(evolution.get("passive_level", 1))

func apply_magic_bolt_evolution(state, events: Array) -> bool:
	if not can_evolve_magic_bolt(state):
		return false
	return _apply_evolution(state, state.evolution_for_weapon("magic_bolt"), events)

func _apply_evolution(state, evolution: Dictionary, events: Array) -> bool:
	var weapon_id = String(evolution.get("weapon", ""))
	var evolution_id = String(evolution.get("id", ""))
	if weapon_id == "" or evolution_id == "":
		return false
	state.evolved_weapons[weapon_id] = evolution_id
	if weapon_id == "magic_bolt":
		state.evolved_magic_bolt = true
	state.evolved_weapon_count = state.evolved_weapons.keys().size()
	var name = String(evolution.get("name_ja", state.weapon_name(weapon_id)))
	state.message = "%sへ進化！" % name
	events.append({"type": "evolution", "weapon": weapon_id, "evolution": evolution_id, "name": name})
	return true
