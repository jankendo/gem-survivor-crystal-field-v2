extends RefCounted
class_name CorePickupChoiceSystem

const SelectionContextSystemScript = preload("res://scripts/systems/SelectionContextSystem.gd")

var capacity = preload("res://scripts/systems/EquipmentCapacitySystem.gd").new()
var over_cap = preload("res://scripts/systems/EquipmentOverCapSystem.gd").new()

func open_choice(state, kind: String, drop: Dictionary, events: Array, count: int = 3) -> bool:
	var options = _options(state, kind, count)
	if options.is_empty():
		var fallback_score := 900 if kind == "weapon" else 700
		state.add_score(fallback_score, drop.get("position", state.player_position))
		state.message = "現在選べる候補がないため、スコア+%dに変換しました" % fallback_score
		events.append({"type": "core_choice_empty", "kind": kind, "score": fallback_score})
		return false
	var source_id = String(drop.get("runtime_id", drop.get("id", "%s_core" % kind)))
	state.pending_core_choice = {
		"source_id": source_id,
		"kind": kind,
		"position": drop.get("position", state.player_position),
		"options": options
	}
	state.level_up_options = options
	state.level_up_pending = true
	state.selection_context = SelectionContextSystemScript.WEAPON_CORE if kind == "weapon" else SelectionContextSystemScript.PASSIVE_CORE
	state.message = "%sの中身を選択" % ("武器コア" if kind == "weapon" else "パッシブ結晶")
	events.append({"type": "core_choice_open", "kind": kind, "options": options.size(), "source_id": source_id})
	return true

func accept_current(state, uid: String, events: Array) -> bool:
	if state.pending_core_choice.is_empty():
		return false
	var option = _find_option(state.pending_core_choice.get("options", []), uid)
	if option.is_empty():
		return false
	if String(option.get("action", "")) == "decline":
		return decline_current(state, events)
	var kind = String(option.get("equipment_kind", option.get("kind", "")))
	var id = String(option.get("id", ""))
	if not over_cap.grant(state, kind, id, events, "core", true):
		return false
	_close(state)
	state.message = "%s Lv%d" % [String(option.get("name_ja", id)), int((state.weapons if kind == "weapon" else state.passives).get(id, 1))]
	events.append({"type": "core_choice_accept", "kind": kind, "id": id, "name": option.get("name_ja", id)})
	return true

func decline_current(state, events: Array) -> bool:
	if state.pending_core_choice.is_empty():
		return false
	state.add_score(350, state.player_position)
	events.append({"type": "core_choice_decline", "kind": state.pending_core_choice.get("kind", ""), "score": 350})
	_close(state)
	state.message = "コアを見送り：スコア+350"
	return true

func _options(state, kind: String, count: int) -> Array:
	var weighted: Array = []
	var defs: Dictionary = state.weapon_defs if kind == "weapon" else state.passive_defs
	var owned: Dictionary = state.weapons if kind == "weapon" else state.passives
	for raw_id in defs.keys():
		var id := String(raw_id)
		var offerable: bool = state.can_offer_weapon(id) if kind == "weapon" else state.can_offer_passive(id)
		if not offerable:
			continue
		if not capacity.can_take(state, kind, id, true):
			continue
		var weight := 6.0 if owned.has(id) else 2.4
		if owned.size() >= capacity.normal_cap(state, kind) and not owned.has(id):
			weight *= 0.65
		weighted.append({"id": id, "weight": weight})
	var options: Array = []
	var used: Array = []
	while options.size() < count and not weighted.is_empty():
		var chosen: Dictionary = state.rng.weighted_choice(weighted)
		var id := String(chosen.get("id", ""))
		if id == "" or used.has(id):
			_remove_weighted(weighted, id)
			continue
		used.append(id)
		options.append(_make_option(state, kind, id))
		_remove_weighted(weighted, id)
	if options.is_empty():
		return options
	options.append({
		"uid": "core_decline:%s" % kind,
		"kind": "decline",
		"equipment_kind": kind,
		"id": "decline",
		"action": "decline",
		"name_ja": "取得しない",
		"next_level": 0,
		"description_ja": "今回は見送り、少量のスコアに変換します",
		"type_label": "見送り",
		"type_color": "infinite",
		"evolution_hint": "フィールド報酬は後戻りできません"
	})
	return options

func _make_option(state, kind: String, id: String) -> Dictionary:
	var owned: Dictionary = state.weapons if kind == "weapon" else state.passives
	var defs: Dictionary = state.weapon_defs if kind == "weapon" else state.passive_defs
	var current := int(owned.get(id, 0))
	var over_label := ""
	if current <= 0 and owned.size() >= capacity.normal_cap(state, kind):
		over_label = " / フィールド取得で枠超過可"
	return {
		"uid": "core:%s:%s" % [kind, id],
		"kind": kind,
		"equipment_kind": kind,
		"id": id,
		"name_ja": state.weapon_name(id) if kind == "weapon" else state.passive_name(id),
		"next_level": current + 1,
		"description_ja": String(defs.get(id, {}).get("description_ja", "装備強化")) + over_label,
		"type_label": "武器コア" if kind == "weapon" else "パッシブ結晶",
		"type_color": "weapon" if kind == "weapon" else "passive",
		"evolution_hint": "現在 %s" % capacity.display_text(state, kind)
	}

func _close(state) -> void:
	state.pending_core_choice = {}
	state.level_up_pending = false
	state.level_up_options = []
	state.selection_context = SelectionContextSystemScript.NONE

func _find_option(options: Array, uid: String) -> Dictionary:
	for option in options:
		if String(option.get("uid", "")) == uid:
			return option
	return {}

func _remove_weighted(weighted: Array, id: String) -> void:
	for i in range(weighted.size() - 1, -1, -1):
		if String(weighted[i].get("id", "")) == id:
			weighted.remove_at(i)
