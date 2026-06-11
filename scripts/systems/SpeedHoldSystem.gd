extends RefCounted
class_name SpeedHoldSystem

const ALLOWED_KEYS := ["left_shift", "tab", "space", "middle_mouse"]
const ALLOWED_MULTIPLIERS := [1.5, 2.0]

var enabled := true
var hold_key := "left_shift"
var speed_multiplier := 2.0

func configure(settings: Dictionary) -> void:
	enabled = bool(settings.get("speed_hold_enabled", true))
	hold_key = String(settings.get("speed_hold_key", "left_shift"))
	if not ALLOWED_KEYS.has(hold_key):
		hold_key = "left_shift"
	speed_multiplier = float(settings.get("speed_multiplier", 2.0))
	if not ALLOWED_MULTIPLIERS.has(speed_multiplier):
		speed_multiplier = 2.0

func simulation_multiplier(pressed: bool, blocked: bool) -> float:
	return speed_multiplier if enabled and pressed and not blocked else 1.0

func is_pressed() -> bool:
	match hold_key:
		"tab":
			return Input.is_key_pressed(KEY_TAB)
		"space":
			return Input.is_key_pressed(KEY_SPACE)
		"middle_mouse":
			return Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
		_:
			return Input.is_key_pressed(KEY_SHIFT)

func display_text(active: bool) -> String:
	return "倍速 x%.1f" % speed_multiplier if active else ""
