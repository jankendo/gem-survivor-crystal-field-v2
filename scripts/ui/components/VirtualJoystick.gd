extends Control
class_name VirtualJoystick

const DynamicVirtualJoystickSystemScript = preload("res://scripts/systems/DynamicVirtualJoystickSystem.gd")

signal direction_changed(direction: Vector2)

var direction := Vector2.ZERO
var dragging := false
var touch_index := -1
var enabled := true
var knob_position := Vector2.ZERO
var dynamic_origin := true
var visual_opacity := 0.72
var origin := Vector2.ZERO
var visual_extent := 196.0
var knob_extent := 82.0
var dynamic_system = DynamicVirtualJoystickSystemScript.new()
var blocked_rects: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	knob_position = size * 0.5
	origin = knob_position
	queue_redraw()

func configure(opacity: float = 0.72, use_dynamic_origin: bool = true, outer_extent: float = 196.0, knob_size: float = 82.0) -> void:
	visual_opacity = clampf(opacity, 0.35, 1.0)
	dynamic_origin = use_dynamic_origin
	visual_extent = maxf(180.0, outer_extent)
	knob_extent = clampf(knob_size, 72.0, 96.0)
	queue_redraw()

func configure_anywhere(viewport_size: Vector2, safe_rect: Rect2, settings: Dictionary, fixed_rect: Rect2, exclusions: Array = []) -> void:
	blocked_rects = exclusions.duplicate()
	dynamic_system.configure(viewport_size, safe_rect, settings, fixed_rect)
	dynamic_origin = dynamic_system.mode == "dynamic"
	visual_extent = dynamic_system.radius * 2.0
	origin = dynamic_system.origin
	knob_position = dynamic_system.pointer
	queue_redraw()

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		_release()
	set_process_input(enabled)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed and dynamic_system.begin_touch(event.index, event.position, _is_blocked(event.position)):
			touch_index = event.index
			dragging = true
			_sync_dynamic()
		elif not event.pressed and dynamic_system.end_touch(event.index):
			_release()
	elif event is InputEventScreenDrag and dynamic_system.drag_touch(event.index, event.position):
		_sync_dynamic()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and dynamic_system.begin_touch(0, event.position, _is_blocked(event.position)):
			touch_index = 0
			dragging = true
			_sync_dynamic()
		elif not event.pressed and dynamic_system.end_touch(0):
			_release()
	elif event is InputEventMouseMotion and dragging and dynamic_system.drag_touch(0, event.position):
		_sync_dynamic()

func _update_pointer(local_position: Vector2) -> void:
	var center = origin if dynamic_origin and dragging else size * 0.5
	var radius = maxf(44.0, visual_extent * 0.36)
	var offset = local_position - center
	if offset.length() > radius:
		offset = offset.normalized() * radius
	knob_position = center + offset
	direction = offset / radius
	direction_changed.emit(direction)
	queue_redraw()

func _release() -> void:
	dynamic_system.cancel()
	dragging = false
	touch_index = -1
	direction = Vector2.ZERO
	origin = size * 0.5
	knob_position = size * 0.5
	direction_changed.emit(direction)
	queue_redraw()

func _draw() -> void:
	if dynamic_system != null:
		if not dynamic_system.should_draw():
			return
		origin = dynamic_system.visual_origin()
		knob_position = dynamic_system.visual_pointer()
	var center = origin if dynamic_origin and dragging else size * 0.5
	if dynamic_system.mode == "fixed":
		center = dynamic_system.origin
	var base_radius = visual_extent * 0.5
	var knob_radius = knob_extent * 0.5
	var opacity = visual_opacity if dragging else visual_opacity * 0.42
	draw_circle(center, base_radius, Color(0.05, 0.13, 0.22, opacity))
	draw_arc(center, base_radius, 0.0, TAU, 72, Color(0.34, 0.88, 1.0, opacity + 0.18), 3.0)
	draw_circle(knob_position if dragging else center, knob_radius, Color(0.30, 0.94, 1.0, opacity + 0.18))
	draw_arc(knob_position if dragging else center, knob_radius, 0.0, TAU, 48, Color(0.92, 1.0, 1.0, opacity + 0.25), 2.0)

func _sync_dynamic() -> void:
	origin = dynamic_system.visual_origin()
	knob_position = dynamic_system.visual_pointer()
	direction = dynamic_system.direction
	direction_changed.emit(direction)
	queue_redraw()

func _is_blocked(point: Vector2) -> bool:
	for rect in blocked_rects:
		if (rect as Rect2).has_point(point):
			return true
	return false
