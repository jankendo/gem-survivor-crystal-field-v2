extends RefCounted
class_name CurrencySinkSystem

const COST_GROWTH := 1.35
const ShopEntitlementSystemScript = preload("res://scripts/systems/ShopEntitlementSystem.gd")

var categories: Dictionary = {}
var sinks: Dictionary = {}
var progress_tracker = preload("res://scripts/systems/ProgressTrackerSystem.gd").new()
var entitlement_system = ShopEntitlementSystemScript.new()

func _init() -> void:
	categories = _json_dict("res://data/shop_categories.json")
	sinks = _json_dict("res://data/currency_sinks.json")
	var generated := entitlement_system.generated_currency_sinks(sinks)
	for id in generated.keys():
		sinks[String(id)] = generated[id]

func category_ids() -> Array:
	var ids = categories.keys()
	ids.sort_custom(func(a, b): return int(categories[a].get("order", 0)) < int(categories[b].get("order", 0)))
	return ids

func items_for_category(category_id: String) -> Array:
	var result: Array = []
	for raw_id in sinks.keys():
		var id = String(raw_id)
		if String(sinks[id].get("category", "")) == category_id:
			var row: Dictionary = sinks[id].duplicate(true)
			row["id"] = id
			result.append(row)
	return result

func current_level(save_data: Dictionary, sink_id: String) -> int:
	return int(save_data.get("currency_sink_levels", {}).get(sink_id, 0))

func cost_for(sink_id: String, current: int) -> int:
	var base = int(sinks.get(sink_id, {}).get("base_cost", 100))
	return maxi(1, int(round(float(base) * pow(COST_GROWTH, float(current)))))

func condition_met(save_data: Dictionary, sink_id: String) -> bool:
	var data: Dictionary = sinks.get(sink_id, {})
	var kind := _kind_for_category(String(data.get("category", "")))
	var target := String(data.get("target", ""))
	if kind != "" and target != "" and not entitlement_system.is_available_for_purchase(save_data, kind, target):
		return false
	var key = String(data.get("required_stat", ""))
	if key == "":
		return true
	return float(save_data.get("stats", {}).get(key, 0.0)) >= float(data.get("required_value", 0.0))

func purchase(save: SaveSystem, sink_id: String) -> bool:
	var data: Dictionary = sinks.get(sink_id, {})
	if data.is_empty():
		return false
	var save_data = save.load_data()
	var levels: Dictionary = save_data.get("currency_sink_levels", {})
	var current = int(levels.get(sink_id, 0))
	if current >= int(data.get("max_level", 1)) or not condition_met(save_data, sink_id):
		return false
	var kind := _kind_for_category(String(data.get("category", "")))
	var target := String(data.get("target", ""))
	if kind != "" and target != "" and entitlement_system.is_usable(save_data, kind, target):
		return false
	var cost = cost_for(sink_id, current)
	if int(save_data.get("crystal_currency", 0)) < cost:
		return false
	save_data["crystal_currency"] = int(save_data.get("crystal_currency", 0)) - cost
	levels[sink_id] = current + 1
	save_data["currency_sink_levels"] = levels
	_apply_unlock(save_data, data)
	if sink_id == "weapon_disable_slots":
		save_data["weapon_disable_slots"] = mini(10, 2 + int(levels[sink_id]))
	elif sink_id == "passive_disable_slots":
		save_data["passive_disable_slots"] = mini(10, 2 + int(levels[sink_id]))
	save.save_data(save_data)
	return true

func progress_text(save_data: Dictionary, sink_id: String) -> String:
	var data: Dictionary = sinks.get(sink_id, {})
	var required_stat := String(data.get("required_stat", ""))
	if required_stat == "":
		return "解放条件：達成済み"
	return progress_tracker.progress_text(save_data, {
		"type": required_stat,
		"value": data.get("required_value", 0)
	})

func apply_to_state(state, save_data: Dictionary) -> void:
	state.currency_sink_levels = save_data.get("currency_sink_levels", {}).duplicate(true)
	var levels: Dictionary = state.currency_sink_levels
	state.meta_magnet_mult *= 1.0 + 0.02 * float(levels.get("scanner_range", 0))
	state.meta_crystal_damage_mult *= 1.0 + 0.015 * float(levels.get("forge_crystal", 0))

func total_remaining_cost(save_data: Dictionary) -> int:
	var total = 0
	for raw_id in sinks.keys():
		var id = String(raw_id)
		var current = current_level(save_data, id)
		var max_level = int(sinks[id].get("max_level", 1))
		for level in range(current, max_level):
			total += cost_for(id, level)
	return total

func _apply_unlock(save_data: Dictionary, data: Dictionary) -> void:
	var category = String(data.get("category", ""))
	var target = String(data.get("target", ""))
	if target == "":
		return
	var key = ""
	if category == "weapon_license":
		key = "unlocked_weapons"
	elif category == "passive_license":
		key = "unlocked_passives"
	elif category == "blessings":
		key = "unlocked_blessings"
	if key != "":
		entitlement_system.mark_purchased(save_data, _kind_for_category(category), target)

func _kind_for_category(category: String) -> String:
	match category:
		"weapon_license":
			return "weapon"
		"passive_license":
			return "passive"
		"blessings":
			return "blessing"
	return ""

func _json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
	return parsed if parsed is Dictionary else {}
