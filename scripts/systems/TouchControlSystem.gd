extends RefCounted
class_name TouchControlSystem

const ACTIONS := [
	"action_scan",
	"action_drone",
	"action_speed_hold",
	"action_pause",
	"action_confirm",
	"action_back",
	"action_select_card",
	"action_reroll",
	"action_banish",
	"action_skip",
	"action_open_log",
	"action_open_map"
]

var touch_ui_mode := "auto"
var virtual_joystick_enabled := true
var touch_button_size := "standard"
var touch_button_opacity := 0.78
var handedness := "right"
var haptics_enabled := true
var speed_pressed := false
var platform_name := ""
var move_vector := Vector2.ZERO
var action_states: Dictionary = {}

func configure(settings: Dictionary, platform: String = OS.get_name()) -> void:
	touch_ui_mode = String(settings.get("touch_ui_mode", "auto"))
	virtual_joystick_enabled = bool(settings.get("virtual_joystick_enabled", true))
	touch_button_size = String(settings.get("touch_button_size", "standard"))
	touch_button_opacity = clampf(float(settings.get("touch_button_opacity", 0.78)), 0.35, 1.0)
	handedness = String(settings.get("touch_handedness", "right"))
	if not handedness in ["right", "left"]:
		handedness = "right"
	haptics_enabled = bool(settings.get("touch_haptics", true))
	platform_name = platform
	speed_pressed = false
	move_vector = Vector2.ZERO
	action_states.clear()
	for action in ACTIONS:
		action_states[action] = false

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
	set_action_pressed("action_speed_hold", speed_pressed, false)

func set_move_vector(value: Vector2) -> void:
	move_vector = value.normalized() if value.length() > 1.0 else value

func set_action_pressed(action: String, value: bool, feedback: bool = true) -> void:
	if not ACTIONS.has(action):
		return
	action_states[action] = value if should_show() else false
	if feedback and value:
		feedback_light()

func is_action_pressed(action: String) -> bool:
	return bool(action_states.get(action, false))

func consume_action(action: String) -> bool:
	if not is_action_pressed(action):
		return false
	action_states[action] = false
	return true

func feedback_light() -> void:
	if haptics_enabled and should_show():
		Input.vibrate_handheld(22)

func controls_swapped() -> bool:
	return handedness == "left"
