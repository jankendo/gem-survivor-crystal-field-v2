extends RefCounted
class_name PerformanceProfileSystem

const VISUAL_CAP_KEYS := [
	"max_rendered_gems",
	"max_rendered_projectiles",
	"max_rendered_enemy_projectiles",
	"max_rendered_effects",
	"max_rendered_damage_numbers",
	"max_rendered_background_particles"
]

func apply_to_state(state, settings: Dictionary, platform: String = OS.get_name()) -> String:
	var quality = String(settings.get("render_quality", "standard"))
	if not quality in ["low", "standard", "high"]:
		quality = "standard"
	var family = "ios" if platform == "iOS" else "desktop"
	var profile_id = "%s_minimal" % family if String(settings.get("effect_density", "normal")) == "minimal" else "%s_%s" % [family, quality]
	var profiles: Dictionary = state.balance_data.get("performance_profiles", {})
	var profile: Dictionary = profiles.get(profile_id, profiles.get("%s_standard" % family, {}))
	if state.has_method("configure_render_profile"):
		state.configure_render_profile(profile_id, bool(settings.get("qa_telemetry_enabled", false)) or bool(settings.get("phase7_benchmark", false)))
	else:
		state.performance_profile_id = profile_id
	return profile_id

func ui_limits(settings: Dictionary, platform: String = OS.get_name()) -> Dictionary:
	var ios := platform == "iOS"
	var quality := String(settings.get("render_quality", "standard"))
	var low := quality == "low"
	var minimal := String(settings.get("effect_density", "normal")) == "minimal"
	var animation_amount := String(settings.get("ui_animation_amount", "standard"))
	var animation_multiplier := 0.0 if animation_amount == "off" else (0.65 if animation_amount == "low" else (1.0 if animation_amount == "high" else 0.82))
	return {
		"damage_numbers_enabled": false,
		"max_damage_numbers": 0,
		"notification_lines": 2 if minimal or (ios and low) else (3 if ios else 5),
		"ui_animation_scale": 0.0 if minimal else animation_multiplier * (0.8 if ios and low else 1.0),
		"max_rendered_projectiles": (56 if ios else 96) if minimal else (120 if ios and low else (190 if ios else 500)),
		"max_rendered_gems": (120 if ios else 180) if minimal else (260 if ios and low else (420 if ios else 1000)),
		"max_rendered_effects": (20 if ios else 28) if minimal else (64 if ios and low else (96 if ios else 200)),
		"max_rendered_damage_numbers": 0,
		"max_rendered_background_particles": 0 if minimal else (48 if ios and low else (90 if ios else 300)),
		"minimap_update_hz": 3 if minimal else (4 if bool(settings.get("battery_saver", settings.get("low_power_mode", false))) else int(settings.get("minimap_update_hz", 8))),
		"background_particles_enabled": bool(settings.get("background_particles", true)) and not minimal
	}
