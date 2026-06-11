extends RefCounted
class_name OverclockSystem

func available_overclocks(state) -> Array:
	var results: Array = []
	if not state.overclock_timing_ready():
		return results
	for weapon_id in state.evolved_weapons.keys():
		if state.overclock_count(String(weapon_id)) >= int(state.balance_data.get("overclock_max_per_weapon", 2)):
			continue
		var evolution_id = String(state.evolved_weapons[weapon_id])
		for entry in state.overclock_defs.get(evolution_id, []):
			var id = String(entry.get("id", ""))
			if id == "" or state.has_overclock(String(weapon_id), id):
				continue
			var option = entry.duplicate(true)
			option["weapon"] = String(weapon_id)
			option["evolution"] = evolution_id
			results.append(option)
	return results

func make_options(state, count: int = 3) -> Array:
	var candidates = state.rng.shuffled(available_overclocks(state))
	var options: Array = []
	for entry in candidates:
		if options.size() >= count:
			break
		options.append({
			"uid": "overclock:%s:%s" % [String(entry.get("weapon", "")), String(entry.get("id", ""))],
			"kind": "overclock",
			"id": String(entry.get("id", "")),
			"weapon": String(entry.get("weapon", "")),
			"evolution": String(entry.get("evolution", "")),
			"name_ja": String(entry.get("name_ja", "")),
			"description_ja": "%s / 対象：%s" % [String(entry.get("description_ja", "")), state.weapon_name(String(entry.get("weapon", "")))],
			"type_label": "過充電",
			"type_color": "overclock"
		})
	return options

func apply_option(state, weapon_id: String, overclock_id: String, events: Array) -> bool:
	if weapon_id == "" or overclock_id == "":
		return false
	if not state.overclock_timing_ready():
		return false
	if not state.evolved_weapons.has(weapon_id):
		return false
	if state.overclock_count(weapon_id) >= int(state.balance_data.get("overclock_max_per_weapon", 2)) or state.has_overclock(weapon_id, overclock_id):
		return false
	var evolution_id = String(state.evolved_weapons[weapon_id])
	var valid = false
	var name = overclock_id
	for entry in state.overclock_defs.get(evolution_id, []):
		if String(entry.get("id", "")) == overclock_id:
			valid = true
			name = String(entry.get("name_ja", overclock_id))
			break
	if not valid:
		return false
	if not state.overclocks.has(weapon_id):
		state.overclocks[weapon_id] = []
	state.overclocks[weapon_id].append(overclock_id)
	state.message = "%s 過充電！" % name
	events.append({"type": "overclock", "weapon": weapon_id, "id": overclock_id, "name": name})
	return true
