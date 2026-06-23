extends RefCounted
class_name V2MomentumSystem

const CONFIG_PATH := "res://data/v2_momentum.json"

var config: Dictionary = {}

func _init() -> void:
	config = _json_dict(CONFIG_PATH, {"enabled": false})

func process(state, delta: float, events: Array) -> void:
	var defs: Dictionary = state.v2_momentum_defs if not state.v2_momentum_defs.is_empty() else config
	if not bool(defs.get("enabled", true)):
		return
	_tick_state(state, delta, defs, events)
	var original_count := events.size()
	for i in range(original_count):
		_consume_event(state, events[i], defs, events)

func _tick_state(state, delta: float, defs: Dictionary, events: Array) -> void:
	state.v2_momentum_timer = maxf(0.0, float(state.v2_momentum_timer) - delta)
	if state.v2_momentum_timer <= 0.0:
		state.v2_momentum_tier = 0
		state.v2_momentum_label = ""
		state.v2_momentum_score_multiplier = 1.0
	state.v2_kill_streak_timer = maxf(0.0, float(state.v2_kill_streak_timer) - delta)
	if state.v2_kill_streak_timer <= 0.0:
		state.v2_kill_streak = 0
	state.v2_no_damage_timer += delta
	state.v2_no_damage_best = maxf(float(state.v2_no_damage_best), float(state.v2_no_damage_timer))
	_check_no_damage_milestone(state, defs, events)

func _consume_event(state, event: Dictionary, defs: Dictionary, events: Array) -> void:
	var event_type := String(event.get("type", ""))
	if event_type == "enemy_die":
		_record_kill(state, defs, events)
		var enemy_id := String(event.get("enemy", ""))
		if enemy_id != "" and state.boss_defs.has(enemy_id):
			_trigger_named(state, defs, events, "boss_defeat")
	elif event_type == "player_damage":
		state.v2_no_damage_timer = 0.0
		state.v2_no_damage_next_milestone = 0
	elif event_type == "evolution":
		_trigger_named(state, defs, events, "evolution")
	elif event_type == "global_gem_collection":
		var trigger: Dictionary = defs.get("special_triggers", {}).get("global_gem_collection", {})
		if int(event.get("count", 0)) >= int(trigger.get("min_count", 1)):
			_activate(state, trigger, events, defs)
	elif event_type == "build_synergy":
		_trigger_named(state, defs, events, "build_synergy")
	elif event_type == "field_event_success":
		_trigger_named(state, defs, events, "field_event_success")

func _record_kill(state, defs: Dictionary, events: Array) -> void:
	state.v2_kill_streak += 1
	state.v2_best_kill_streak = maxi(int(state.v2_best_kill_streak), int(state.v2_kill_streak))
	state.v2_kill_streak_timer = float(defs.get("kill_streak_window_seconds", 4.0))
	var tier_entry := _tier_for_kills(defs, int(state.v2_kill_streak))
	if tier_entry.is_empty():
		return
	if int(tier_entry.get("tier", 0)) > int(state.v2_momentum_tier) or state.v2_momentum_timer <= 0.0:
		_activate(state, tier_entry, events, defs)

func _tier_for_kills(defs: Dictionary, kills: int) -> Dictionary:
	var result: Dictionary = {}
	for entry in defs.get("kill_streak_tiers", []):
		if not entry is Dictionary:
			continue
		if kills >= int(entry.get("kills", 0)):
			if result.is_empty() or int(entry.get("tier", 0)) >= int(result.get("tier", 0)):
				result = entry
	return result

func _check_no_damage_milestone(state, defs: Dictionary, events: Array) -> void:
	var milestones: Array = defs.get("no_damage_milestones", [])
	var index := int(state.v2_no_damage_next_milestone)
	if index < 0 or index >= milestones.size():
		return
	var entry = milestones[index]
	if not entry is Dictionary:
		state.v2_no_damage_next_milestone += 1
		return
	if float(state.v2_no_damage_timer) >= float(entry.get("seconds", 0.0)):
		state.v2_no_damage_next_milestone += 1
		_activate(state, entry, events, defs)

func _trigger_named(state, defs: Dictionary, events: Array, id: String) -> void:
	var trigger: Dictionary = defs.get("special_triggers", {}).get(id, {})
	if trigger.is_empty():
		return
	_activate(state, trigger, events, defs)

func _activate(state, entry: Dictionary, events: Array, defs: Dictionary) -> void:
	if entry.is_empty():
		return
	var tier := int(entry.get("tier", 1))
	var label := String(entry.get("label", "Momentum"))
	var duration := float(entry.get("duration", 8.0))
	var multiplier := float(entry.get("score_multiplier", 1.0))
	if tier < int(state.v2_momentum_tier) and state.v2_momentum_timer > duration * 0.5:
		return
	state.v2_momentum_tier = tier
	state.v2_peak_momentum_tier = maxi(int(state.v2_peak_momentum_tier), tier)
	state.v2_momentum_label = label
	state.v2_momentum_timer = maxf(float(state.v2_momentum_timer), duration)
	state.v2_momentum_score_multiplier = maxf(float(state.v2_momentum_score_multiplier), multiplier)
	state.v2_momentum_triggers += 1
	var row := {
		"label": label,
		"tier": tier,
		"time": float(state.elapsed_seconds),
		"duration": duration,
		"score_multiplier": multiplier
	}
	state.v2_momentum_history.push_front(row)
	var max_history := int(defs.get("max_history", 8))
	if state.v2_momentum_history.size() > max_history:
		state.v2_momentum_history.resize(max_history)
	events.append({
		"type": "v2_momentum",
		"label": label,
		"tier": tier,
		"duration": duration,
		"score_multiplier": multiplier,
		"message": String(entry.get("message", label))
	})

func _json_dict(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback.duplicate(true)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return fallback.duplicate(true)
