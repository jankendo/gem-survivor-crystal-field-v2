extends PanelContainer
class_name AchievementCard

const UiNavigation = preload("res://scripts/ui/UiNavigation.gd")

var label: Label

func setup(title: String, description: String, reward: String, completed: bool) -> void:
	custom_minimum_size = Vector2(720, 104)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", UiNavigation.card_style(Color(0.48, 1.0, 0.66) if completed else Color(0.42, 0.82, 1.0)))
	label = Label.new()
	label.text = "%s　%s\n%s\n報酬：%s" % ["達成/受取済み" if completed else "未達成", title, description, reward]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 680
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.90, 0.98, 0.92) if completed else Color(0.84, 0.90, 0.98))
	add_child(label)

