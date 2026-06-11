extends RefCounted

func run(t) -> void:
	test_windows_export_preset(t)

func test_windows_export_preset(t) -> void:
	var config := ConfigFile.new()
	var err := config.load("res://export_presets.cfg")
	t.assert_eq(err, OK, "export_presets.cfg should load")
	t.assert_eq(String(config.get_value("preset.0", "name", "")), "Windows Desktop", "Windows export preset name should match")
	t.assert_eq(String(config.get_value("preset.0", "export_path", "")), "builds/ChronoMergeTactics.exe", "export path should target builds exe")
	t.assert_eq(String(config.get_value("preset.0", "include_filter", "")), "assets/sounds/*.wav", "raw WAV files should be included for direct AudioManager loading")
	var exclude_filter := String(config.get_value("preset.0", "exclude_filter", ""))
	t.assert_true(exclude_filter.find("tests/*") >= 0, "tests should be excluded from release export")
	t.assert_true(exclude_filter.find("tools/*") >= 0, "tools should be excluded from release export")
	t.assert_eq(bool(config.get_value("preset.0.options", "application/modify_resources", true)), false, "modify_resources should be false to avoid rcedit dependency")
