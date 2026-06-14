extends RefCounted
class_name DynamicVirtualJoystickSystem

var viewport_size := Vector2(1280, 720)
var safe_rect := Rect2(0, 0, 1280, 720)
var move_zone := Rect2(0, 0, 640, 720)
var fixed_rect := Rect2()
var mode := "dynamic"
var visual_mode := "active"
var handedness := "right"
var radius := 98.0
var deadzone := 0.12
var sensitivity := 1.0
var touch_id := -1
var origin := Vector2.ZERO
var pointer := Vector2.ZERO
var direction := Vector2.ZERO

func configure(size: Vector2, safe: Rect2, settings: Dictionary = {}, configured_fixed_rect: Rect2 = Rect2()) -> void:
	viewport_size = size
	safe_rect = safe
	mode = String(settings.get("move_control_mode", "dynamic"))
	visual_mode = String(settings.get("joystick_visual_mode", "active"))
	handedness = String(settings.get("touch_handedness", "right"))
	radius = clampf(float(settings.get("joystick_radius", 98.0)), 72.0, 140.0)
	deadzone = clampf(float(settings.get("joystick_deadzone", 0.12)), 0.0, 0.45)
	sensitivity = clampf(float(settings.get("joystick_sensitivity", 1.0)), 0.5, 1.8)
	fixed_rect = configured_fixed_rect
	var half := safe_rect.size.x * 0.5
	move_zone = Rect2(
		safe_rect.position if handedness != "left" else Vector2(safe_rect.position.x + half, safe_rect.position.y),
		Vector2(half, safe_rect.size.y)
	)
	cancel()

func begin_touch(id: int, position: Vector2, blocked: bool = false) -> bool:
	if blocked or touch_id >= 0 or not can_begin_at(position):
		return false
	touch_id = id
	origin = fixed_rect.get_center() if mode == "fixed" and fixed_rect.size != Vector2.ZERO else position
	pointer = position
	_update_direction()
	return true

func drag_touch(id: int, position: Vector2) -> bool:
	if id != touch_id:
		return false
	pointer = position
	_update_direction()
	return true

func end_touch(id: int) -> bool:
	if id != touch_id:
		return false
	cancel()
	return true

func can_begin_at(position: Vector2) -> bool:
	if not safe_rect.has_point(position):
		return false
	if mode == "fixed":
		return fixed_rect.has_point(position)
	return move_zone.has_point(position)

func cancel() -> void:
	touch_id = -1
	direction = Vector2.ZERO
	pointer = origin

func active() -> bool:
	return touch_id >= 0

func should_draw() -> bool:
	return visual_mode == "always" or (visual_mode == "active" and active())

func visual_origin() -> Vector2:
	return Vector2(
		clampf(origin.x, safe_rect.position.x + radius, safe_rect.end.x - radius),
		clampf(origin.y, safe_rect.position.y + radius, safe_rect.end.y - radius)
	)

func visual_pointer() -> Vector2:
	return visual_origin() + (pointer - origin).limit_length(radius)

func _update_direction() -> void:
	var raw := (pointer - origin) / radius
	if raw.length() <= deadzone:
		direction = Vector2.ZERO
		return
	var normalized_length := clampf((raw.length() - deadzone) / maxf(0.01, 1.0 - deadzone), 0.0, 1.0)
	direction = raw.normalized() * minf(1.0, normalized_length * sensitivity)
	pointer = origin + (pointer - origin).limit_length(radius)
