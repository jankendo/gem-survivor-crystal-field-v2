extends RefCounted
class_name AppVersionSystem

var data: Dictionary = {}

func _init() -> void:
	data = _json_dict("res://data/app_version.json", {
		"display_version": "0.3.0",
		"build_number": 3,
		"phase": "v2 Phase 3",
		"product_name_ja": "ジェムサバイバー：クリスタルフィールド"
	})

func display_version() -> String:
	return String(data.get("display_version", "0.3.0"))

func build_number() -> int:
	return int(data.get("build_number", 3))

func phase_label() -> String:
	return String(data.get("phase_ja", data.get("phase", "v2 Phase 3")))

func product_name_ja() -> String:
	return String(data.get("product_name_ja", "ジェムサバイバー：クリスタルフィールド"))

func title_version_line() -> String:
	return "%s  v%s  build %d" % [phase_label(), display_version(), build_number()]

func _json_dict(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback.duplicate(true)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else fallback.duplicate(true)
