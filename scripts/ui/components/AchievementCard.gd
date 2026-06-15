extends PanelContainer
class_name AchievementCard

const UiNavigation = preload("res://scripts/ui/UiNavigation.gd")

var label: Label
var progress_bar: ProgressBar

func setup(title: String, description: String, reward: String, completed: bool, progress: Dictionary = {}) -> void:
	custom_minimum_size = Vector2(720, 136)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", UiNavigation.card_style(Color(0.48, 1.0, 0.66) if completed else Color(0.42, 0.82, 1.0)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var current := float(progress.get("current", 0.0))
	var target := maxf(1.0, float(progress.get("target", 1.0)))
	var near := not completed and current / target >= 0.75
	label.text = "%s　%s\n%s\n現在：%s / %s　報酬：%s" % [
		"達成済み" if completed else ("もうすぐ" if near else "進行中" if current > 0.0 else "未達成"),
		title,
		description,
		_format_value(current, String(progress.get("value_type", "number"))),
		_format_value(target, String(progress.get("value_type", "number"))),
		reward
	]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 680
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.90, 0.98, 0.92) if completed else (Color(1.0, 0.88, 0.42) if near else Color(0.84, 0.90, 0.98)))
	box.add_child(label)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 16
	progress_bar.min_value = 0
	progress_bar.max_value = target
	progress_bar.value = minf(current, target)
	progress_bar.show_percentage = false
	box.add_child(progress_bar)

func _format_value(value: float, value_type: String) -> String:
	if value_type == "time":
		var seconds := maxi(0, int(round(value)))
		return "%d:%02d" % [seconds / 60, seconds % 60]
	if value_type == "rank":
		var ranks := ["D", "C", "B", "A", "S", "SS"]
		return ranks[clampi(int(value), 0, ranks.size() - 1)]
	return "%d" % int(round(value))
