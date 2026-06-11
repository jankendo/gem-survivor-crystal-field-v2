extends RefCounted
class_name ExplorationMasterySystem

func process(state, events: Array) -> void:
	var points: Dictionary = state.exploration_mastery_defs.get("points", {})
	for event in events.duplicate():
		var type = String(event.get("type", ""))
		var gained = 0
		match type:
			"field_drop_pickup":
				gained += int(points.get("field_drop_pickup", 8))
				if float(event.get("spawn_distance", 0.0)) >= 1500.0:
					gained += int(points.get("far_drop_bonus", 7))
					state.exploration_far_pickups += 1
				if bool(event.get("in_danger", false)):
					gained += int(points.get("danger_pickup_bonus", 10))
					state.exploration_danger_pickups += 1
			"gimmick_activated", "gimmick_destroyed", "gimmick_open":
				gained += int(points.get("gimmick_trigger", 10))
				if String(event.get("id", "")) == "spawn_rift":
					gained += int(points.get("spawn_rift_destroyed", 18))
				elif String(event.get("id", "")) == "sealed_chest_pillar":
					gained += int(points.get("sealed_pillar_opened", 20))
			"field_event_success":
				gained += int(points.get("field_event_success", 22))
				state.field_event_successes += 1
			"field_event_failed":
				state.field_event_failures += 1
		if gained > 0:
			state.exploration_score += gained
			events.append({"type": "exploration_score", "amount": gained, "score": state.exploration_score})
	_update_rank(state)

func rank_for_score(defs: Dictionary, score: int) -> Dictionary:
	var result = {"rank": "D", "min_score": 0, "currency_bonus": 0.0}
	for raw in defs.get("ranks", []):
		var entry: Dictionary = raw
		if score >= int(entry.get("min_score", 0)):
			result = entry
	return result.duplicate(true)

func _update_rank(state) -> void:
	var rank = rank_for_score(state.exploration_mastery_defs, state.exploration_score)
	state.exploration_rank = String(rank.get("rank", "D"))
	state.exploration_currency_bonus = float(rank.get("currency_bonus", 0.0))
