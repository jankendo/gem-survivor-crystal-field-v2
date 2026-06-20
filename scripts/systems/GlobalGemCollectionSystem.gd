extends RefCounted
class_name GlobalGemCollectionSystem

const GemRegistryScript = preload("res://scripts/systems/GemRegistry.gd")
const GemCollectionBatchProcessorScript = preload("res://scripts/systems/GemCollectionBatchProcessor.gd")

var registry = GemRegistryScript.new()
var processor = GemCollectionBatchProcessorScript.new()
var config: Dictionary = {}

func _init() -> void:
	config = _json_dict("res://data/gem_collection_effects.json", {"global_collection": {"batch_size": 160}})

func collect_all(state, events: Array, source: String, value_multiplier: float = 1.0) -> Dictionary:
	return processor.collect(state, registry.active_gems(state), events, source, _batch_size(), value_multiplier)

func collect_nearby(state, center: Vector2, radius: float, events: Array, source: String, value_multiplier: float = 1.0) -> Dictionary:
	return processor.collect(state, registry.gems_in_radius(state, center, radius), events, source, _batch_size(), value_multiplier)

func active_count(state) -> int:
	return registry.active_count(state)

func _batch_size() -> int:
	return int(config.get("global_collection", {}).get("batch_size", 160))

func _json_dict(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback.duplicate(true)
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else fallback.duplicate(true)
