extends RefCounted
class_name InputModeSystem

const DESKTOP_KEYBOARD_MOUSE := "desktop_keyboard_mouse"
const DESKTOP_TOUCH_PREVIEW := "desktop_touch_preview"
const IOS_TOUCH := "ios_touch"
const CONTROLLER_OPTIONAL := "controller_optional"

var mode := DESKTOP_KEYBOARD_MOUSE
var platform_name := ""

func configure(settings: Dictionary = {}, platform: String = OS.get_name(), controller_connected: bool = false) -> String:
	platform_name = platform
	var touch_mode := String(settings.get("touch_ui_mode", "auto"))
	if platform == "iOS":
		mode = IOS_TOUCH
	elif touch_mode == "on" or bool(settings.get("desktop_touch_preview", false)):
		mode = DESKTOP_TOUCH_PREVIEW
	elif controller_connected:
		mode = CONTROLLER_OPTIONAL
	else:
		mode = DESKTOP_KEYBOARD_MOUSE
	return mode

func is_touch_mode() -> bool:
	return mode == IOS_TOUCH or mode == DESKTOP_TOUCH_PREVIEW

func is_ios_touch() -> bool:
	return mode == IOS_TOUCH

func keyboard_hints_allowed() -> bool:
	return not is_touch_mode()

func action_hint(action: String) -> String:
	if is_touch_mode():
		var touch_hints := {
			"action_scan": "スキャン",
			"action_drone": "回収",
			"action_speed_hold": "倍速を長押し",
			"action_pause": "ポーズ",
			"action_confirm": "タップして決定",
			"action_back": "戻る",
			"action_select_card": "カードをタップ",
			"action_open_log": "ログ",
			"action_open_map": "マップ"
		}
		return String(touch_hints.get(action, "タップ"))
	var desktop_hints := {
		"action_scan": "F / 右クリック",
		"action_drone": "R",
		"action_speed_hold": "Shift長押し",
		"action_pause": "Esc",
		"action_confirm": "Enter / クリック",
		"action_back": "Esc",
		"action_select_card": "1/2/3 / クリック",
		"action_open_log": "ポーズ > ログ",
		"action_open_map": "ミニマップ"
	}
	return String(desktop_hints.get(action, "クリック"))
