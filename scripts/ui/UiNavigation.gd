extends RefCounted
class_name UiNavigation

static func button_style(accent: Color = Color(0.40, 0.92, 1.0), hover: bool = false, danger: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var bg := Color(0.055, 0.075, 0.115, 0.96)
	if danger:
		bg = Color(0.16, 0.055, 0.085, 0.96)
	if hover:
		bg = bg.lightened(0.10)
		accent = accent.lightened(0.14)
	style.bg_color = bg
	style.border_color = accent
	style.set_border_width_all(2 if not hover else 3)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func card_style(accent: Color = Color(0.40, 0.92, 1.0), hover: bool = false, secret: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var bg := Color(0.035, 0.050, 0.086, 0.96)
	if secret:
		bg = Color(0.035, 0.025, 0.055, 0.98)
	if hover:
		bg = bg.lightened(0.08)
		accent = accent.lightened(0.12)
	style.bg_color = bg
	style.border_color = accent
	style.set_border_width_all(2 if not hover else 3)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func focusless(button: BaseButton) -> BaseButton:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button

static func accent_for_kind(kind: String) -> Color:
	match kind:
		"weapon":
			return Color(1.0, 0.48, 0.22)
		"passive":
			return Color(0.38, 0.92, 0.62)
		"evolution":
			return Color(1.0, 0.86, 0.28)
		"overclock":
			return Color(1.0, 0.62, 0.18)
		"contract", "danger":
			return Color(1.0, 0.22, 0.42)
		"secret":
			return Color(0.74, 0.34, 1.0)
		"settings":
			return Color(0.42, 0.82, 1.0)
	return Color(0.40, 0.92, 1.0)
