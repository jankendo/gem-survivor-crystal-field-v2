extends RefCounted
class_name FieldHelpSystem

func process(state, events: Array, proximity: float = 230.0) -> Dictionary:
	var target = nearest_target(state, proximity)
	if target.is_empty():
		state.nearby_field_help = {}
		return {}
	state.nearby_field_help = target
	var key = discovery_key(target)
	if key != "" and not bool(state.field_help_discovered.get(key, false)):
		state.field_help_discovered[key] = true
		events.append({
			"type": "field_discovery",
			"key": key,
			"kind": target.get("kind", ""),
			"id": target.get("id", ""),
			"name": target.get("name_ja", "新発見"),
			"entry": target.duplicate(true)
		})
	return target

func scan(state, max_distance: float = 680.0) -> Dictionary:
	var target = nearest_target(state, max_distance)
	if target.is_empty() and not state.active_field_event.is_empty():
		target = _entry_for(state, "events", String(state.active_field_event.get("id", "")))
		target["kind"] = "event"
		target["id"] = String(state.active_field_event.get("id", ""))
		target["distance"] = 0.0
	state.scanned_field_help = target
	state.field_scan_timer = 7.0 if not target.is_empty() else 2.0
	return target

func nearest_target(state, max_distance: float = 230.0) -> Dictionary:
	var best: Dictionary = {}
	var best_distance = max_distance
	for drop in state.field_drops:
		if bool(drop.get("collected", false)) or state.elapsed_seconds < float(drop.get("unlock_seconds", 0.0)):
			continue
		var distance = (drop.get("position", Vector2.ZERO) as Vector2).distance_to(state.player_position)
		if distance <= best_distance:
			best_distance = distance
			best = _entry_for(state, "drops", String(drop.get("id", "")))
			best["kind"] = "drop"
			best["id"] = String(drop.get("id", ""))
			best["position"] = drop.get("position", Vector2.ZERO)
			best["distance"] = distance
	for gimmick in state.field_gimmicks:
		if bool(gimmick.get("destroyed", false)) or state.elapsed_seconds < float(gimmick.get("unlock_seconds", 0.0)):
			continue
		var distance = (gimmick.get("position", Vector2.ZERO) as Vector2).distance_to(state.player_position)
		if distance <= best_distance:
			best_distance = distance
			best = _entry_for(state, "gimmicks", String(gimmick.get("id", "")))
			best["kind"] = "gimmick"
			best["id"] = String(gimmick.get("id", ""))
			best["position"] = gimmick.get("position", Vector2.ZERO)
			best["distance"] = distance
	return best

func discovery_key(target: Dictionary) -> String:
	var kind = String(target.get("kind", ""))
	var id = String(target.get("id", ""))
	return "%s:%s" % [kind, id] if kind != "" and id != "" else ""

func _entry_for(state, section: String, id: String) -> Dictionary:
	return state.field_help_defs.get(section, {}).get(id, {}).duplicate(true)

