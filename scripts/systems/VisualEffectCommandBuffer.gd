extends RefCounted
class_name VisualEffectCommandBuffer

const VisualEffectCoalescerScript = preload("res://scripts/systems/VisualEffectCoalescer.gd")

const PRIORITY_CRITICAL := 0
const PRIORITY_SIGNATURE := 1
const PRIORITY_COMBAT := 2
const PRIORITY_DECORATIVE := 3

var capacity_by_type := {
	"hit_flash": 220,
	"effect_line": 220,
	"damage_text": 100,
}
var coalescer = VisualEffectCoalescerScript.new()
var metrics_enabled := false
var metrics: Dictionary = {}
var recent_indexes: Dictionary = {}
var last_sizes: Dictionary = {}

func configure(capacities: Dictionary, enable_metrics: bool = false) -> void:
	for key in capacities:
		capacity_by_type[String(key)] = maxi(1, int(capacities[key]))
	metrics_enabled = enable_metrics
	metrics.clear()
	recent_indexes.clear()
	last_sizes.clear()

func append(
		target: Array,
		type_id: String,
		data: Dictionary,
		pool_manager,
		now_seconds: float
	) -> bool:
	var command := data
	command["priority"] = priority_of(command)
	command["created_at"] = now_seconds
	command["effect_kind"] = String(command.get("effect_kind", type_id))
	_count("created", command)
	if target.size() < int(last_sizes.get(type_id, 0)):
		recent_indexes[type_id] = {}
	var type_indexes: Dictionary = recent_indexes.get(type_id, {})
	var command_key := coalescer.key_for(command)
	var match_index := int(type_indexes.get(command_key, -1))
	if match_index >= target.size():
		match_index = -1
	if match_index >= 0:
		var candidate: Dictionary = target[match_index]
		if (
			now_seconds - float(candidate.get("created_at", now_seconds)) > VisualEffectCoalescerScript.DEFAULT_WINDOW_SECONDS
			or coalescer.key_for(candidate) != command_key
		):
			match_index = -1
	if match_index >= 0:
		coalescer.merge(target[match_index], command)
		_count("coalesced", command)
		last_sizes[type_id] = target.size()
		return true
	var capacity := int(capacity_by_type.get(type_id, 128))
	if target.size() >= capacity and int(command["priority"]) != PRIORITY_CRITICAL:
		_count("rejected", command)
		last_sizes[type_id] = target.size()
		return false
	var pooled = pool_manager.acquire(type_id, [command])
	if pooled == null:
		_count("rejected", command)
		return false
	target.append(pooled)
	type_indexes[command_key] = target.size() - 1
	recent_indexes[type_id] = type_indexes
	last_sizes[type_id] = target.size()
	_count("accepted", command)
	return true

func priority_of(data: Dictionary) -> int:
	if data.has("priority"):
		var raw = data["priority"]
		if raw is int:
			return clampi(int(raw), PRIORITY_CRITICAL, PRIORITY_DECORATIVE)
		match String(raw).to_upper():
			"CRITICAL":
				return PRIORITY_CRITICAL
			"SIGNATURE":
				return PRIORITY_SIGNATURE
			"DECORATIVE":
				return PRIORITY_DECORATIVE
			_:
				return PRIORITY_COMBAT
	if bool(data.get("critical", false)) or String(data.get("effect_kind", "")) in [
		"enemy_warning", "boss_warning", "player_hit", "danger_zone", "important_reward"
	]:
		return PRIORITY_CRITICAL
	if bool(data.get("evolved", false)) or bool(data.get("signature", false)):
		return PRIORITY_SIGNATURE
	if bool(data.get("decorative", false)):
		return PRIORITY_DECORATIVE
	return PRIORITY_COMBAT

func snapshot() -> Dictionary:
	return metrics.duplicate(true) if metrics_enabled else {"enabled": false}

func _count(kind: String, data: Dictionary) -> void:
	if not metrics_enabled:
		return
	metrics["enabled"] = true
	metrics[kind] = int(metrics.get(kind, 0)) + 1
	var source := String(data.get("source", data.get("weapon_id", "unknown")))
	var priority := str(priority_of(data))
	var source_key := "%s_by_source" % kind
	var priority_key := "%s_by_priority" % kind
	var by_source: Dictionary = metrics.get(source_key, {})
	var by_priority: Dictionary = metrics.get(priority_key, {})
	by_source[source] = int(by_source.get(source, 0)) + 1
	by_priority[priority] = int(by_priority.get(priority, 0)) + 1
	metrics[source_key] = by_source
	metrics[priority_key] = by_priority
