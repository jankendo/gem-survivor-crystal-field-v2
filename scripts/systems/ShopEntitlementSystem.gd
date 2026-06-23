extends RefCounted
class_name ShopEntitlementSystem

const ProgressTrackerSystemScript = preload("res://scripts/systems/ProgressTrackerSystem.gd")

var config: Dictionary = {}
var weapons: Dictionary = {}
var passives: Dictionary = {}
var characters: Dictionary = {}
var blessings: Dictionary = {}
var weapon_unlocks: Dictionary = {}
var passive_unlocks: Dictionary = {}
var character_unlocks: Dictionary = {}
var currency_sinks: Dictionary = {}
var progress_tracker = ProgressTrackerSystemScript.new()

func _init() -> void:
	reload()

func reload() -> void:
	config = _json_dict("res://data/shop_entitlements.json", {})
	weapons = _json_dict("res://data/weapons.json", {})
	passives = _json_dict("res://data/passives.json", {})
	characters = _json_dict("res://data/characters.json", {})
	blessings = _json_dict("res://data/blessings.json", {})
	weapon_unlocks = _json_dict("res://data/weapon_unlocks.json", {})
	passive_unlocks = _json_dict("res://data/passive_unlocks.json", {})
	character_unlocks = _json_dict("res://data/character_unlocks.json", {})
	currency_sinks = _json_dict("res://data/currency_sinks.json", {})

func starter_ids(kind: String) -> Array:
	var result: Array = []
	var source := _defs_for_kind(kind)
	var unlock_source := _unlock_defs_for_kind(kind)
	for raw_id in source.keys():
		var id := String(raw_id)
		var is_initial := false
		if kind == "blessing":
			is_initial = String(source[id].get("unlock", {}).get("type", "")) == "initial"
		elif kind == "character":
			is_initial = bool(source[id].get("initial", false)) or String(unlock_source.get(id, {}).get("type", "")) == "initial"
		else:
			is_initial = bool(unlock_source.get(id, {}).get("initial", false))
		if is_initial:
			result.append(id)
	return result

func all_ids(kind: String) -> Array:
	return _defs_for_kind(kind).keys()

func is_starter(kind: String, id: String) -> bool:
	return starter_ids(kind).has(id)

func is_purchased(save_data: Dictionary, kind: String, id: String) -> bool:
	if is_starter(kind, id):
		return true
	var purchases: Dictionary = save_data.get("shop_purchases", {})
	if bool(purchases.get(kind, {}).get(id, false)):
		return true
	var sink_id := sink_id_for(kind, id)
	if sink_id != "" and int(save_data.get("currency_sink_levels", {}).get(sink_id, 0)) > 0:
		return true
	return false

func is_usable(save_data: Dictionary, kind: String, id: String) -> bool:
	return is_starter(kind, id) or is_purchased(save_data, kind, id)

func usable_ids(save_data: Dictionary, kind: String) -> Array:
	var result: Array = []
	for raw_id in _defs_for_kind(kind).keys():
		var id := String(raw_id)
		if is_usable(save_data, kind, id):
			result.append(id)
	return result

func is_available_for_purchase(save_data: Dictionary, kind: String, id: String) -> bool:
	if id == "" or is_usable(save_data, kind, id):
		return false
	if bool(save_data.get("shop_available", {}).get(kind, {}).get(id, false)):
		return true
	var condition := condition_for(kind, id)
	return _condition_met(save_data, condition)

func can_purchase(save_data: Dictionary, kind: String, id: String) -> bool:
	if not is_available_for_purchase(save_data, kind, id):
		return false
	return int(save_data.get("crystal_currency", 0)) >= cost_for(kind, id)

func purchase_character(save, character_id: String) -> bool:
	var save_data: Dictionary = save.load_data()
	if not can_purchase(save_data, "character", character_id):
		return false
	var cost := cost_for("character", character_id)
	save_data["crystal_currency"] = int(save_data.get("crystal_currency", 0)) - cost
	mark_purchased(save_data, "character", character_id)
	_mark_collection(save_data, "characters", character_id)
	save.save_data(save_data)
	return true

func mark_purchased(save_data: Dictionary, kind: String, id: String) -> void:
	if id == "":
		return
	var purchases: Dictionary = save_data.get("shop_purchases", {})
	var kind_purchases: Dictionary = purchases.get(kind, {})
	kind_purchases[id] = true
	purchases[kind] = kind_purchases
	save_data["shop_purchases"] = purchases
	_publish_item(save_data, kind, id)
	var key := _save_key_for_kind(kind)
	if key != "":
		var values: Array = save_data.get(key, starter_ids(kind))
		if not values.has(id):
			values.append(id)
		save_data[key] = values

func publish_available_from_conditions(save_data: Dictionary) -> Dictionary:
	var newly := {"weapon": [], "passive": [], "character": [], "blessing": []}
	for kind in newly.keys():
		for raw_id in _defs_for_kind(String(kind)).keys():
			var id := String(raw_id)
			if is_starter(String(kind), id) or is_usable(save_data, String(kind), id):
				continue
			if _condition_met(save_data, condition_for(String(kind), id)):
				if _publish_item(save_data, String(kind), id):
					newly[kind].append(id)
	return newly

func migrate_save(raw_data: Dictionary) -> Dictionary:
	var data := raw_data.duplicate(true)
	var target_schema := int(config.get("save_schema_version", 3))
	data["save_schema_version"] = maxi(int(data.get("save_schema_version", 0)), target_schema)
	if not data.has("shop_purchases"):
		data["shop_purchases"] = {"weapon": {}, "passive": {}, "character": {}, "blessing": {}}
	if not data.has("shop_available"):
		data["shop_available"] = {"weapon": {}, "passive": {}, "character": {}, "blessing": {}}
	var migration_version := int(config.get("migration_version", 1))
	if int(data.get("shop_entitlement_migration_version", 0)) >= migration_version:
		_sync_usable_lists(data)
		_repair_selected(data)
		return data
	_recover_legacy_purchases_from_sinks(data)
	var relocked := {"weapon": [], "passive": [], "character": [], "blessing": []}
	for kind in ["weapon", "passive", "character", "blessing"]:
		var save_key := _save_key_for_kind(kind)
		if save_key == "":
			continue
		var current: Array = data.get(save_key, starter_ids(kind))
		var repaired: Array = []
		for starter in starter_ids(kind):
			if not repaired.has(starter):
				repaired.append(starter)
		for raw_id in current:
			var id := String(raw_id)
			if id == "" or repaired.has(id):
				continue
			if _legacy_purchase_proven(data, kind, id):
				mark_purchased(data, kind, id)
				repaired.append(id)
			else:
				_publish_item(data, kind, id)
				relocked[kind].append(id)
		data[save_key] = repaired
	_sync_usable_lists(data)
	var selected_changed := _repair_selected(data)
	data["shop_entitlement_migration_version"] = migration_version
	if _relocked_count(relocked) > 0 or selected_changed:
		data["shop_migration_notice_pending"] = true
		data["shop_migration_relocked"] = relocked
	return data

func generated_currency_sinks(existing_sinks: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {}
	_generate_sinks_for_kind(result, existing_sinks, "weapon", "weapon_license")
	_generate_sinks_for_kind(result, existing_sinks, "passive", "passive_license")
	_generate_sinks_for_kind(result, existing_sinks, "blessing", "blessings")
	return result

func sink_id_for(kind: String, id: String) -> String:
	var category := _category_for_kind(kind)
	for raw_sink_id in currency_sinks.keys():
		var sink_id := String(raw_sink_id)
		var sink: Dictionary = currency_sinks[sink_id]
		if String(sink.get("category", "")) == category and String(sink.get("target", "")) == id:
			return sink_id
	if category != "" and _defs_for_kind(kind).has(id) and not is_starter(kind, id):
		return _generated_sink_id(kind, id)
	return ""

func condition_for(kind: String, id: String) -> Dictionary:
	if kind == "weapon" or kind == "passive":
		return _unlock_defs_for_kind(kind).get(id, {}).get("condition", {"type": "initial"} if is_starter(kind, id) else {})
	if kind == "character":
		return character_unlocks.get(id, {"type": "initial"} if is_starter(kind, id) else {})
	if kind == "blessing":
		return blessings.get(id, {}).get("unlock", {"type": "initial"} if is_starter(kind, id) else {})
	return {}

func cost_for(kind: String, id: String) -> int:
	var sink_id := sink_id_for(kind, id)
	if sink_id != "" and currency_sinks.has(sink_id):
		return int(currency_sinks[sink_id].get("base_cost", _generated_cost(kind, id)))
	if kind == "character":
		var character: Dictionary = characters.get(id, {})
		var direct_cost := int(character.get("unlock_cost", 0))
		if direct_cost > 0:
			return direct_cost
		var condition: Dictionary = character_unlocks.get(id, {})
		if String(condition.get("type", "")) == "currency":
			return int(condition.get("cost", condition.get("value", _generated_cost(kind, id))))
	return _generated_cost(kind, id)

func purchase_state_label(save_data: Dictionary, kind: String, id: String) -> String:
	if is_usable(save_data, kind, id):
		return "購入済み" if not is_starter(kind, id) else "初期解放"
	if is_available_for_purchase(save_data, kind, id):
		return "購入可能"
	return "購入条件未達成"

func purchase_condition_text(save_data: Dictionary, kind: String, id: String) -> String:
	if is_usable(save_data, kind, id):
		return "購入済みです。以後のランで候補に出現します。"
	var condition := condition_for(kind, id)
	if _condition_met(save_data, condition):
		return "購入条件：達成済み"
	var base := _condition_text_for(kind, id)
	var progress := progress_tracker.progress_text(save_data, condition)
	return "%s\n%s" % [base, progress] if progress != "" else base

func _generate_sinks_for_kind(result: Dictionary, existing_sinks: Dictionary, kind: String, category: String) -> void:
	for raw_id in _defs_for_kind(kind).keys():
		var id := String(raw_id)
		if is_starter(kind, id) or _existing_sink_for(existing_sinks, category, id) != "":
			continue
		var sink_id := _generated_sink_id(kind, id)
		var name := _display_name(kind, id)
		var condition := condition_for(kind, id)
		result[sink_id] = {
			"category": category,
			"target": id,
			"name_ja": "%sライセンス：%s" % [_kind_label(kind), name] if kind != "blessing" else name,
			"description_ja": "購入すると、以後のランで%s候補に出現します。" % _kind_candidate_label(kind),
			"effect_per_level_ja": "永久解放",
			"recommend_ja": "条件達成後に購入",
			"max_level": 1,
			"base_cost": _generated_cost(kind, id),
			"unlock_condition": condition,
			"unlock_condition_text_ja": _condition_text_for(kind, id),
			"generated_by": "ShopEntitlementSystem"
		}

func _sync_usable_lists(data: Dictionary) -> void:
	for kind in ["weapon", "passive", "character", "blessing"]:
		var save_key := _save_key_for_kind(kind)
		if save_key == "":
			continue
		data[save_key] = usable_ids(data, kind)

func _recover_legacy_purchases_from_sinks(data: Dictionary) -> void:
	var levels: Dictionary = data.get("currency_sink_levels", {})
	var combined := currency_sinks.duplicate(true)
	var generated := generated_currency_sinks(currency_sinks)
	for id in generated.keys():
		combined[id] = generated[id]
	for raw_sink_id in combined.keys():
		var sink_id := String(raw_sink_id)
		if int(levels.get(sink_id, 0)) <= 0:
			continue
		var sink: Dictionary = combined[sink_id]
		var kind := _kind_for_category(String(sink.get("category", "")))
		var target := String(sink.get("target", ""))
		if kind != "" and target != "":
			mark_purchased(data, kind, target)

func _legacy_purchase_proven(data: Dictionary, kind: String, id: String) -> bool:
	if is_starter(kind, id) or is_purchased(data, kind, id):
		return true
	if kind == "character" and int(characters.get(id, {}).get("unlock_cost", 0)) > 0:
		mark_purchased(data, kind, id)
		return true
	return false

func _repair_selected(data: Dictionary) -> bool:
	var changed := false
	var selected_character := String(data.get("selected_character", "noah"))
	if not is_usable(data, "character", selected_character):
		data["selected_character"] = "noah"
		changed = true
	var selected_blessing := String(data.get("selected_blessing", "attack"))
	if not is_usable(data, "blessing", selected_blessing):
		data["selected_blessing"] = "attack"
		changed = true
	data["disabled_weapons"] = _filter_usable(data.get("disabled_weapons", []), data, "weapon")
	data["disabled_passives"] = _filter_usable(data.get("disabled_passives", []), data, "passive")
	return changed

func _filter_usable(values: Array, data: Dictionary, kind: String) -> Array:
	var result: Array = []
	for raw_id in values:
		var id := String(raw_id)
		if is_usable(data, kind, id):
			result.append(id)
	return result

func _publish_item(save_data: Dictionary, kind: String, id: String) -> bool:
	var available: Dictionary = save_data.get("shop_available", {})
	var table: Dictionary = available.get(kind, {})
	var was_new := not bool(table.get(id, false))
	table[id] = true
	available[kind] = table
	save_data["shop_available"] = available
	return was_new

func _condition_met(save_data: Dictionary, condition: Dictionary) -> bool:
	if condition.is_empty():
		return false
	if String(condition.get("type", "")) == "currency_sink":
		return true
	return bool(progress_tracker.progress_for_condition(save_data, condition).get("complete", false))

func _display_name(kind: String, id: String) -> String:
	return String(_defs_for_kind(kind).get(id, {}).get("name_ja", id))

func _condition_text_for(kind: String, id: String) -> String:
	if kind == "weapon" or kind == "passive":
		return String(_unlock_defs_for_kind(kind).get(id, {}).get("text_ja", "購入条件を満たしていません"))
	if kind == "character":
		return String(character_unlocks.get(id, {}).get("text_ja", "購入条件を満たしていません"))
	if kind == "blessing":
		return String(blessings.get(id, {}).get("unlock_condition_ja", "購入条件を満たしていません"))
	return "購入条件を満たしていません"

func _defs_for_kind(kind: String) -> Dictionary:
	match kind:
		"weapon":
			return weapons
		"passive":
			return passives
		"character":
			return characters
		"blessing":
			return blessings
	return {}

func _unlock_defs_for_kind(kind: String) -> Dictionary:
	return weapon_unlocks if kind == "weapon" else passive_unlocks

func _save_key_for_kind(kind: String) -> String:
	match kind:
		"weapon":
			return "unlocked_weapons"
		"passive":
			return "unlocked_passives"
		"character":
			return "unlocked_characters"
		"blessing":
			return "unlocked_blessings"
	return ""

func _category_for_kind(kind: String) -> String:
	match kind:
		"weapon":
			return "weapon_license"
		"passive":
			return "passive_license"
		"blessing":
			return "blessings"
	return ""

func _kind_for_category(category: String) -> String:
	match category:
		"weapon_license":
			return "weapon"
		"passive_license":
			return "passive"
		"blessings":
			return "blessing"
	return ""

func _kind_label(kind: String) -> String:
	match kind:
		"weapon":
			return "武器"
		"passive":
			return "パッシブ"
	return "祝福"

func _kind_candidate_label(kind: String) -> String:
	return "武器" if kind == "weapon" else ("パッシブ" if kind == "passive" else "祝福")

func _existing_sink_for(sinks: Dictionary, category: String, target: String) -> String:
	for raw_id in sinks.keys():
		var id := String(raw_id)
		if String(sinks[id].get("category", "")) == category and String(sinks[id].get("target", "")) == target:
			return id
	return ""

func _generated_sink_id(kind: String, id: String) -> String:
	return "%s_license_%s" % [kind, id] if kind != "blessing" else "blessing_%s" % id

func _generated_cost(kind: String, id: String) -> int:
	var defaults: Dictionary = config.get("default_costs", {})
	var table: Dictionary = defaults.get(kind, {"base": 600, "step": 120})
	var index := maxi(0, _defs_for_kind(kind).keys().find(id))
	return int(table.get("base", 600)) + int(table.get("step", 120)) * index

func _relocked_count(relocked: Dictionary) -> int:
	var count := 0
	for values in relocked.values():
		count += (values as Array).size()
	return count

func _mark_collection(save_data: Dictionary, tab: String, id: String) -> void:
	var discovered: Dictionary = save_data.get("collection_discovered", {})
	var table: Dictionary = discovered.get(tab, {})
	table[id] = true
	discovered[tab] = table
	save_data["collection_discovered"] = discovered

func _json_dict(path: String, fallback: Dictionary = {}) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback.duplicate(true)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else fallback.duplicate(true)
