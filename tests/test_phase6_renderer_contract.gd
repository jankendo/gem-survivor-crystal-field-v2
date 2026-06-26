extends RefCounted

const HarnessScript = preload("res://tests/Phase6BenchmarkHarness.gd")

func run(t) -> void:
	var method := String(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))
	var mobile_method := String(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", ""))
	t.assert_eq(method, "gl_compatibility", "Phase 6 should use the 2D-friendly Compatibility renderer")
	t.assert_eq(mobile_method, "gl_compatibility", "mobile renderer should match the adopted Compatibility renderer")
	var features: PackedStringArray = ProjectSettings.get_setting("application/config/features", PackedStringArray())
	t.assert_true(features.has("GL Compatibility"), "project features should record GL Compatibility")
	t.assert_true(not features.has("Forward Plus"), "project features should not silently return to Forward+")
	var harness = HarnessScript.new()
	if RenderingServer.has_method("get_current_rendering_method"):
		var runtime_method := harness._rendering_method()
		t.assert_true(runtime_method in ["forward_plus", "mobile", "gl_compatibility"], "runtime renderer report should use a known Godot renderer id")
	else:
		t.assert_eq(harness._rendering_method(), "", "Godot versions without runtime renderer API should report an empty method")
	var config := ConfigFile.new()
	t.assert_eq(config.load("res://export_presets.cfg"), OK, "export presets should load for renderer contract")
	t.assert_true(String(config.get_value("preset.0", "exclude_filter", "")).find("tests/*") >= 0, "Windows export should keep tests out of release artifacts")
	t.assert_true(String(config.get_value("preset.1.options", "application/bundle_identifier", "")) == "com.jankendo14.gemsurvivor", "iOS bundle identifier should remain compatible")
