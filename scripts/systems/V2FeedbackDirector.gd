extends RefCounted
class_name V2FeedbackDirector

const CONFIG_PATH := "res://data/v2_feedback.json"

var config: Dictionary = {}
var current: Dictionary = {}
var queue: Array = []
var recent: Dictionary = {}
var suppressed_count := 0
var banner_count := 0

func _init(path: String = CONFIG_PATH) -> void:
	config = _json_dict(path, {"enabled": true, "events": {}})

func ingest(event: Dictionary, now: float) -> void:
	if not bool(config.get("enabled", true)):
		return
	var item := _item_from_event(event, now)
	if item.is_empty():
		return
	var key := String(item.get("dedupe_key", ""))
	var dedupe_window := float(config.get("dedupe_window_seconds", 1.25))
	if key != "" and recent.has(key) and now - float(recent[key]) < dedupe_window:
		suppressed_count += 1
		return
	if key != "":
		recent[key] = now
	if current.is_empty():
		_show(item)
		return
	if int(item.get("priority_value", 0)) > int(current.get("priority_value", 0)):
		current = item
		banner_count += 1
		return
	_enqueue(item)

func tick(delta: float, paused: bool = false) -> void:
	if paused:
		return
	if not current.is_empty():
		current["remaining"] = maxf(0.0, float(current.get("remaining", 0.0)) - delta)
		if float(current.get("remaining", 0.0)) <= 0.0:
			current = {}
	if current.is_empty() and not queue.is_empty():
		_show(queue.pop_front())

func active_text() -> String:
	if current.is_empty():
		return ""
	var title := String(current.get("title", ""))
	var body := String(current.get("body", ""))
	if body == "":
		return title
	return "%s\n%s" % [title, body]

func active_accent() -> String:
	return String(current.get("accent", "crystal")) if not current.is_empty() else "crystal"

func queue_size() -> int:
	return queue.size()

func active_priority() -> int:
	return int(current.get("priority_value", 0))

func _show(item: Dictionary) -> void:
	current = item
	banner_count += 1

func _enqueue(item: Dictionary) -> void:
	var max_queue := int(config.get("max_queue", 4))
	if queue.size() >= max_queue:
		var weakest_index := _weakest_queue_index()
		if weakest_index >= 0 and int(item.get("priority_value", 0)) > int(queue[weakest_index].get("priority_value", 0)):
			queue.remove_at(weakest_index)
		else:
			suppressed_count += 1
			return
	queue.append(item)
	queue.sort_custom(_sort_priority_desc)

func _sort_priority_desc(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("priority_value", 0)) > int(b.get("priority_value", 0))

func _weakest_queue_index() -> int:
	var index := -1
	var weakest := 999999
	for i in range(queue.size()):
		var value := int(queue[i].get("priority_value", 0))
		if value < weakest:
			weakest = value
			index = i
	return index

func _item_from_event(event: Dictionary, now: float) -> Dictionary:
	var type := String(event.get("type", ""))
	var mapped_type := type
	if type == "enemy_die" and bool(event.get("boss", false)):
		mapped_type = "boss_defeat"
	if type in ["characters_unlocked", "weapons_unlocked", "passives_unlocked"]:
		mapped_type = "unlock"
	var defs: Dictionary = config.get("events", {})
	if not defs.has(mapped_type):
		return {}
	var rule: Dictionary = defs.get(mapped_type, {})
	var priorities: Dictionary = config.get("priorities", {})
	var priority_name := String(rule.get("priority", "normal"))
	var title := String(rule.get("title", mapped_type))
	var body := _body_for_event(type, event)
	return {
		"type": mapped_type,
		"title": title,
		"body": body,
		"accent": String(rule.get("accent", "crystal")),
		"priority": priority_name,
		"priority_value": int(priorities.get(priority_name, 50)),
		"remaining": float(rule.get("duration", config.get("default_duration", 2.6))),
		"created_at": now,
		"dedupe_key": _dedupe_key(mapped_type, event)
	}

func _body_for_event(type: String, event: Dictionary) -> String:
	match type:
		"v2_momentum":
			return "%s  Tier %d  x%.2f" % [String(event.get("label", "Momentum")), int(event.get("tier", 1)), float(event.get("score_multiplier", 1.0))]
		"v2_momentum_tier_up":
			return "%s  Tier %d" % [String(event.get("label", "Momentum")), int(event.get("tier", 1))]
		"v2_momentum_ending":
			return "残り %.1f 秒" % float(event.get("remaining", 0.0))
		"evolution":
			return String(event.get("name", event.get("evolution", "")))
		"character_evolution":
			return String(event.get("name", ""))
		"boss_spawn", "boss_warning":
			return String(event.get("name", event.get("message", "")))
		"global_gem_collection":
			return "%d個 / EXP %d" % [int(event.get("count", 0)), int(event.get("exp", 0))]
		"build_synergy":
			return String(event.get("name", event.get("id", "")))
		_:
			return String(event.get("message", event.get("name", "")))

func _dedupe_key(type: String, event: Dictionary) -> String:
	match type:
		"v2_momentum", "v2_momentum_tier_up":
			return "%s:%s:%d" % [type, String(event.get("label", "")), int(event.get("tier", 0))]
		"global_gem_collection":
			return "%s:%s:%d" % [type, String(event.get("source", "")), int(event.get("count", 0))]
		"evolution":
			return "%s:%s" % [type, String(event.get("evolution", event.get("weapon", "")))]
		"character_evolution":
			return "%s:%s" % [type, String(event.get("character", ""))]
		"build_synergy":
			return "%s:%s" % [type, String(event.get("id", ""))]
		_:
			return "%s:%s" % [type, String(event.get("name", event.get("message", "")))]

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
