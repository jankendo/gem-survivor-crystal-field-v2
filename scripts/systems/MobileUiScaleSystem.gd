extends RefCounted
class_name MobileUiScaleSystem

const CONFIG_PATH := "res://data/mobile_ui_scale.json"

var config: Dictionary = {}

func _init() -> void:
	config = _load_config()

func classify(viewport_size: Vector2) -> String:
	var breakpoints: Dictionary = config.get("breakpoints", {})
	var aspect := viewport_size.x / maxf(1.0, viewport_size.y)
	var tablet_min := float(breakpoints.get("tablet_min_width", 2300.0))
	var tablet_aspect := float(breakpoints.get("tablet_max_aspect", 1.55))
	if viewport_size.x >= tablet_min and aspect <= tablet_aspect:
		return "tablet"
	if viewport_size.x <= float(breakpoints.get("compact_phone_max_width", 1599.0)):
		return "compact_phone"
	if viewport_size.x <= float(breakpoints.get("regular_phone_max_width", 2299.0)):
		return "regular_phone"
	return "large_phone"

func metrics(viewport_size: Vector2) -> Dictionary:
	var base: Dictionary = config.get("ios", {}).duplicate(true)
	var profile_name := classify(viewport_size)
	var profile: Dictionary = config.get("profiles", {}).get(profile_name, {}).duplicate(true)
	for key in profile.keys():
		base[key] = profile[key]
	base["profile"] = profile_name
	base["tablet"] = profile_name == "tablet"
	base["joystick_touch_extent"] = float(base.get("joystick_outer", 196.0)) * float(base.get("virtual_joystick_touch_scale", 1.30))
	return base

func character_visible_count(viewport_size: Vector2) -> int:
	return int(metrics(viewport_size).get("visible_characters", 3))

func _load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
