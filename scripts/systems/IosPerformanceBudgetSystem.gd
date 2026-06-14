extends RefCounted
class_name IosPerformanceBudgetSystem

const BUDGET_PATH := "res://data/ios_performance_budget.json"

var values: Dictionary = {}

func _init() -> void:
	reload()

func reload() -> void:
	values = _load_json(BUDGET_PATH).get("ios", {}).duplicate(true)

func get_int(key: String, fallback: int) -> int:
	return int(values.get(key, fallback))

func get_float(key: String, fallback: float) -> float:
	return float(values.get(key, fallback))

func within(key: String, value: float) -> bool:
	return value <= float(values.get(key, INF))

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
