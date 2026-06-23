extends RefCounted
class_name V2AssetRegistry

const MANIFEST_PATH := "res://data/asset_manifest.json"

var manifest_path := MANIFEST_PATH
var manifest: Dictionary = {}
var assets_by_id: Dictionary = {}

func _init(path: String = MANIFEST_PATH) -> void:
	manifest_path = path
	reload()

func reload() -> void:
	manifest = _json_dict(manifest_path, {"assets": []})
	assets_by_id.clear()
	for entry in manifest.get("assets", []):
		if not entry is Dictionary:
			continue
		var asset_id := String(entry.get("asset_id", ""))
		if asset_id == "":
			continue
		assets_by_id[asset_id] = entry

func has_asset(asset_id: String) -> bool:
	return assets_by_id.has(asset_id)

func asset_entry(asset_id: String) -> Dictionary:
	return assets_by_id.get(asset_id, {}).duplicate(true)

func resolve_path(asset_id: String) -> String:
	var entry: Dictionary = assets_by_id.get(asset_id, {})
	if entry.is_empty():
		return ""
	var status := String(entry.get("replacement_status", "fallback"))
	var future_path := String(entry.get("future_path", ""))
	if status in ["candidate", "approved"] and future_path != "" and ResourceLoader.exists(future_path):
		return future_path
	var current_source := String(entry.get("current_source", ""))
	if current_source != "" and ResourceLoader.exists(current_source):
		return current_source
	if future_path != "" and ResourceLoader.exists(future_path):
		return future_path
	return ""

func category_entries(category: String) -> Array:
	var result: Array = []
	for entry in assets_by_id.values():
		if String(entry.get("category", "")) == category:
			result.append(entry.duplicate(true))
	return result

func replacement_status_counts() -> Dictionary:
	var counts: Dictionary = {}
	for entry in assets_by_id.values():
		var status := String(entry.get("replacement_status", "unknown"))
		counts[status] = int(counts.get(status, 0)) + 1
	return counts

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

