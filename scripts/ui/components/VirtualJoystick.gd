extends Control
class_name VirtualJoystick

signal direction_changed(direction: Vector2)

var direction := Vector2.ZERO
var dragging := false
var touch_index := -1
var enabled := true
var knob_position := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	knob_position = size * 0.5
	queue_redraw()

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		_release()
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed and touch_index < 0:
			touch_index = event.index
			dragging = true
			_update_pointer(event.position)
			accept_event()
		elif not event.pressed and event.index == touch_index:
			_release()
			accept_event()
	elif event is InputEventScreenDrag and event.index == touch_index:
		_update_pointer(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			_update_pointer(event.position)
		else:
			_release()
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		_update_pointer(event.position)
		accept_event()

func _update_pointer(local_position: Vector2) -> void:
	var center = size * 0.5
	var radius = maxf(24.0, minf(size.x, size.y) * 0.34)
	var offset = local_position - center
	if offset.length() > radius:
		offset = offset.normalized() * radius
	knob_position = center + offset
	direction = offset / radius
	direction_changed.emit(direction)
	queue_redraw()

func _release() -> void:
	dragging = false
	touch_index = -1
	direction = Vector2.ZERO
	knob_position = size * 0.5
	direction_changed.emit(direction)
	queue_redraw()

func _draw() -> void:
	var center = size * 0.5
	var base_radius = minf(size.x, size.y) * 0.42
	var knob_radius = base_radius * 0.38
	var opacity = 0.58 if dragging else 0.28
	draw_circle(center, base_radius, Color(0.05, 0.13, 0.22, opacity))
	draw_arc(center, base_radius, 0.0, TAU, 72, Color(0.34, 0.88, 1.0, opacity + 0.18), 3.0)
	draw_circle(knob_position if dragging else center, knob_radius, Color(0.30, 0.94, 1.0, opacity + 0.18))
	draw_arc(knob_position if dragging else center, knob_radius, 0.0, TAU, 48, Color(0.92, 1.0, 1.0, opacity + 0.25), 2.0)
