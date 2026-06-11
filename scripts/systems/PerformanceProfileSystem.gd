extends RefCounted
class_name PerformanceProfileSystem

const CAP_KEYS := [
	"max_enemies",
	"max_gems",
	"max_projectiles",
	"max_enemy_projectiles",
	"max_effects",
	"max_texts",
	"max_background_particles"
]

func apply_to_state(state, settings: Dictionary, platform: String = OS.get_name()) -> String:
	var quality = String(settings.get("render_quality", "standard"))
	if not quality in ["low", "standard", "high"]:
		quality = "standard"
	var family = "ios" if platform == "iOS" else "desktop"
	var profile_id = "%s_%s" % [family, quality]
	var profiles: Dictionary = state.balance_data.get("performance_profiles", {})
	var profile: Dictionary = profiles.get(profile_id, profiles.get("%s_standard" % family, {}))
	for key in CAP_KEYS:
		if profile.has(key):
			state.balance_data[key] = int(profile[key])
	state.performance_profile_id = profile_id
	return profile_id
