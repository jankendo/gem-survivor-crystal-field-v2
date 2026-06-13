extends RefCounted
class_name IosLayoutDiagnosticSystem

const MobileSafeAreaSystemScript = preload("res://scripts/systems/MobileSafeAreaSystem.gd")
const MobileHudLayoutSystemScript = preload("res://scripts/systems/MobileHudLayoutSystem.gd")
const MobileUiScaleSystemScript = preload("res://scripts/systems/MobileUiScaleSystem.gd")
const MobileMapSystemScript = preload("res://scripts/systems/MobileMapSystem.gd")

var safe_system = MobileSafeAreaSystemScript.new()
var hud_system = MobileHudLayoutSystemScript.new()
var ui_system = MobileUiScaleSystemScript.new()
var map_system = MobileMapSystemScript.new()

func snapshot(viewport_size: Vector2, settings: Dictionary = {}) -> Dictionary:
	var safe := safe_system.safe_rect(viewport_size, maxf(16.0, float(settings.get("safe_area_margin", 16.0))))
	var hud := hud_system.layout(viewport_size, safe, settings)
	var metrics := ui_system.metrics(viewport_size)
	var map_settings := map_system.settings_for(viewport_size, settings)
	return {
		"viewport": _rect_data(Rect2(Vector2.ZERO, viewport_size)),
		"safe_area": _rect_data(safe),
		"profile": metrics.get("profile", ""),
		"visible_characters": metrics.get("visible_characters", 0),
		"character_card": {
			"width": metrics.get("character_card_width", 0),
			"height": metrics.get("character_card_height", 0)
		},
		"joystick_visual_extent": hud.get("joystick_visual_extent", 0),
		"joystick_touch_extent": hud.get("joystick_touch_extent", 0),
		"action_button_extent": hud.get("button_extent", 0),
		"joystick_rect": _rect_data(hud.get("joystick_rect", Rect2())),
		"actions_rect": _rect_data(hud.get("actions_rect", Rect2())),
		"minimap_rect": _rect_data(hud.get("minimap_rect", Rect2())),
		"pause_rect": _rect_data(hud.get("pause_rect", Rect2())),
		"minimap_size": map_settings.get("minimap_size", 0),
		"minimap_icon": map_settings.get("minimap_icon", 0),
		"camera_zoom": map_settings.get("camera_zoom", 1.0),
		"debug_overlay": false
	}

func export_snapshots(path: String, sizes: Array, settings: Dictionary = {}) -> bool:
	var rows: Array = []
	for size in sizes:
		rows.append(snapshot(size, settings))
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"layouts": rows}, "\t"))
	return true

func _rect_data(rect: Rect2) -> Dictionary:
	return {
		"x": rect.position.x,
		"y": rect.position.y,
		"width": rect.size.x,
		"height": rect.size.y
	}
