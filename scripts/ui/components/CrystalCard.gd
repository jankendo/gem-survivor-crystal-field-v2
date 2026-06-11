extends PanelContainer
class_name CrystalCard

const UiNavigation = preload("res://scripts/ui/UiNavigation.gd")

var accent_color := Color(0.40, 0.92, 1.0)
var secret_style := false

func _ready() -> void:
	apply_theme()

func setup(accent: Color = Color(0.40, 0.92, 1.0), secret: bool = false, min_size: Vector2 = Vector2.ZERO) -> void:
	accent_color = accent
	secret_style = secret
	custom_minimum_size = Vector2(maxf(240.0, min_size.x), min_size.y)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	apply_theme()

func apply_theme() -> void:
	add_theme_stylebox_override("panel", UiNavigation.card_style(accent_color, false, secret_style))
