extends RefCounted
class_name V2AssetRegistry

const MANIFEST_PATH := "res://data/asset_manifest.json"

var manifest_path := MANIFEST_PATH
var manifest: Dictionary = {}
var assets_by_id: Dictionary = {}
var texture_cache: Dictionary = {}

func _init(path: String = MANIFEST_PATH) -> void:
	manifest_path = path
	reload()

func reload() -> void:
	manifest = _json_dict(manifest_path, {"assets": []})
	assets_by_id.clear()
	texture_cache.clear()
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
	var preferred_path := String(entry.get("preferred_path", entry.get("future_path", "")))
	if status in ["generated", "integrated", "approved"] and preferred_path != "" and _resource_exists(preferred_path):
		return preferred_path
	var fallback_path := String(entry.get("fallback_path", entry.get("current_source", "")))
	if fallback_path != "" and _resource_exists(fallback_path):
		return fallback_path
	if preferred_path != "" and _resource_exists(preferred_path):
		return preferred_path
	return ""

func resolve_texture(asset_id: String):
	var path := resolve_path(asset_id)
	if path == "":
		return null
	if texture_cache.has(path):
		return texture_cache[path]
	var resource = null
	if path.get_extension().to_lower() == "png" and FileAccess.file_exists(path):
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image != null and not image.is_empty():
			resource = ImageTexture.create_from_image(image)
	if resource == null:
		resource = load(path)
	texture_cache[path] = resource
	return resource

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

func _resource_exists(path: String) -> bool:
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)

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
