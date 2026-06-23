extends RefCounted
class_name V2ThemeProvider

const THEME_PATH := "res://data/v2_visual_theme.json"

var data: Dictionary = {}

func _init(path: String = THEME_PATH) -> void:
	data = _json_dict(path, {})

func color(id: String, fallback: Color = Color.WHITE) -> Color:
	var colors: Dictionary = data.get("colors", {})
	if not colors.has(id):
		return fallback
	return Color.html(String(colors[id]))

func spacing(id: String, fallback: float) -> float:
	return float(data.get("spacing", {}).get(id, fallback))

func font_size(id: String, fallback: int) -> int:
	return int(data.get("font_sizes", {}).get(id, fallback))

func panel_style(accent: Color, filled: bool = true) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color("panel", Color(0.08, 0.11, 0.18))
	if not filled:
		box.bg_color.a = 0.72
	box.border_color = accent
	box.set_border_width_all(int(data.get("shape", {}).get("border_width", 2)))
	box.set_corner_radius_all(int(data.get("shape", {}).get("corner_radius", 8)))
	box.content_margin_left = spacing("card_padding", 14.0)
	box.content_margin_right = spacing("card_padding", 14.0)
	box.content_margin_top = spacing("card_padding", 14.0)
	box.content_margin_bottom = spacing("card_padding", 14.0)
	box.shadow_color = Color(0.0, 0.0, 0.0, float(data.get("shape", {}).get("shadow_alpha", 0.35)))
	box.shadow_size = 8
	return box

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
