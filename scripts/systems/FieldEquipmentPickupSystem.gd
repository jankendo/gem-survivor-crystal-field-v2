extends RefCounted
class_name FieldEquipmentPickupSystem

var capacity = preload("res://scripts/systems/EquipmentCapacitySystem.gd").new()
var over_cap = preload("res://scripts/systems/EquipmentOverCapSystem.gd").new()
var availability = preload("res://scripts/systems/FieldObjectAvailabilitySystem.gd").new()

func process(state, delta: float, events: Array) -> void:
	if not state.pending_field_equipment_choice.is_empty():
		return
	for equipment in state.field_equipment:
		if not availability.is_available_now(state, equipment, "collected"):
			continue
		var pos: Vector2 = equipment.get("position", Vector2.ZERO)
		if pos.distance_to(state.player_position) <= float(equipment.get("radius", 34.0)) + 22.0:
			var kind := String(equipment.get("kind", "weapon"))
			var item_id := String(equipment.get("id", ""))
			if bool(equipment.get("invalid_conversion_only", false)) or not capacity.can_take(state, kind, item_id, true):
				_convert_invalid(state, equipment, events, "invalid_or_unavailable")
				return
			open_choice(state, equipment, events)
			return

func open_choice(state, equipment: Dictionary, events: Array) -> bool:
	equipment["pending"] = true
	var kind := String(equipment.get("kind", "weapon"))
	var item_id := String(equipment.get("id", ""))
	var owned = state.weapons if kind == "weapon" else state.passives
	var owned_text = "既に所持中。取得するとLv+1 / " if int(owned.get(item_id, 0)) > 0 else ""
	var option := {
		"uid": "field_equipment:%s" % String(equipment.get("runtime_id", item_id)),
		"kind": kind,
		"equipment_kind": kind,
		"id": item_id,
		"name_ja": String(equipment.get("name_ja", item_id)),
		"next_level": int((state.weapons if kind == "weapon" else state.passives).get(item_id, 0)) + 1,
		"description_ja": "%s%s。通常5枠を超えていても取得できます" % [owned_text, String(equipment.get("reason_ja", "フィールド報酬"))],
		"type_label": "フィールド武器" if kind == "weapon" else "フィールドパッシブ",
		"type_color": "weapon" if kind == "weapon" else "passive",
		"evolution_hint": "マップ配置の具体報酬 / 取得しない選択可"
	}
	var decline := {
		"uid": "field_equipment_decline:%s" % String(equipment.get("runtime_id", item_id)),
		"kind": "decline",
		"equipment_kind": kind,
		"id": "decline",
		"action": "decline",
		"name_ja": "取得しない",
		"next_level": 0,
		"description_ja": "見送り、少量のスコアに変換します",
		"type_label": "見送り",
		"type_color": "infinite"
	}
	state.pending_field_equipment_choice = {"equipment": equipment, "options": [option, decline]}
	state.level_up_options = [option, decline]
	state.level_up_pending = true
	state.message = "フィールド装備を発見：%s" % String(equipment.get("name_ja", item_id))
	events.append({"type": "field_equipment_choice_open", "id": item_id, "kind": kind, "name": option.get("name_ja", item_id)})
	return true

func accept_current(state, uid: String, events: Array) -> bool:
	if state.pending_field_equipment_choice.is_empty():
		return false
	var option = _find_option(state.pending_field_equipment_choice.get("options", []), uid)
	if option.is_empty():
		return false
	if String(option.get("action", "")) == "decline":
		return decline_current(state, events)
	var equipment: Dictionary = state.pending_field_equipment_choice.get("equipment", {})
	var kind := String(option.get("equipment_kind", option.get("kind", "weapon")))
	var id := String(option.get("id", ""))
	if not over_cap.grant(state, kind, id, events, "field_equipment", true):
		_convert_invalid(state, equipment, events, "grant_rejected")
		_close(state)
		return true
	equipment["collected"] = true
	equipment["pending"] = false
	state.field_equipment_collected += 1
	state.reward_room_pickups += 1
	state.message = "%s取得" % String(option.get("name_ja", id))
	events.append({"type": "field_equipment_pickup", "kind": kind, "id": id, "name": option.get("name_ja", id), "room_id": equipment.get("room_id", "")})
	_close(state)
	return true

func _convert_invalid(state, equipment: Dictionary, events: Array, reason: String) -> void:
	equipment["collected"] = true
	equipment["pending"] = false
	var score := 300
	state.add_score(score, equipment.get("position", state.player_position))
	state.field_equipment_converted += 1
	state.message = "無効なフィールド装備をスコア+%dに変換" % score
	events.append({
		"type": "field_equipment_converted",
		"id": equipment.get("id", ""),
		"kind": equipment.get("kind", ""),
		"reason": reason,
		"score": score
	})

func decline_current(state, events: Array) -> bool:
	if state.pending_field_equipment_choice.is_empty():
		return false
	var equipment: Dictionary = state.pending_field_equipment_choice.get("equipment", {})
	equipment["collected"] = true
	equipment["pending"] = false
	state.add_score(300, equipment.get("position", state.player_position))
	state.message = "フィールド装備を見送り：スコア+300"
	events.append({"type": "field_equipment_decline", "id": equipment.get("id", ""), "score": 300})
	_close(state)
	return true

func _close(state) -> void:
	state.pending_field_equipment_choice = {}
	state.level_up_pending = false
	state.level_up_options = []

func _find_option(options: Array, uid: String) -> Dictionary:
	for option in options:
		if String(option.get("uid", "")) == uid:
			return option
	return {}
