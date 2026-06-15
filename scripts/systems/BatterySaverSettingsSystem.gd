extends RefCounted
class_name BatterySaverSettingsSystem

func profile_id(settings: Dictionary) -> String:
	return "battery_saver" if bool(settings.get("battery_saver", settings.get("low_power_mode", false))) else "standard"

func is_enabled(settings: Dictionary) -> bool:
	return profile_id(settings) == "battery_saver"

func normalized_patch(enabled: bool) -> Dictionary:
	return {
		"battery_saver": enabled,
		"low_power_mode": enabled
	}
