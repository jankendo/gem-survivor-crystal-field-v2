extends RefCounted
class_name FieldEventNavigationSystem

func update(state) -> void:
	if state.active_field_event.is_empty():
		clear(state)
		return
	var kind := String(state.active_field_event.get("target_kind", ""))
	var runtime_id := String(state.active_field_event.get("target_runtime_id", ""))
	var target := {}
	match kind:
		"crystal_wall":
			target = _nearest_event_wall(state)
		"elite":
			target = _event_elite(state, runtime_id)
		"danger_zone":
			target = _dictionary_target(state.danger_zones, runtime_id, "イベント危険地帯")
		"chest":
			target = _event_chest(state, runtime_id)
	if target.is_empty():
		state.navigation_targets.erase("field_event")
		state.active_field_event["navigation_enabled"] = false
		return
	state.navigation_targets["field_event"] = {
		"enabled": true,
		"runtime_id": target["runtime_id"],
		"position": target["position"],
		"label": target["label"],
	}
	state.active_field_event["target_runtime_id"] = target["runtime_id"]
	state.active_field_event["target_position"] = target["position"]
	state.active_field_event["target_label"] = target["label"]
	state.active_field_event["navigation_enabled"] = true

func clear(state) -> void:
	state.navigation_targets.erase("field_event")

func _nearest_event_wall(state) -> Dictionary:
	var instance_id := String(state.active_field_event.get("instance_id", ""))
	var best := {}
	var best_distance := INF
	for wall in state.crystal_walls:
		if not String(wall.id).begins_with("%s_wall_" % instance_id):
			continue
		var distance: float = wall.position.distance_to(state.player_position)
		if distance < best_distance:
			best_distance = distance
			best = {"runtime_id": wall.id, "position": wall.position, "label": "イベント結晶壁"}
	return best

func _event_elite(state, runtime_id: String) -> Dictionary:
	for enemy in state.enemies:
		if String(enemy.data.get("event_instance_id", "")) == runtime_id:
			return {"runtime_id": runtime_id, "position": enemy.position, "label": "イベントエリート"}
	return {}

func _event_chest(state, runtime_id: String) -> Dictionary:
	for chest in state.chests:
		if String(chest.runtime_id) == runtime_id and not chest.collected:
			return {"runtime_id": runtime_id, "position": chest.position, "label": "呪いの宝箱"}
	return {}

func _dictionary_target(items: Array, runtime_id: String, label: String) -> Dictionary:
	for item in items:
		if String(item.get("runtime_id", item.get("id", ""))) == runtime_id:
			return {"runtime_id": runtime_id, "position": item.get("position", Vector2.ZERO), "label": label}
	return {}
