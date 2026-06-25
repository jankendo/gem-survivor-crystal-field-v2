extends RefCounted
class_name EnvironmentVisualSystem

const MANIFEST_PATH := "res://data/environment_asset_manifest.json"
const QUALITY_PATH := "res://data/environment_visual_quality.json"

var manifest: Dictionary = {}
var quality_config: Dictionary = {}
var texture_cache: Dictionary = {}

func _init(manifest_path: String = MANIFEST_PATH, quality_path: String = QUALITY_PATH) -> void:
	manifest = _json_dict(manifest_path, _fallback_manifest())
	quality_config = _json_dict(quality_path, _fallback_quality())

func biome_ids() -> Array:
	return (manifest.get("biomes", {}) as Dictionary).keys()

func biome_visual(biome_id: String) -> Dictionary:
	var biomes: Dictionary = manifest.get("biomes", {})
	if biomes.has(biome_id):
		return biomes[biome_id]
	if biomes.has("star_plain"):
		return biomes["star_plain"]
	return {}

func surface_entry(biome_id: String, surface: String) -> Dictionary:
	var biome := biome_visual(biome_id)
	var surfaces: Dictionary = biome.get("surfaces", {})
	if surfaces.has(surface):
		return surfaces[surface]
	if surfaces.has("floor"):
		return surfaces["floor"]
	return {}

func surface_path(biome_id: String, surface: String, material_kind: String = "albedo") -> String:
	var entry := surface_entry(biome_id, surface)
	var key := "%s_path" % material_kind
	return String(entry.get(key, entry.get("albedo_path", "")))

func surface_texture(biome_id: String, surface: String, material_kind: String = "albedo"):
	var path := surface_path(biome_id, surface, material_kind)
	if path == "":
		return null
	if texture_cache.has(path):
		return texture_cache[path]
	var texture = null
	if FileAccess.file_exists(path):
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image != null and not image.is_empty():
			texture = ImageTexture.create_from_image(image)
	if texture == null and ResourceLoader.exists(path):
		texture = load(path)
	texture_cache[path] = texture
	return texture

func background_color(biome_id: String, fallback: Color) -> Color:
	var palette: Dictionary = biome_visual(biome_id).get("palette", {})
	return _hex_color(String(palette.get("dark", "")), fallback)

func grid_color(biome_id: String, fallback: Color) -> Color:
	var palette: Dictionary = biome_visual(biome_id).get("palette", {})
	return _hex_color(String(palette.get("glow", "")), fallback)

func accent_color(biome_id: String, fallback: Color) -> Color:
	var palette: Dictionary = biome_visual(biome_id).get("palette", {})
	return _hex_color(String(palette.get("accent", "")), fallback)

func surface_color(biome_id: String, surface: String, fallback: Color) -> Color:
	var entry := surface_entry(biome_id, surface)
	var values: Array = entry.get("fallback_color", [])
	if values.size() >= 3:
		return Color(float(values[0]) / 255.0, float(values[1]) / 255.0, float(values[2]) / 255.0, fallback.a)
	return fallback

func terrain_color(biome_id: String, terrain_color_value: Color, terrain_id: String) -> Color:
	var floor_color := surface_color(biome_id, "floor", terrain_color_value)
	var terrain_weight := 0.42
	if terrain_id in ["danger_den", "boss_arena"]:
		terrain_weight = 0.56
	elif terrain_id in ["safe_room", "healing_oasis"]:
		terrain_weight = 0.32
	return floor_color.lerp(terrain_color_value, terrain_weight)

func quality_profile(name: String = "") -> Dictionary:
	var profiles: Dictionary = quality_config.get("profiles", {})
	var profile_name := name
	if profile_name == "":
		profile_name = String(quality_config.get("default_profile", "medium"))
	return profiles.get(profile_name, profiles.get("medium", _fallback_quality()["profiles"]["medium"]))

func tile_texture_alpha(profile_name: String = "") -> float:
	return float(quality_profile(profile_name).get("tile_texture_alpha", 0.86))

func texture_enabled(profile_name: String = "") -> bool:
	return bool(quality_profile(profile_name).get("texture_enabled", true))

func deterministic_variant(biome_id: String, surface: String, cell_key: String, seed: int = 0) -> int:
	var value := int(seed)
	var source := "%s|%s|%s" % [biome_id, surface, cell_key]
	for i in range(source.length()):
		value = int((value * 131 + source.unicode_at(i)) & 0x7fffffff)
	return value % 8

func manifest_summary() -> Dictionary:
	var result := {
		"biome_count": 0,
		"surface_count": 0,
		"integrated_count": 0,
		"needs_review_count": 0,
		"missing_path_count": 0
	}
	var biomes: Dictionary = manifest.get("biomes", {})
	result["biome_count"] = biomes.keys().size()
	for biome in biomes.values():
		var surfaces: Dictionary = biome.get("surfaces", {})
		for entry in surfaces.values():
			result["surface_count"] = int(result["surface_count"]) + 1
			if String(entry.get("replacement_status", "")) == "integrated":
				result["integrated_count"] = int(result["integrated_count"]) + 1
			if String(entry.get("human_review_status", "")) == "needs_review":
				result["needs_review_count"] = int(result["needs_review_count"]) + 1
			for key in ["albedo_path", "normal_path", "specular_path", "emission_path"]:
				var path := String(entry.get(key, ""))
				if path == "" or not FileAccess.file_exists(path):
					result["missing_path_count"] = int(result["missing_path_count"]) + 1
	return result

func _hex_color(value: String, fallback: Color) -> Color:
	var hex := value.trim_prefix("#")
	if hex.length() != 6:
		return fallback
	return Color(
		float(hex.substr(0, 2).hex_to_int()) / 255.0,
		float(hex.substr(2, 2).hex_to_int()) / 255.0,
		float(hex.substr(4, 2).hex_to_int()) / 255.0,
		fallback.a
	)

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

func _fallback_manifest() -> Dictionary:
	return {
		"schema_version": 1,
		"biomes": {
			"star_plain": {
				"name_ja": "星屑平原",
				"palette": {"dark": "#06111f", "glow": "#55dfff", "accent": "#d5fbff"},
				"surfaces": {
					"floor": {"fallback_color": [16, 37, 58], "replacement_status": "fallback", "human_review_status": "fallback"}
				}
			}
		}
	}

func _fallback_quality() -> Dictionary:
	return {
		"default_profile": "medium",
		"profiles": {
			"medium": {"texture_enabled": true, "material_maps": true, "tile_texture_alpha": 0.86}
		}
	}
