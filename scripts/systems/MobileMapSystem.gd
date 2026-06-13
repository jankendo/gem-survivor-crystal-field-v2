extends RefCounted
class_name MobileMapSystem

const MobileUiScaleSystemScript = preload("res://scripts/systems/MobileUiScaleSystem.gd")

var ui_scale = MobileUiScaleSystemScript.new()

func settings_for(viewport_size: Vector2, settings: Dictionary = {}) -> Dictionary:
	var metrics := ui_scale.metrics(viewport_size)
	var size_name := String(settings.get("minimap_size", "standard"))
	var size_multiplier := 0.82 if size_name == "small" else (1.18 if size_name == "large" else 1.0)
	var opacity_name := String(settings.get("minimap_opacity", "standard"))
	var opacity := 0.56 if opacity_name == "low" else (0.92 if opacity_name == "high" else 0.76)
	var camera_name := String(settings.get("camera_view_size", "standard"))
	var camera_zoom := float(metrics.get("camera_zoom", 1.16))
	if camera_name == "near":
		camera_zoom += 0.08
	elif camera_name == "wide":
		camera_zoom -= 0.08
	return {
		"profile": String(metrics.get("profile", "compact_phone")),
		"minimap_size": maxf(180.0, float(metrics.get("minimap_size", 204.0)) * size_multiplier),
		"minimap_icon": maxf(8.0, float(metrics.get("minimap_icon", 8.0)) * size_multiplier),
		"minimap_opacity": opacity,
		"tap_expand": bool(settings.get("map_tap_expand", true)),
		"camera_zoom": clampf(camera_zoom, 0.92, 1.28),
		"update_hz": 4 if bool(settings.get("low_power_mode", false)) else clampi(int(settings.get("minimap_update_hz", 8)), 4, 12)
	}

func expanded_rect(viewport_size: Vector2, safe_rect: Rect2) -> Rect2:
	var target := Vector2(minf(safe_rect.size.x * 0.70, 820.0), minf(safe_rect.size.y * 0.78, 620.0))
	return Rect2(safe_rect.get_center() - target * 0.5, target)
