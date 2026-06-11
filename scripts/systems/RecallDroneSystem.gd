extends RefCounted
class_name RecallDroneSystem

func activate(state, events: Array) -> bool:
	if not state.recall_drone_ready:
		return false
	state.recall_drone_ready = false
	state.recall_drone_meter = 0.0
	state.recall_drone_active_timer = 5.0
	state.recall_drone_activations += 1
	var pulled = 0
	for gem in state.gems:
		if gem.position.distance_to(state.player_position) <= 1450.0:
			gem.attracting = true
			pulled += 1
	state.add_floating_text("回収ドローン %d" % pulled, state.player_position + Vector2(0, -54), Color(0.42, 0.95, 1.0))
	events.append({"type": "recall_drone", "count": pulled})
	return true
