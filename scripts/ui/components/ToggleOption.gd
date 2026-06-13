extends Button
class_name ToggleOption

const UiNavigation = preload("res://scripts/ui/UiNavigation.gd")

signal toggled_value(value: bool)

var option_name := ""
var value := false

func setup(title: String, initial_value: bool) -> void:
	option_name = title
	value = initial_value
	_refresh()
	pressed.connect(_toggle)

func _toggle() -> void:
	value = not value
	_refresh()
	toggled_value.emit(value)

func _refresh() -> void:
	text = "%s：%s" % [option_name, "ON" if value else "OFF"]
	custom_minimum_size = Vector2(300, 56)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_font_size_override("font_size", 18)
	var accent := Color(0.46, 1.0, 0.70) if value else Color(0.50, 0.58, 0.70)
	add_theme_stylebox_override("normal", UiNavigation.button_style(accent))
	add_theme_stylebox_override("hover", UiNavigation.button_style(accent, true))
