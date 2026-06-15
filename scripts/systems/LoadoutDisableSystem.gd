extends RefCounted
class_name LoadoutDisableSystem

const BASE_SLOTS := 2
const MAX_SLOTS := 10
const MIN_ACTIVE_WEAPONS := 4
const MIN_ACTIVE_PASSIVES := 4

func slots_for(save_data: Dictionary, kind: String) -> int:
	var levels: Dictionary = save_data.get("currency_sink_levels", {})
	var purchased := int(levels.get("weapon_disable_slots" if kind == "weapon" else "passive_disable_slots", 0))
	var stats: Dictionary = save_data.get("stats", {})
	var achievement := 0
	var unlocked_key := "unlocked_weapons" if kind == "weapon" else "unlocked_passives"
	if (save_data.get(unlocked_key, []) as Array).size() >= 20:
		achievement += 1
	if float(stats.get("best_survival", 0.0)) >= 1800.0:
		achievement += 1
	if int(stats.get("exploration_rank_count", {}).get("SS", 0)) >= 3:
		achievement += 1
	return mini(MAX_SLOTS, BASE_SLOTS + purchased + achievement)

func disabled_ids(save_data: Dictionary, kind: String) -> Array:
	return (save_data.get("disabled_weapons" if kind == "weapon" else "disabled_passives", []) as Array).duplicate()

func can_disable(save_data: Dictionary, kind: String, id: String) -> Dictionary:
	var unlocked_key := "unlocked_weapons" if kind == "weapon" else "unlocked_passives"
	var unlocked: Array = save_data.get(unlocked_key, [])
	if not unlocked.has(id):
		return {"ok": false, "reason": "未解放の項目はOFFにできません。"}
	if kind == "weapon" and id == _selected_initial_weapon(save_data):
		return {"ok": false, "reason": "選択中キャラの初期武器はOFFにできません。"}
	var disabled := disabled_ids(save_data, kind)
	if disabled.has(id):
		return {"ok": true, "reason": ""}
	if disabled.size() >= slots_for(save_data, kind):
		return {"ok": false, "reason": "OFF枠が上限です。"}
	var minimum := MIN_ACTIVE_WEAPONS if kind == "weapon" else MIN_ACTIVE_PASSIVES
	if unlocked.size() - disabled.size() - 1 < minimum:
		return {"ok": false, "reason": "候補プール保護のため、これ以上OFFにできません。"}
	if kind == "passive" and _breaks_selected_weapon_evolution(save_data, id):
		return {"ok": false, "reason": "初期武器の進化素材はOFFにできません。"}
	return {"ok": true, "reason": ""}

func set_enabled(save: SaveSystem, kind: String, id: String, enabled: bool) -> Dictionary:
	var data := save.load_data()
	var key := "disabled_weapons" if kind == "weapon" else "disabled_passives"
	var disabled: Array = data.get(key, [])
	if enabled:
		disabled.erase(id)
	else:
		var check := can_disable(data, kind, id)
		if not bool(check.get("ok", false)):
			return check
		if not disabled.has(id):
			disabled.append(id)
	data[key] = disabled
	save.save_data(data)
	return {"ok": true, "reason": "", "enabled": enabled}

func usage_text(save_data: Dictionary, kind: String) -> String:
	return "%d / %d" % [disabled_ids(save_data, kind).size(), slots_for(save_data, kind)]

func _selected_initial_weapon(save_data: Dictionary) -> String:
	var characters := _json_dict("res://data/characters.json")
	return String(characters.get(String(save_data.get("selected_character", "noah")), {}).get("initial_weapon", "magic_bolt"))

func _breaks_selected_weapon_evolution(save_data: Dictionary, passive_id: String) -> bool:
	var initial_weapon := _selected_initial_weapon(save_data)
	var evolutions := _json_dict("res://data/evolutions.json")
	for data in evolutions.values():
		if String(data.get("weapon", "")) == initial_weapon and String(data.get("passive", "")) == passive_id:
			return true
	return false

func _json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
