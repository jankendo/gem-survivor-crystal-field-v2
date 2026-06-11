extends PanelContainer
class_name FieldHelpCard

const UiNavigation = preload("res://scripts/ui/UiNavigation.gd")

var label: Label

func setup(text_value: String, accent: Color = Color(0.42, 0.82, 1.0)) -> void:
	custom_minimum_size = Vector2(360, 110)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", UiNavigation.card_style(accent))
	label = Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 330
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	add_child(label)
