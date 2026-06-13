extends RefCounted
class_name MobileHudLayoutSystem

const MobileUiScaleSystemScript = preload("res://scripts/systems/MobileUiScaleSystem.gd")
const MobileMapSystemScript = preload("res://scripts/systems/MobileMapSystem.gd")

const MIN_TOUCH_TARGET := 56.0
const MIN_JOYSTICK_EXTENT := 180.0

var ui_scale_system = MobileUiScaleSystemScript.new()
var map_system = MobileMapSystemScript.new()

func layout(viewport_size: Vector2, safe_rect: Rect2, settings: Dictionary = {}) -> Dictionary:
	var reference_size: Vector2 = settings.get("_device_size", viewport_size)
	var metrics := ui_scale_system.metrics(reference_size)
	var map_settings := map_system.settings_for(reference_size, settings)
	var tablet := bool(metrics.get("tablet", false))
	var handedness := String(settings.get("touch_handedness", "right"))
	var scale := clampf(float(settings.get("hud_scale", 1.0)), 0.9, 1.3)
	var configured_button := float(metrics.get("action_button", 76.0))
	var size_name := String(settings.get("touch_button_size", "standard"))
	var size_multiplier := 0.90 if size_name == "small" else (1.14 if size_name == "large" else 1.0)
	var button_extent := maxf(64.0, configured_button * size_multiplier * scale)
	var joystick_visual_extent := maxf(MIN_JOYSTICK_EXTENT, float(metrics.get("joystick_outer", 196.0)) * scale)
	var joystick_touch_extent := maxf(joystick_visual_extent, float(metrics.get("joystick_touch_extent", joystick_visual_extent * 1.30)) * scale)
	var gap := 14.0 * scale
	var left_controls := handedness != "left"
	var joystick_offset := Vector2(
		float(settings.get("joystick_offset_x", 0.0)),
		float(settings.get("joystick_offset_y", 0.0))
	)
	var joystick_x := safe_rect.position.x + gap if left_controls else safe_rect.end.x - gap - joystick_touch_extent
	var actions_x := safe_rect.end.x - gap - button_extent * 2.0 - gap if left_controls else safe_rect.position.x + gap
	var controls_bottom := safe_rect.end.y - gap
	var joystick_position := Vector2(joystick_x, controls_bottom - joystick_touch_extent) + joystick_offset
	joystick_position.x = clampf(joystick_position.x, safe_rect.position.x, safe_rect.end.x - joystick_touch_extent)
	joystick_position.y = clampf(joystick_position.y, safe_rect.position.y, safe_rect.end.y - joystick_touch_extent)
	var minimap_size := minf(float(map_settings.get("minimap_size", 204.0)), safe_rect.size.y * 0.38)
	var top_button_extent := maxf(60.0, float(metrics.get("pause_button_px", 60.0)) * scale)
	var minimap_rect := Rect2(
		Vector2(safe_rect.end.x - minimap_size, safe_rect.position.y + top_button_extent + gap),
		Vector2.ONE * minimap_size
	)
	return {
		"profile": metrics.get("profile", "compact_phone"),
		"tablet": tablet,
		"button_extent": button_extent,
		"joystick_extent": joystick_touch_extent,
		"joystick_visual_extent": joystick_visual_extent,
		"joystick_touch_extent": joystick_touch_extent,
		"joystick_knob_extent": clampf(float(metrics.get("virtual_joystick_knob_px", 82.0)) * scale, 72.0, 96.0),
		"joystick_rect": Rect2(
			joystick_position,
			Vector2.ONE * joystick_touch_extent
		),
		"actions_rect": Rect2(
			Vector2(actions_x, controls_bottom - button_extent * 2.0 - gap),
			Vector2(button_extent * 2.0 + gap, button_extent * 2.0 + gap)
		),
		"pause_rect": Rect2(Vector2(safe_rect.end.x - top_button_extent, safe_rect.position.y), Vector2.ONE * top_button_extent),
		"log_rect": Rect2(Vector2(safe_rect.end.x - top_button_extent * 2.0 - gap, safe_rect.position.y), Vector2.ONE * top_button_extent),
		"map_rect": Rect2(Vector2(safe_rect.end.x - top_button_extent * 3.0 - gap * 2.0, safe_rect.position.y), Vector2.ONE * top_button_extent),
		"minimap_rect": minimap_rect,
		"minimap_icon": map_settings.get("minimap_icon", 8.0),
		"minimap_opacity": map_settings.get("minimap_opacity", 0.76),
		"camera_zoom": map_settings.get("camera_zoom", 1.0),
		"map_tap_expand": map_settings.get("tap_expand", true),
		"expanded_map_rect": map_system.expanded_rect(viewport_size, safe_rect)
	}
