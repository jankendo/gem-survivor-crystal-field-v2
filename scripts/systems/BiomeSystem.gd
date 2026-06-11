extends RefCounted
class_name BiomeSystem

var biome_defs: Dictionary = {}

func _init() -> void:
	biome_defs = _load_biomes()

func biome_count() -> int:
	return biome_defs.keys().size()

func biome_for_position(state, pos: Vector2) -> Dictionary:
	var fallback = {}
	var runtime_biomes: Dictionary = state.map_data.get("biomes", {}) if state != null and state.map_data is Dictionary else {}
	for raw_id in biome_defs.keys():
		var id = String(raw_id)
		var data: Dictionary = biome_defs[id].duplicate(true)
		if runtime_biomes.has(id):
			for key in runtime_biomes[id].keys():
				data[key] = runtime_biomes[id][key]
		if fallback.is_empty():
			fallback = _with_id(id, data)
		var rect_data = data.get("rect", [])
		if rect_data.size() < 4:
			continue
		var rect = Rect2(Vector2(float(rect_data[0]) * state.field_size.x, float(rect_data[1]) * state.field_size.y), Vector2(float(rect_data[2]) * state.field_size.x, float(rect_data[3]) * state.field_size.y))
		if rect.has_point(pos):
			return _with_id(id, data)
	return fallback

func biome_id_for_position(state, pos: Vector2) -> String:
	return String(biome_for_position(state, pos).get("id", "star_plain"))

func current_biome(state) -> Dictionary:
	var data = biome_for_position(state, state.player_position)
	if state.elapsed_seconds >= 1200.0 and String(data.get("id", "")) == "star_plain":
		return _with_id("void_zone", biome_defs.get("void_zone", data))
	return data

func bg_color(data: Dictionary) -> Color:
	return _color_from_array(data.get("bg_color", [0.025, 0.036, 0.070]))

func grid_color(data: Dictionary) -> Color:
	return _color_from_array(data.get("grid_color", [0.18, 0.28, 0.42]))

func accent_color(data: Dictionary) -> Color:
	return _color_from_array(data.get("accent_color", [0.42, 0.82, 1.0]))

func crystal_hp_multiplier(data: Dictionary) -> float:
	return float(data.get("crystal_hp_multiplier", 1.0))

func danger_density(data: Dictionary) -> float:
	return float(data.get("danger_density", 1.0))

func all_biomes() -> Array:
	var result: Array = []
	for id in biome_defs.keys():
		result.append(_with_id(String(id), biome_defs[id]))
	return result

func _with_id(id: String, data: Dictionary) -> Dictionary:
	var copy = data.duplicate(true)
	copy["id"] = id
	return copy

func _load_biomes() -> Dictionary:
	if not FileAccess.file_exists("res://data/biomes.json"):
		return _fallback()
	var file = FileAccess.open("res://data/biomes.json", FileAccess.READ)
	if file == null:
		return _fallback()
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return _fallback()

func _color_from_array(values: Array) -> Color:
	if values.size() < 3:
		return Color(0.02, 0.03, 0.06)
	return Color(float(values[0]), float(values[1]), float(values[2]), 1.0)

func _fallback() -> Dictionary:
	return {
		"star_plain": {"name_ja": "星屑平原", "rect": [0.0, 0.0, 0.52, 0.52], "bg_color": [0.025, 0.036, 0.070], "grid_color": [0.18, 0.28, 0.42], "accent_color": [0.42, 0.82, 1.0], "crystal_hp_multiplier": 1.0, "danger_density": 0.8},
		"amethyst_forest": {"name_ja": "紫晶の森", "rect": [0.48, 0.0, 0.52, 0.55], "bg_color": [0.050, 0.025, 0.082], "grid_color": [0.40, 0.22, 0.62], "accent_color": [0.78, 0.45, 1.0], "crystal_hp_multiplier": 1.5, "danger_density": 1.0},
		"red_mine": {"name_ja": "赤熱鉱床", "rect": [0.0, 0.48, 0.56, 0.52], "bg_color": [0.072, 0.035, 0.030], "grid_color": [0.64, 0.28, 0.16], "accent_color": [1.0, 0.44, 0.18], "crystal_hp_multiplier": 1.8, "danger_density": 1.35},
		"void_zone": {"name_ja": "虚無領域", "rect": [0.52, 0.50, 0.48, 0.50], "bg_color": [0.018, 0.012, 0.035], "grid_color": [0.32, 0.16, 0.48], "accent_color": [0.68, 0.22, 1.0], "crystal_hp_multiplier": 2.2, "danger_density": 1.6}
	}
