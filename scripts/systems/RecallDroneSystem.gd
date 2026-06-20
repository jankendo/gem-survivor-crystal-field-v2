extends RefCounted
class_name RecallDroneSystem

var global_collection_system = preload("res://scripts/systems/GlobalGemCollectionSystem.gd").new()

func activate(state, events: Array) -> bool:
	if not state.recall_drone_ready:
		return false
	state.recall_drone_ready = false
	state.recall_drone_meter = 0.0
	state.recall_drone_active_timer = 5.0
	state.recall_drone_activations += 1
	var result = global_collection_system.collect_all(state, events, "drone")
	state.add_floating_text("回収ドローン %d" % int(result.get("count", 0)), state.player_position + Vector2(0, -54), Color(0.42, 0.95, 1.0))
	events.append({"type": "recall_drone", "count": int(result.get("count", 0)), "exp": int(result.get("exp", 0)), "batches": int(result.get("batches", 0))})
	return true
