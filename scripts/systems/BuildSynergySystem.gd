extends RefCounted
class_name BuildSynergySystem

func process(state, events: Array = []) -> void:
	var tag_counts = build_tag_counts(state)
	var active = {}
	for raw_id in state.build_synergy_defs.keys():
		var id = String(raw_id)
		var def: Dictionary = state.build_synergy_defs[id]
		if _requirements_met(def, tag_counts):
			active[id] = def
	state.build_tag_counts = tag_counts
	for id in active.keys():
		if not state.active_synergies.has(id):
			state.active_synergy_history.append(id)
			events.append({"type": "build_synergy", "id": id, "name": String(active[id].get("name_ja", id))})
	state.active_synergies = active

func build_tag_counts(state) -> Dictionary:
	var counts = {}
	for weapon_id in state.weapons.keys():
		_add_tags(counts, state.weapon_tags(String(weapon_id)))
	for passive_id in state.passives.keys():
		_add_passive_tag(counts, String(passive_id))
	var char_tags: Dictionary = state.character_modifiers.get("tag_damage", {})
	for tag in char_tags.keys():
		counts[String(tag)] = int(counts.get(String(tag), 0)) + 1
	if state.selected_character_id == "atlas":
		counts["defense"] = int(counts.get("defense", 0)) + 1
	return counts

func would_complete_synergy(state, kind: String, id: String) -> String:
	var counts = build_tag_counts(state)
	if kind == "weapon":
		_add_tags(counts, state.weapon_defs.get(id, {}).get("tags", []))
	elif kind == "passive":
		_add_passive_tag(counts, id)
	for raw_id in state.build_synergy_defs.keys():
		var synergy_id = String(raw_id)
		if state.active_synergies.has(synergy_id):
			continue
		var def: Dictionary = state.build_synergy_defs[synergy_id]
		if _requirements_met(def, counts):
			return String(def.get("name_ja", synergy_id))
	return ""

func _add_tags(counts: Dictionary, tags: Array) -> void:
	for raw_tag in tags:
		var tag = String(raw_tag)
		counts[tag] = int(counts.get(tag, 0)) + 1

func _add_passive_tag(counts: Dictionary, passive_id: String) -> void:
	match passive_id:
		"curse":
			counts["curse"] = int(counts.get("curse", 0)) + 1
		"armor", "max_hp", "regen", "revival":
			counts["defense"] = int(counts.get("defense", 0)) + 1
		"crystal_breaker":
			counts["crystal"] = int(counts.get("crystal", 0)) + 1
		"magnet", "greed":
			counts["gem"] = int(counts.get("gem", 0)) + 1

func _requirements_met(def: Dictionary, counts: Dictionary) -> bool:
	var req: Dictionary = def.get("requirements", {})
	for tag in req.keys():
		if int(counts.get(String(tag), 0)) < int(req[tag]):
			return false
	if def.has("requirements_any_total"):
		var any_req: Dictionary = def["requirements_any_total"]
		var total = 0
		for raw_tag in any_req.get("tags", []):
			total += int(counts.get(String(raw_tag), 0))
		if total < int(any_req.get("count", 1)):
			return false
	return true

