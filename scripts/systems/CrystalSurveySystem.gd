extends RefCounted
class_name CrystalSurveySystem

const FieldHelpSystemScript = preload("res://scripts/systems/FieldHelpSystem.gd")
const FieldObjectAvailabilitySystemScript = preload("res://scripts/systems/FieldObjectAvailabilitySystem.gd")

var field_help = FieldHelpSystemScript.new()
var availability = FieldObjectAvailabilitySystemScript.new()

func tick(state, delta: float) -> void:
	if state == null:
		return
	state.scan_cooldown = maxf(0.0, float(state.scan_cooldown) - delta)
	state.scan_extract_cooldown = maxf(0.0, float(state.scan_extract_cooldown) - delta)
	state.scan_hold_progress = maxf(0.0, float(state.scan_hold_progress) - delta)

func short_scan(state, events: Array, max_distance: float = 760.0) -> Dictionary:
	var started := Time.get_ticks_usec()
	_telemetry_inc(state, "scan_tap_count")
	if float(state.scan_cooldown) > 0.0:
		_record_scan_time(state, started)
		return {"ok": false, "reason": "cooldown", "cooldown": state.scan_cooldown}
	var candidates := _collect_candidates(state, max_distance)
	if candidates.is_empty():
		state.scanned_field_help = {}
		state.field_scan_timer = 2.0
		state.scan_cooldown = 1.0
		_record_scan_time(state, started)
		return {"ok": false, "reason": "no_target", "discoveries": []}
	var discoveries: Array = []
	var first_target: Dictionary = candidates[0]
	for candidate in candidates:
		var key := String(candidate.get("key", ""))
		if key == "":
			continue
		if not bool(state.scan_discovered_keys.get(key, false)):
			state.scan_discovered_keys[key] = true
			discoveries.append(candidate)
			_award_resonance_for_discovery(state, candidate, events)
			events.append({
				"type": "survey_discovery",
				"key": key,
				"kind": candidate.get("kind", ""),
				"id": candidate.get("id", ""),
				"name": candidate.get("name_ja", "新発見"),
				"position": candidate.get("position", state.player_position)
			})
			_mark_room_discovered(state, candidate, events)
		if discoveries.size() >= 4:
			break
	state.scanned_field_help = _help_entry_for_candidate(state, first_target)
	state.field_scan_timer = 7.0
	state.scan_cooldown = 2.2
	state.scan_last_targets = candidates.slice(0, mini(candidates.size(), 8))
	state.scan_navigation_target = first_target.duplicate(true)
	_mark_room_discovered(state, first_target, events)
	_telemetry_inc(state, "scan_discoveries", discoveries.size())
	_record_scan_time(state, started)
	return {
		"ok": true,
		"target": first_target,
		"discoveries": discoveries,
		"candidate_count": candidates.size(),
		"resonance": state.survey_resonance
	}

func begin_extract(state, events: Array, max_distance: float = 420.0) -> Dictionary:
	_telemetry_inc(state, "scan_hold_count")
	if float(state.scan_extract_cooldown) > 0.0:
		return {"ok": false, "reason": "cooldown"}
	if int(state.survey_resonance) < int(state.survey_resonance_max):
		return {"ok": false, "reason": "resonance_short", "current": state.survey_resonance, "target": state.survey_resonance_max}
	var target := extractable_target(state, max_distance)
	if target.is_empty():
		return {"ok": false, "reason": "no_extractable"}
	state.scan_extract_target = target
	state.scan_hold_progress = 1.45
	events.append({"type": "survey_extract_begin", "target": target})
	return {"ok": true, "target": target, "duration": state.scan_hold_progress}

func complete_extract(state, events: Array) -> Dictionary:
	_telemetry_inc(state, "extraction_attempts")
	var target: Dictionary = state.scan_extract_target
	if target.is_empty():
		_telemetry_inc(state, "extraction_cancels")
		return {"ok": false, "reason": "no_target"}
	if not _target_still_available(state, target):
		cancel_extract(state, events, "target_gone")
		return {"ok": false, "reason": "target_gone"}
	state.survey_resonance = maxi(0, int(state.survey_resonance) - int(state.survey_resonance_max))
	state.scan_extract_cooldown = 8.0
	state.scan_hold_progress = 0.0
	state.scan_extract_target = {}
	_telemetry_inc(state, "extraction_successes")
	events.append({"type": "survey_extract_complete", "target": target, "name": target.get("name_ja", "封印対象")})
	return {"ok": true, "target": target}

func cancel_extract(state, events: Array, reason: String = "cancel") -> void:
	if not state.scan_extract_target.is_empty():
		events.append({"type": "survey_extract_cancel", "reason": reason, "target": state.scan_extract_target})
	state.scan_extract_target = {}
	state.scan_hold_progress = 0.0
	_telemetry_inc(state, "scan_cancel_count")
	_telemetry_inc(state, "extraction_cancels")

func extractable_target(state, max_distance: float = 420.0) -> Dictionary:
	var best: Dictionary = {}
	var best_dist_sq := max_distance * max_distance
	for equipment in state.field_equipment:
		if not bool(equipment.get("scan_extractable", true)):
			continue
		if not availability.is_available_now(state, equipment, "collected"):
			continue
		var pos: Vector2 = equipment.get("position", Vector2.ZERO)
		var dist_sq := pos.distance_squared_to(state.player_position)
		if dist_sq <= best_dist_sq:
			best_dist_sq = dist_sq
			best = {
				"kind": "field_equipment",
				"id": String(equipment.get("id", "")),
				"runtime_id": String(equipment.get("runtime_id", equipment.get("id", ""))),
				"name_ja": String(equipment.get("name_ja", equipment.get("id", "フィールド装備"))),
				"position": pos,
				"source": equipment
			}
	for drop in state.field_drops:
		if String(drop.get("id", "")) not in ["weapon_core", "passive_core"]:
			continue
		if not bool(drop.get("scan_extractable", true)):
			continue
		if not availability.is_available_now(state, drop, "collected"):
			continue
		var drop_pos: Vector2 = drop.get("position", Vector2.ZERO)
		var drop_dist_sq := drop_pos.distance_squared_to(state.player_position)
		if drop_dist_sq <= best_dist_sq:
			best_dist_sq = drop_dist_sq
			best = {
				"kind": "drop",
				"id": String(drop.get("id", "")),
				"runtime_id": String(drop.get("runtime_id", drop.get("id", ""))),
				"name_ja": String(drop.get("name_ja", drop.get("id", "封印コア"))),
				"position": drop_pos,
				"source": drop
			}
	return best

func button_label(state) -> String:
	if float(state.scan_cooldown) > 0.0:
		return "スキャン\n%d秒" % int(ceil(float(state.scan_cooldown)))
	if not state.scan_extract_target.is_empty():
		return "抽出\n%d%%" % int(round((1.45 - float(state.scan_hold_progress)) / 1.45 * 100.0))
	if int(state.survey_resonance) >= int(state.survey_resonance_max) and not extractable_target(state).is_empty():
		return "長押し\n抽出可能"
	if not state.nearby_field_help.is_empty():
		return "スキャン\n反応あり"
	return "スキャン"

func _collect_candidates(state, max_distance: float) -> Array:
	var max_dist_sq := max_distance * max_distance
	var candidates: Array = []
	for room in state.map_data.get("rooms", []):
		var pos: Vector2 = room.get("position", Vector2.ZERO)
		var dist_sq := pos.distance_squared_to(state.player_position)
		if dist_sq <= max_dist_sq:
			candidates.append({
				"kind": "room",
				"id": String(room.get("id", "")),
				"terrain_id": String(room.get("terrain_id", "")),
				"name_ja": _terrain_name(state, String(room.get("terrain_id", ""))),
				"position": pos,
				"distance_sq": dist_sq,
				"key": "room:%s" % String(room.get("id", ""))
			})
	_add_field_candidates(state, candidates, max_dist_sq)
	_add_enemy_candidates(state, candidates, max_dist_sq)
	if not state.active_field_event.is_empty():
		candidates.append({
			"kind": "event",
			"id": String(state.active_field_event.get("id", "active_event")),
			"name_ja": String(state.active_field_event.get("name_ja", "フィールドイベント")),
			"position": state.active_field_event.get("position", state.player_position),
			"distance_sq": 0.0,
			"key": "event:%s" % String(state.active_field_event.get("id", "active_event"))
		})
	candidates.sort_custom(func(a, b): return float(a.get("distance_sq", 0.0)) < float(b.get("distance_sq", 0.0)))
	return candidates.slice(0, mini(candidates.size(), 12))

func _add_field_candidates(state, candidates: Array, max_dist_sq: float) -> void:
	for drop in state.field_drops:
		if not availability.is_available_now(state, drop, "collected"):
			continue
		var pos: Vector2 = drop.get("position", Vector2.ZERO)
		var dist_sq := pos.distance_squared_to(state.player_position)
		if dist_sq <= max_dist_sq:
			candidates.append({
				"kind": "drop",
				"id": String(drop.get("id", "")),
				"name_ja": String(drop.get("name_ja", drop.get("id", "ドロップ"))),
				"position": pos,
				"distance_sq": dist_sq,
				"key": "drop:%s" % String(drop.get("runtime_id", drop.get("id", "")))
			})
	for equipment in state.field_equipment:
		if not availability.is_available_now(state, equipment, "collected"):
			continue
		var equip_pos: Vector2 = equipment.get("position", Vector2.ZERO)
		var equip_dist_sq := equip_pos.distance_squared_to(state.player_position)
		if equip_dist_sq <= max_dist_sq:
			candidates.append({
				"kind": "equipment",
				"id": String(equipment.get("id", "")),
				"name_ja": String(equipment.get("name_ja", equipment.get("id", "フィールド装備"))),
				"position": equip_pos,
				"distance_sq": equip_dist_sq,
				"key": "equipment:%s" % String(equipment.get("runtime_id", equipment.get("id", "")))
			})
	for gimmick in state.field_gimmicks:
		if not availability.is_available_now(state, gimmick, "destroyed"):
			continue
		var gimmick_pos: Vector2 = gimmick.get("position", Vector2.ZERO)
		var gimmick_dist_sq := gimmick_pos.distance_squared_to(state.player_position)
		if gimmick_dist_sq <= max_dist_sq:
			candidates.append({
				"kind": "gimmick",
				"id": String(gimmick.get("id", "")),
				"name_ja": String(gimmick.get("name_ja", gimmick.get("id", "ギミック"))),
				"position": gimmick_pos,
				"distance_sq": gimmick_dist_sq,
				"key": "gimmick:%s" % String(gimmick.get("runtime_id", gimmick.get("id", "")))
			})

func _add_enemy_candidates(state, candidates: Array, max_dist_sq: float) -> void:
	var seen_types: Dictionary = {}
	for enemy in state.enemies:
		if enemy == null:
			continue
		var dist_sq: float = enemy.position.distance_squared_to(state.player_position)
		if dist_sq > max_dist_sq:
			continue
		var type_key := String(enemy.type)
		if bool(seen_types.get(type_key, false)) and not enemy.boss and not enemy.elite:
			continue
		seen_types[type_key] = true
		candidates.append({
			"kind": "enemy",
			"id": type_key,
			"name_ja": "ボス" if enemy.boss else ("エリート" if enemy.elite else type_key),
			"position": enemy.position,
			"distance_sq": dist_sq,
			"key": "enemy:%s" % type_key
		})

func _help_entry_for_candidate(state, candidate: Dictionary) -> Dictionary:
	var kind := String(candidate.get("kind", ""))
	if kind in ["drop", "gimmick"]:
		var section := "drops" if kind == "drop" else "gimmicks"
		var entry: Dictionary = state.field_help_defs.get(section, {}).get(String(candidate.get("id", "")), {}).duplicate(true)
		if not entry.is_empty():
			entry["kind"] = kind
			entry["id"] = candidate.get("id", "")
			entry["name_ja"] = candidate.get("name_ja", entry.get("name_ja", "調査対象"))
			entry["position"] = candidate.get("position", state.player_position)
			return entry
	return {
		"kind": kind,
		"id": candidate.get("id", ""),
		"name_ja": candidate.get("name_ja", "調査対象"),
		"title_ja": candidate.get("name_ja", "調査対象"),
		"body_ja": "スキャンで発見しました。マップと目標表示を確認してください。",
		"effect_ja": "発見済みとして記録",
		"approach_ja": "安全な進路を選び、必要なら長押し抽出を使う",
		"reward_ja": "探査共鳴",
		"danger_ja": "周辺敵に注意",
		"recommend_ja": "次の探索先候補",
		"position": candidate.get("position", state.player_position)
	}

func _mark_room_discovered(state, candidate: Dictionary, events: Array) -> void:
	var room_id := ""
	if String(candidate.get("kind", "")) == "room":
		room_id = String(candidate.get("id", ""))
	else:
		var room = state.terrain_room_system.room_at_position(state.map_data, candidate.get("position", state.player_position))
		room_id = String(room.get("id", ""))
	if room_id == "" or room_id == "corridor":
		return
	if not state.explored_room_ids.has(room_id):
		state.explored_room_ids.append(room_id)
		state.rooms_discovered += 1
		_telemetry_inc(state, "rooms_discovered_by_scan")
		events.append({"type": "scan_room_discovered", "room": room_id})

func _award_resonance_for_discovery(state, candidate: Dictionary, events: Array) -> void:
	var kind := String(candidate.get("kind", ""))
	if not kind in ["room", "drop", "equipment", "gimmick", "event"]:
		return
	if int(state.survey_resonance) >= int(state.survey_resonance_max):
		return
	state.survey_resonance += 1
	_telemetry_inc(state, "resonance_earned")
	events.append({
		"type": "survey_resonance_earned",
		"current": state.survey_resonance,
		"max": state.survey_resonance_max,
		"source": candidate.get("key", "")
	})
	match kind:
		"room":
			_telemetry_inc(state, "rooms_discovered_by_scan")
		"drop", "equipment", "gimmick":
			_telemetry_inc(state, "items_discovered_by_scan")
		"event":
			_telemetry_inc(state, "events_discovered_by_scan")

func _target_still_available(state, target: Dictionary) -> bool:
	var source = target.get("source", {})
	if source is Dictionary:
		if String(target.get("kind", "")) == "drop":
			return availability.is_available_now(state, source, "collected")
		if String(target.get("kind", "")) == "field_equipment":
			return availability.is_available_now(state, source, "collected")
	return false

func _terrain_name(state, terrain_id: String) -> String:
	return String(state.terrain_type_defs.get(terrain_id, {}).get("name_ja", terrain_id))

func _telemetry_inc(state, key: String, amount: int = 1) -> void:
	state.scan_telemetry[key] = int(state.scan_telemetry.get(key, 0)) + amount

func _record_scan_time(state, started_usec: int) -> void:
	state.scan_telemetry["scan_query_us"] = maxi(0, Time.get_ticks_usec() - started_usec)
