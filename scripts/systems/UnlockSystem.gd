extends RefCounted
class_name UnlockSystem

var weapon_unlocks: Dictionary = {}
var passive_unlocks: Dictionary = {}

func _init() -> void:
	weapon_unlocks = _json_dict("res://data/weapon_unlocks.json")
	passive_unlocks = _json_dict("res://data/passive_unlocks.json")

func initial_weapon_ids() -> Array:
	return _initial_ids(weapon_unlocks)

func initial_passive_ids() -> Array:
	return _initial_ids(passive_unlocks)

func apply_to_state(state, save_data: Dictionary) -> void:
	state.unlocked_weapon_ids = (save_data.get("unlocked_weapons", initial_weapon_ids()) as Array).duplicate()
	state.unlocked_passive_ids = (save_data.get("unlocked_passives", initial_passive_ids()) as Array).duplicate()

func update_after_run(save_data: Dictionary) -> Dictionary:
	var new_weapons = _unlock_table(save_data, "unlocked_weapons", weapon_unlocks)
	var new_passives = _unlock_table(save_data, "unlocked_passives", passive_unlocks)
	return {"weapons": new_weapons, "passives": new_passives}

func is_weapon_unlocked(save_data: Dictionary, id: String) -> bool:
	return (save_data.get("unlocked_weapons", initial_weapon_ids()) as Array).has(id)

func is_passive_unlocked(save_data: Dictionary, id: String) -> bool:
	return (save_data.get("unlocked_passives", initial_passive_ids()) as Array).has(id)

func unlock_text(kind: String, id: String) -> String:
	var source = weapon_unlocks if kind == "weapons" else passive_unlocks
	return String(source.get(id, {}).get("text_ja", "解放条件なし"))

func _unlock_table(save_data: Dictionary, save_key: String, defs: Dictionary) -> Array:
	var unlocked: Array = save_data.get(save_key, _initial_ids(defs))
	var newly: Array = []
	for raw_id in defs.keys():
		var id = String(raw_id)
		if unlocked.has(id):
			continue
		var def: Dictionary = defs[id]
		if _condition_met(save_data, def.get("condition", {})):
			unlocked.append(id)
			newly.append(id)
	save_data[save_key] = unlocked
	return newly

func _condition_met(save_data: Dictionary, condition: Dictionary) -> bool:
	if condition.is_empty():
		return false
	var type = String(condition.get("type", ""))
	var stats: Dictionary = save_data.get("stats", {})
	match type:
		"total_kills":
			return int(stats.get("total_kills", 0)) >= int(condition.get("value", 0))
		"total_crystals":
			return int(stats.get("total_crystals", 0)) >= int(condition.get("value", 0))
		"total_chests":
			return int(stats.get("total_chests", 0)) >= int(condition.get("value", 0))
		"total_currency_earned":
			return int(stats.get("total_currency_earned", 0)) >= int(condition.get("value", 0))
		"survive_seconds":
			return float(stats.get("best_survival", 0.0)) >= float(condition.get("value", 0.0))
		"survive_runs":
			return int(stats.get("survive_10_runs", 0)) >= int(condition.get("value", 1))
		"danger_time":
			return float(stats.get("best_danger_time", 0.0)) >= float(condition.get("value", 0.0))
		"max_combo":
			return int(stats.get("max_combo", 0)) >= int(condition.get("value", 0))
		"weapon_level":
			return int(save_data.get("weapon_highest_levels", {}).get(String(condition.get("weapon", "")), 0)) >= int(condition.get("level", 1))
		"boss_defeat":
			return bool(save_data.get("boss_defeats", {}).get(String(condition.get("boss", "")), false))
		"character_unlocked":
			return (save_data.get("unlocked_characters", []) as Array).has(String(condition.get("character", "")))
		"shortcut_walls":
			return int(stats.get("shortcut_walls_broken", 0)) >= int(condition.get("value", 0))
		"rooms_discovered":
			return int(stats.get("rooms_discovered", 0)) >= int(condition.get("value", 0))
		"cursed_relics":
			return int(stats.get("cursed_relics", 0)) >= int(condition.get("value", 0))
		"field_event_successes":
			return int(stats.get("field_event_successes", 0)) >= int(condition.get("value", 0))
		"low_hp_time":
			return float(stats.get("low_hp_time", 0.0)) >= float(condition.get("value", 0.0))
		"terrain_time":
			return float(stats.get("terrain_time", {}).get(String(condition.get("terrain", "")), 0.0)) >= float(condition.get("value", 0.0))
		"terrain_kills":
			return int(stats.get("terrain_kills", {}).get(String(condition.get("terrain", "")), 0)) >= int(condition.get("value", 0))
		"exploration_rank":
			return _rank_value(String(stats.get("best_exploration_rank", "D"))) >= _rank_value(String(condition.get("rank", condition.get("value", "D"))))
		"exploration_chain":
			return int(stats.get("max_exploration_chain", 0)) >= int(condition.get("value", 0))
		"gimmicks_triggered":
			return int(stats.get("field_gimmicks_triggered", 0)) >= int(condition.get("value", 0))
		"gimmick_count":
			return int(stats.get("field_gimmicks_triggered", 0)) >= int(condition.get("value", 0))
	return false

func _rank_value(rank: String) -> int:
	return ["D", "C", "B", "A", "S", "SS"].find(rank)

func _initial_ids(defs: Dictionary) -> Array:
	var result: Array = []
	for raw_id in defs.keys():
		if bool(defs[raw_id].get("initial", false)):
			result.append(String(raw_id))
	return result

func _json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
	return parsed if parsed is Dictionary else {}
