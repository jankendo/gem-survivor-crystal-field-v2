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
	var active_before := float(state.v2_momentum_timer) > 0.0
	var multiplier_before := float(state.v2_momentum_score_multiplier) if active_before else 1.0
	state.v2_momentum_weighted_time += delta
	state.v2_momentum_weighted_multiplier_sum += multiplier_before * delta
	if active_before:
		state.v2_momentum_active_time_total += delta
		var warning_seconds := float(defs.get("ending_warning_seconds", 2.5))
		if not bool(state.v2_momentum_ending_warned) and float(state.v2_momentum_timer) <= warning_seconds + delta:
			state.v2_momentum_ending_warned = true
			events.append({
				"type": "v2_momentum_ending",
				"remaining": maxf(0.0, float(state.v2_momentum_timer) - delta),
				"label": String(state.v2_momentum_label)
			})
	state.v2_momentum_timer = maxf(0.0, float(state.v2_momentum_timer) - delta)
	if state.v2_momentum_timer <= 0.0:
		state.v2_momentum_tier = 0
		state.v2_momentum_label = ""
		state.v2_momentum_reason = ""
		state.v2_momentum_trigger_type = ""
		state.v2_momentum_score_multiplier = 1.0
		state.v2_momentum_ending_warned = false
	state.v2_kill_streak_timer = maxf(0.0, float(state.v2_kill_streak_timer) - delta)
	if state.v2_kill_streak_timer <= 0.0:
		state.v2_kill_streak = 0
	state.v2_no_damage_timer += delta
	state.v2_no_damage_best = maxf(float(state.v2_no_damage_best), float(state.v2_no_damage_timer))
	_prune_recent_keys(state, float(state.elapsed_seconds), float(defs.get("dedupe_window_seconds", 0.35)))
	_check_no_damage_milestone(state, defs, events)

func _consume_event(state, event: Dictionary, defs: Dictionary, events: Array) -> void:
	var event_type := String(event.get("type", ""))
	if event_type == "enemy_die":
		_record_kill(state, defs, events)
		var enemy_id := String(event.get("enemy", ""))
		if enemy_id != "" and state.boss_defs.has(enemy_id):
			_trigger_named(state, defs, events, "boss_defeat", event)
	elif event_type == "player_damage":
		state.v2_no_damage_timer = 0.0
		state.v2_no_damage_next_milestone = 0
	elif event_type == "evolution":
		_trigger_named(state, defs, events, "evolution", event)
	elif event_type == "global_gem_collection":
		var trigger: Dictionary = defs.get("special_triggers", {}).get("global_gem_collection", {})
		if int(event.get("count", 0)) >= int(trigger.get("min_count", 1)):
			_activate(state, trigger, events, defs, "global_gem_collection", event)
	elif event_type == "build_synergy":
		_trigger_named(state, defs, events, "build_synergy", event)
	elif event_type == "field_event_success":
		_trigger_named(state, defs, events, "field_event_success", event)

func _record_kill(state, defs: Dictionary, events: Array) -> void:
	state.v2_kill_streak += 1
	state.v2_best_kill_streak = maxi(int(state.v2_best_kill_streak), int(state.v2_kill_streak))
	state.v2_kill_streak_timer = float(defs.get("kill_streak_window_seconds", 4.0))
	var tier_entry := _tier_for_kills(defs, int(state.v2_kill_streak))
	if tier_entry.is_empty():
		return
	if int(tier_entry.get("tier", 0)) > int(state.v2_momentum_tier) or state.v2_momentum_timer <= 0.0:
		_activate(state, tier_entry, events, defs, "kill_streak", {"kills": state.v2_kill_streak})

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
		_activate(state, entry, events, defs, "no_damage", {"seconds": entry.get("seconds", 0.0)})

func _trigger_named(state, defs: Dictionary, events: Array, id: String, event: Dictionary = {}) -> void:
	var trigger: Dictionary = defs.get("special_triggers", {}).get(id, {})
	if trigger.is_empty():
		return
	_activate(state, trigger, events, defs, id, event)

func _activate(state, entry: Dictionary, events: Array, defs: Dictionary, trigger_type: String, source_event: Dictionary = {}) -> void:
	if entry.is_empty():
		return
	var key := _dedupe_key(trigger_type, source_event, entry)
	var now := float(state.elapsed_seconds)
	var dedupe_window := float(defs.get("dedupe_window_seconds", 0.35))
	if key != "" and state.v2_momentum_recent_event_keys.has(key):
		if now - float(state.v2_momentum_recent_event_keys[key]) <= dedupe_window:
			state.v2_momentum_suppressed_duplicates += 1
			return
	if key != "":
		state.v2_momentum_recent_event_keys[key] = now
	var tier := int(entry.get("tier", 1))
	var label := String(entry.get("label", "ラッシュ"))
	var duration := float(entry.get("duration", 8.0))
	var multiplier := float(entry.get("score_multiplier", 1.0))
	if tier < int(state.v2_momentum_tier) and state.v2_momentum_timer > duration * 0.5:
		return
	var previous_tier := int(state.v2_momentum_tier)
	state.v2_momentum_tier = tier
	state.v2_peak_momentum_tier = maxi(int(state.v2_peak_momentum_tier), tier)
	state.v2_momentum_label = label
	state.v2_momentum_reason = label
	state.v2_momentum_trigger_type = trigger_type
	state.v2_momentum_timer = maxf(float(state.v2_momentum_timer), duration)
	state.v2_momentum_score_multiplier = maxf(float(state.v2_momentum_score_multiplier), multiplier)
	state.v2_momentum_ending_warned = false
	state.v2_momentum_triggers += 1
	state.v2_momentum_trigger_counts[trigger_type] = int(state.v2_momentum_trigger_counts.get(trigger_type, 0)) + 1
	var row := {
		"label": label,
		"tier": tier,
		"time": float(state.elapsed_seconds),
		"duration": duration,
		"score_multiplier": multiplier,
		"trigger_type": trigger_type
	}
	state.v2_momentum_history.push_front(row)
	var max_history := int(defs.get("max_history", 8))
	if state.v2_momentum_history.size() > max_history:
		state.v2_momentum_history.resize(max_history)
	events.append({
		"type": "v2_momentum_tier_up" if previous_tier > 0 and tier > previous_tier else "v2_momentum",
		"label": label,
		"tier": tier,
		"duration": duration,
		"score_multiplier": multiplier,
		"trigger_type": trigger_type,
		"message": String(entry.get("message", label))
	})

func most_common_trigger(state) -> String:
	var best_key := ""
	var best_count := -1
	for key in state.v2_momentum_trigger_counts.keys():
		var count := int(state.v2_momentum_trigger_counts[key])
		if count > best_count:
			best_count = count
			best_key = String(key)
	return best_key

func summary(state) -> Dictionary:
	var weighted_time := maxf(0.001, float(state.v2_momentum_weighted_time))
	return {
		"peak_tier": int(state.v2_peak_momentum_tier),
		"trigger_count": int(state.v2_momentum_triggers),
		"active_time_total": float(state.v2_momentum_active_time_total),
		"score_bonus": int(state.v2_momentum_score_bonus),
		"score_base": int(state.v2_momentum_score_base),
		"weighted_multiplier": float(state.v2_momentum_weighted_multiplier_sum) / weighted_time,
		"trigger_counts": state.v2_momentum_trigger_counts.duplicate(true),
		"main_trigger": most_common_trigger(state),
		"suppressed_duplicates": int(state.v2_momentum_suppressed_duplicates)
	}

func _dedupe_key(trigger_type: String, source_event: Dictionary, entry: Dictionary) -> String:
	match trigger_type:
		"kill_streak":
			return ""
		"boss_defeat":
			return "boss_defeat:%s:%s" % [String(source_event.get("enemy", "")), str(source_event.get("kills", ""))]
		"evolution":
			return "evolution:%s:%s" % [String(source_event.get("weapon", "")), String(source_event.get("evolution", ""))]
		"global_gem_collection":
			return "global_gem_collection:%s:%d" % [String(source_event.get("source", "")), int(source_event.get("count", 0))]
		"build_synergy":
			return "build_synergy:%s" % String(source_event.get("id", ""))
		"field_event_success":
			return "field_event_success:%s" % String(source_event.get("id", source_event.get("name", "")))
		"no_damage":
			return "no_damage:%s" % str(source_event.get("seconds", entry.get("seconds", "")))
		_:
			return "%s:%s" % [trigger_type, String(entry.get("label", ""))]

func _prune_recent_keys(state, now: float, dedupe_window: float) -> void:
	for key in state.v2_momentum_recent_event_keys.keys():
		if now - float(state.v2_momentum_recent_event_keys[key]) > maxf(1.0, dedupe_window * 4.0):
			state.v2_momentum_recent_event_keys.erase(key)

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
