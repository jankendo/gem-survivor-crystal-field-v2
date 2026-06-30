extends RefCounted
class_name IosDefaultSettingsSystem

func defaults_for_platform(platform: String = OS.get_name()) -> Dictionary:
	if platform != "iOS":
		return {}
	return _json_dict("res://data/ios_lightweight_defaults.json", {
		"battery_saver": true,
		"low_power_mode": true,
		"render_quality": "low",
		"target_fps": 30,
		"damage_numbers": false,
		"damage_number_mode": "removed",
		"screen_shake": false,
		"background_particles": false,
		"notification_log_amount": "low",
		"minimap_update_hz": 4,
		"equipment_hud_mode": "simple",
		"touch_haptics": false,
		"touch_haptics_mode": "removed",
		"ui_animation_amount": "off",
		"touch_hit_test_debug": false,
		"touch_action_audit": false,
		"notch_protection": true,
		"safe_play_display_mode": "letterbox"
	})

func apply_defaults(settings: Dictionary, platform: String = OS.get_name()) -> Dictionary:
	var result := settings.duplicate(true)
	var defaults := defaults_for_platform(platform)
	for key in defaults.keys():
		if not result.has(key):
			result[key] = defaults[key]
	return result

func high_quality_patch() -> Dictionary:
	return {
		"battery_saver": false,
		"low_power_mode": false,
		"render_quality": "high",
		"target_fps": 60,
		"damage_numbers": false,
		"damage_number_mode": "removed",
		"screen_shake": true,
		"background_particles": true,
		"notification_log_amount": "standard",
		"minimap_update_hz": 8,
		"ui_animation_amount": "standard"
	}

func _json_dict(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback.duplicate(true)
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else fallback.duplicate(true)
