extends RefCounted
class_name ShopRerollSystem

const CurrencySinkSystemScript = preload("res://scripts/systems/CurrencySinkSystem.gd")
const MetaProgressionSystemScript = preload("res://scripts/systems/MetaProgressionSystem.gd")
const RunRngScript = preload("res://scripts/core/RunRng.gd")

var config: Dictionary = {}
var currency_sinks = CurrencySinkSystemScript.new()
var meta_system = MetaProgressionSystemScript.new()

func _init() -> void:
	config = _json_dict("res://data/shop_reroll.json", {
		"featured_slot_count": 4,
		"free_rerolls_per_cycle": 1,
		"costs": [0, 50, 100, 200, 400],
		"max_rerolls_per_cycle": 8,
		"avoid_duplicate_items": true,
		"guarantee_affordable_item": true,
		"save_seed_default": 314159
	})

func ensure_featured(save: SaveSystem) -> Dictionary:
	var data = save.load_data()
	var changed = false
	if not data.has("shop_save_seed") or int(data.get("shop_save_seed", 0)) == 0:
		data["shop_save_seed"] = int(config.get("save_seed_default", 314159))
		changed = true
	if not data.has("shop_cycle_id"):
		data["shop_cycle_id"] = 0
		changed = true
	if not data.has("shop_reroll_count"):
		data["shop_reroll_count"] = 0
		changed = true
	if not data.has("shop_featured_items") or (data.get("shop_featured_items", []) as Array).is_empty():
		data["shop_featured_items"] = generate_featured(data)
		changed = true
	if changed:
		save.save_data(data)
	return data

func advance_cycle(save: SaveSystem) -> void:
	var data = save.load_data()
	data["shop_cycle_id"] = int(data.get("shop_cycle_id", 0)) + 1
	data["shop_reroll_count"] = 0
	data["shop_featured_items"] = generate_featured(data)
	save.save_data(data)

func can_reroll(save_data: Dictionary) -> bool:
	var count = int(save_data.get("shop_reroll_count", 0))
	if count >= int(config.get("max_rerolls_per_cycle", 8)):
		return false
	return int(save_data.get("crystal_currency", 0)) >= cost_for_count(count)

func cost_for_count(current_reroll_count: int) -> int:
	var costs: Array = config.get("costs", [0, 50, 100, 200, 400])
	if costs.is_empty():
		return 0
	return int(costs[mini(current_reroll_count, costs.size() - 1)])

func free_rerolls_remaining(save_data: Dictionary) -> int:
	return maxi(0, int(config.get("free_rerolls_per_cycle", 1)) - int(save_data.get("shop_reroll_count", 0)))

func reroll(save: SaveSystem) -> Dictionary:
	var data = ensure_featured(save)
	var current_count = int(data.get("shop_reroll_count", 0))
	if current_count >= int(config.get("max_rerolls_per_cycle", 8)):
		return {"ok": false, "reason": "limit", "data": data}
	var cost = cost_for_count(current_count)
	if int(data.get("crystal_currency", 0)) < cost:
		return {"ok": false, "reason": "currency", "data": data}
	data["crystal_currency"] = int(data.get("crystal_currency", 0)) - cost
	data["shop_reroll_count"] = current_count + 1
	data["shop_featured_items"] = generate_featured(data)
	save.save_data(data)
	return {"ok": true, "cost": cost, "items": data["shop_featured_items"], "data": data}

func generate_featured(save_data: Dictionary) -> Array:
	var rng = _rng_for(save_data)
	var candidates = _candidates(save_data)
	var result: Array = []
	var used: Array = []
	var slot_count = int(config.get("featured_slot_count", 4))
	var affordable = _affordable_candidates(candidates, save_data)
	if bool(config.get("guarantee_affordable_item", true)) and not affordable.is_empty():
		var first: Dictionary = rng.weighted_choice(affordable)
		result.append(first)
		used.append(String(first.get("uid", "")))
	while result.size() < slot_count and not candidates.is_empty():
		var chosen: Dictionary = rng.weighted_choice(candidates)
		var uid = String(chosen.get("uid", ""))
		if uid == "":
			break
		if bool(config.get("avoid_duplicate_items", true)) and used.has(uid):
			_remove_candidate(candidates, uid)
			continue
		result.append(chosen)
		used.append(uid)
		_remove_candidate(candidates, uid)
	return result

func featured_text(save_data: Dictionary) -> String:
	var items: Array = save_data.get("shop_featured_items", [])
	var names: Array = []
	for item in items:
		names.append(String(item.get("name_ja", item.get("id", ""))))
	return " / ".join(names)

func _rng_for(save_data: Dictionary):
	var base = RunRngScript.new()
	base.set_seed_value(int(save_data.get("shop_save_seed", config.get("save_seed_default", 314159))))
	var salt = "%d:%d" % [int(save_data.get("shop_cycle_id", 0)), int(save_data.get("shop_reroll_count", 0))]
	return base.stream_rng("shop_featured", salt)

func _candidates(save_data: Dictionary) -> Array:
	var result: Array = []
	for id in meta_system.character_ids():
		var character_id = String(id)
		var data: Dictionary = meta_system.character_data(character_id)
		var cost = int(data.get("unlock_cost", 0))
		if cost <= 0 or meta_system.is_character_unlocked(save_data, character_id):
			continue
		result.append({
			"uid": "character:%s" % character_id,
			"kind": "character",
			"id": character_id,
			"name_ja": meta_system.display_name(character_id, save_data),
			"description_ja": String(data.get("role_ja", "")),
			"cost": cost,
			"weight": 1.25 if int(save_data.get("crystal_currency", 0)) >= cost else 0.55
		})
	for id in meta_system.upgrades.keys():
		var upgrade_id = String(id)
		var data: Dictionary = meta_system.upgrades[upgrade_id]
		var levels: Dictionary = save_data.get("meta_upgrades", {})
		var current = int(levels.get(upgrade_id, 0))
		if current >= int(data.get("max_level", 1)):
			continue
		var cost = meta_system.upgrade_cost(upgrade_id, current)
		result.append({
			"uid": "meta:%s" % upgrade_id,
			"kind": "meta",
			"id": upgrade_id,
			"name_ja": String(data.get("name_ja", upgrade_id)),
			"description_ja": String(data.get("description_ja", "")),
			"cost": cost,
			"level": current,
			"max_level": int(data.get("max_level", 1)),
			"weight": 1.5 if int(save_data.get("crystal_currency", 0)) >= cost else 0.65
		})
	for category_id in currency_sinks.category_ids():
		for item in currency_sinks.items_for_category(String(category_id)):
			var sink_id = String(item.get("id", ""))
			var current = currency_sinks.current_level(save_data, sink_id)
			if current >= int(item.get("max_level", 1)):
				continue
			if not currency_sinks.condition_met(save_data, sink_id):
				continue
			var cost = currency_sinks.cost_for(sink_id, current)
			result.append({
				"uid": "sink:%s" % sink_id,
				"kind": "sink",
				"id": sink_id,
				"name_ja": String(item.get("name_ja", sink_id)),
				"description_ja": String(item.get("description_ja", "")),
				"cost": cost,
				"level": current,
				"max_level": int(item.get("max_level", 1)),
				"weight": 1.35 if int(save_data.get("crystal_currency", 0)) >= cost else 0.55
			})
	return result

func _affordable_candidates(candidates: Array, save_data: Dictionary) -> Array:
	var result: Array = []
	var currency = int(save_data.get("crystal_currency", 0))
	for item in candidates:
		if int(item.get("cost", 0)) <= currency:
			result.append(item)
	return result

func _remove_candidate(candidates: Array, uid: String) -> void:
	for i in range(candidates.size() - 1, -1, -1):
		if String(candidates[i].get("uid", "")) == uid:
			candidates.remove_at(i)

func _json_dict(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback.duplicate(true)
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else fallback.duplicate(true)
