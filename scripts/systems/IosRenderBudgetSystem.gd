extends RefCounted
class_name IosRenderBudgetSystem

const PATH := "res://data/ios_energy_budget.json"

var profiles: Dictionary = {}

func _init() -> void:
	reload()

func reload() -> void:
	profiles = {}
	if FileAccess.file_exists(PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			profiles = parsed

func profile(profile_id: String) -> Dictionary:
	return profiles.get(profile_id, profiles.get("standard", {})).duplicate(true)

func value(profile_id: String, key: String, fallback):
	return profiles.get(profile_id, profiles.get("standard", {})).get(key, fallback)

func preserves_quality(profile_id: String) -> bool:
	return not bool(value(profile_id, "force_quality_reduction", false))
