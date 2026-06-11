extends RefCounted
class_name ExplorationChainSystem

const CHAIN_EVENTS = ["field_drop_pickup", "gimmick_activated", "gimmick_destroyed", "gimmick_open", "field_event_success"]

func process(state, delta: float, events: Array) -> void:
	state.exploration_chain_timer = maxf(0.0, state.exploration_chain_timer - delta)
	if state.exploration_chain_timer <= 0.0:
		state.exploration_chain = 0
	var source_events = events.duplicate()
	for event in source_events:
		if not CHAIN_EVENTS.has(String(event.get("type", ""))):
			continue
		_increment(state, events)

func _increment(state, events: Array) -> void:
	state.exploration_chain += 1
	state.exploration_chain_max = maxi(state.exploration_chain_max, state.exploration_chain)
	state.exploration_chain_timer = float(state.exploration_chain_defs.get("window_seconds", 60.0)) + 8.0 * float(state.passives.get("chain_reward", 0))
	var threshold: Dictionary = state.exploration_chain_defs.get("thresholds", {}).get(str(state.exploration_chain), {})
	var effect_message = ""
	if not threshold.is_empty():
		effect_message = String(threshold.get("message_ja", "探索ボーナス"))
		state.exploration_chain_currency_bonus += int(threshold.get("currency_bonus", 0))
		if threshold.has("drop_rate_multiplier"):
			state.dynamic_drop_rate_multiplier = float(threshold.get("drop_rate_multiplier", 1.0))
			state.dynamic_drop_rate_timer = float(threshold.get("duration", 60.0))
		if threshold.has("fever_seconds"):
			state.gem_fever_timer = maxf(state.gem_fever_timer, float(threshold.get("fever_seconds", 8.0)))
			state.gem_fever_tier = maxi(state.gem_fever_tier, 1)
		if threshold.has("rare_drop_multiplier"):
			state.rare_drop_multiplier = float(threshold.get("rare_drop_multiplier", 1.0))
			state.rare_drop_bonus_timer = float(threshold.get("duration", 90.0))
	events.append({
		"type": "exploration_chain",
		"chain": state.exploration_chain,
		"max_chain": state.exploration_chain_max,
		"message": effect_message
	})
