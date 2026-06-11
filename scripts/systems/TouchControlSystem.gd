extends RefCounted
class_name TouchControlSystem

var touch_ui_mode := "auto"
var virtual_joystick_enabled := true
var touch_button_size := "standard"
var speed_pressed := false
var platform_name := ""

func configure(settings: Dictionary, platform: String = OS.get_name()) -> void:
	touch_ui_mode = String(settings.get("touch_ui_mode", "auto"))
	virtual_joystick_enabled = bool(settings.get("virtual_joystick_enabled", true))
	touch_button_size = String(settings.get("touch_button_size", "standard"))
	platform_name = platform
	speed_pressed = false

func should_show() -> bool:
	if touch_ui_mode == "on":
		return true
	if touch_ui_mode == "off":
		return false
	return platform_name == "iOS"

func should_show_joystick() -> bool:
	return should_show() and virtual_joystick_enabled

func button_extent() -> float:
	match touch_button_size:
		"small":
			return 62.0
		"large":
			return 92.0
		_:
			return 76.0

func joystick_extent() -> float:
	return button_extent() * 2.15

func combined_direction(keyboard_direction: Vector2, touch_direction: Vector2) -> Vector2:
	var combined = keyboard_direction + touch_direction
	return combined.normalized() if combined.length() > 1.0 else combined

func set_speed_pressed(value: bool) -> void:
	speed_pressed = value if should_show() else false
