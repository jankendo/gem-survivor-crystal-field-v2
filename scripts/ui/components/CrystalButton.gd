extends Button
class_name CrystalButton

const UiNavigation = preload("res://scripts/ui/UiNavigation.gd")

var accent_color := Color(0.40, 0.92, 1.0)
var danger_style := false

func _ready() -> void:
	apply_theme()

func setup(label: String, accent: Color = Color(0.40, 0.92, 1.0), min_size: Vector2 = Vector2(0, 44), danger: bool = false) -> void:
	text = label
	accent_color = accent
	custom_minimum_size = min_size
	danger_style = danger
	apply_theme()

func apply_theme() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 20)
	add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	add_theme_stylebox_override("normal", UiNavigation.button_style(accent_color, false, danger_style))
	add_theme_stylebox_override("hover", UiNavigation.button_style(accent_color, true, danger_style))
	add_theme_stylebox_override("pressed", UiNavigation.button_style(accent_color.lightened(0.08), true, danger_style))
	add_theme_stylebox_override("disabled", UiNavigation.button_style(Color(0.22, 0.28, 0.34), false, danger_style))
