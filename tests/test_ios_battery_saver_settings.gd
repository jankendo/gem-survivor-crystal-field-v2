extends RefCounted

const SettingsScript = preload("res://scripts/systems/BatterySaverSettingsSystem.gd")
const FrameScript = preload("res://scripts/systems/IosFramePacingSystem.gd")
const ProfileScript = preload("res://scripts/systems/PerformanceProfileSystem.gd")

func run(t) -> void:
	var settings = SettingsScript.new()
	t.assert_eq(settings.profile_id({"battery_saver": false}), "standard", "battery saver should be optional")
	t.assert_eq(settings.profile_id({"battery_saver": true}), "battery_saver", "enabled setting should select battery saver")
	var patch := settings.normalized_patch(true)
	t.assert_true(bool(patch.get("battery_saver", false)) and bool(patch.get("low_power_mode", false)), "legacy low power setting should stay synchronized")
	var profile = ProfileScript.new().ui_limits({"battery_saver": true, "damage_numbers": true, "background_particles": true}, "iOS")
	t.assert_true(bool(profile.get("damage_numbers_enabled", false)), "battery saver must not remove damage numbers")
	t.assert_true(bool(profile.get("background_particles_enabled", false)), "battery saver must not remove background particles")
	var pacing = FrameScript.new()
	var before := Engine.max_fps
	t.assert_eq(pacing.apply({"target_fps": 45}, true), 45, "battery saver should apply a reversible 45 fps cap")
	pacing.restore()
	t.assert_eq(Engine.max_fps, before, "frame pacing should restore the desktop/default cap")
