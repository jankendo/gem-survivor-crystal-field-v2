extends RefCounted
class_name JapaneseTextSystem

var data: Dictionary = {}

func _init() -> void:
	data = _json_dict("res://data/localization_ja.json", {})

func term(source: String) -> String:
	return String(data.get("terms", {}).get(source, source))

func text(key: String, fallback: String = "") -> String:
	var value := String(data.get(key, fallback))
	if value.strip_edges() == "":
		return fallback if fallback != "" else "表示文言が未設定です。"
	return value

func safe_label(value: String, fallback: String = "項目") -> String:
	var trimmed := value.strip_edges()
	if trimmed == "" or _looks_like_internal_id(trimmed):
		return fallback
	return trimmed

func _looks_like_internal_id(value: String) -> bool:
	return value.find("_") >= 0 and value.to_lower() == value

func _json_dict(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback.duplicate(true)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else fallback.duplicate(true)
