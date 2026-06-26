extends RefCounted

const PerformanceProfileSystemScript = preload("res://scripts/systems/PerformanceProfileSystem.gd")
const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var system = PerformanceProfileSystemScript.new()
	var desktop = SurvivorStateScript.new()
	desktop.start_new_run(1)
	system.apply_to_state(desktop, {"render_quality": "standard"}, "Windows")
	var ios = SurvivorStateScript.new()
	ios.start_new_run(1)
	system.apply_to_state(ios, {"render_quality": "standard"}, "iOS")
	t.assert_eq(ios.max_enemies(), desktop.max_enemies(), "iOS should keep the same enemy cap as desktop")
	t.assert_true(ios.max_effects() < desktop.max_effects(), "iOS should cap effects below desktop")
	var desktop_ui: Dictionary = system.ui_limits({"render_quality": "standard"}, "Windows")
	var ios_ui: Dictionary = system.ui_limits({"render_quality": "low"}, "iOS")
	t.assert_true(int(ios_ui["max_damage_numbers"]) < int(desktop_ui["max_damage_numbers"]), "iOS should reduce damage numbers")
	t.assert_true(int(ios_ui["notification_lines"]) < int(desktop_ui["notification_lines"]), "iOS should reduce notification lines")
	t.assert_true(float(ios_ui["ui_animation_scale"]) < float(desktop_ui["ui_animation_scale"]), "iOS should reduce UI animation intensity")
