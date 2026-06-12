extends RefCounted
class_name MobileHudLayoutSystem

const MIN_TOUCH_TARGET := 56.0
const MIN_JOYSTICK_EXTENT := 140.0

func layout(viewport_size: Vector2, safe_rect: Rect2, settings: Dictionary = {}) -> Dictionary:
	var tablet := viewport_size.y >= 1400.0 or viewport_size.x / maxf(1.0, viewport_size.y) < 1.55
	var handedness := String(settings.get("touch_handedness", "right"))
	var scale := clampf(float(settings.get("hud_scale", 1.0)), 0.9, 1.3)
	var button_extent := maxf(MIN_TOUCH_TARGET, _button_extent(String(settings.get("touch_button_size", "standard"))) * scale)
	var joystick_extent := maxf(MIN_JOYSTICK_EXTENT, button_extent * 2.05)
	var gap := 12.0 * scale
	var left_controls := handedness != "left"
	var minimap_reserve := 184.0 * scale
	var joystick_x := safe_rect.position.x + gap if left_controls else safe_rect.end.x - gap - joystick_extent
	if not left_controls:
		joystick_x -= minimap_reserve
	var actions_x := safe_rect.end.x - gap - button_extent * 2.0 - gap - minimap_reserve if left_controls else safe_rect.position.x + gap
	return {
		"tablet": tablet,
		"button_extent": button_extent,
		"joystick_extent": joystick_extent,
		"joystick_rect": Rect2(Vector2(joystick_x, safe_rect.end.y - joystick_extent - gap), Vector2.ONE * joystick_extent),
		"actions_rect": Rect2(Vector2(actions_x, safe_rect.end.y - button_extent * 2.0 - gap * 2.0), Vector2(button_extent * 2.0 + gap, button_extent * 2.0 + gap)),
		"pause_rect": Rect2(Vector2(safe_rect.end.x - button_extent, safe_rect.position.y), Vector2(button_extent, MIN_TOUCH_TARGET)),
		"log_rect": Rect2(Vector2(safe_rect.end.x - button_extent * 2.0 - gap, safe_rect.position.y), Vector2(button_extent, MIN_TOUCH_TARGET)),
		"map_rect": Rect2(Vector2(safe_rect.end.x - button_extent * 3.0 - gap * 2.0, safe_rect.position.y), Vector2(button_extent, MIN_TOUCH_TARGET))
	}

func _button_extent(size_name: String) -> float:
	match size_name:
		"small":
			return 62.0
		"large":
			return 92.0
		_:
			return 76.0
