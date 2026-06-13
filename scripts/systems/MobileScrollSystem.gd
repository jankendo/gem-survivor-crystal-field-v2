extends Node
class_name MobileScrollSystem

const AXIS_HORIZONTAL := "horizontal"
const AXIS_VERTICAL := "vertical"
const AXIS_BOTH := "both"
const DRAG_THRESHOLD := 12.0
const INERTIA_STOP_SPEED := 18.0
const INERTIA_DECAY := 8.5

var enabled := false
var mouse_preview := false
var registrations: Array = []
var pointer_active := false
var pointer_index := -1
var pointer_start := Vector2.ZERO
var pointer_last := Vector2.ZERO
var pointer_total := Vector2.ZERO
var dragging := false
var active_scroll: ScrollContainer
var content_velocity := Vector2.ZERO
var inertia_scroll: ScrollContainer
var inertia_velocity := Vector2.ZERO
var suppressed_buttons: Array = []

func configure(is_touch_mode: bool, enable_mouse_preview: bool = false) -> void:
	enabled = is_touch_mode
	mouse_preview = is_touch_mode and enable_mouse_preview
	set_process(enabled)
	set_process_input(enabled)
	if not enabled:
		_reset_pointer()
		inertia_scroll = null
		inertia_velocity = Vector2.ZERO

func clear_registrations() -> void:
	registrations.clear()
	active_scroll = null
	inertia_scroll = null
	_restore_buttons()

func register_scroll(scroll: ScrollContainer, axis: String) -> void:
	if scroll == null:
		return
	var normalized := axis if axis in [AXIS_HORIZONTAL, AXIS_VERTICAL, AXIS_BOTH] else AXIS_VERTICAL
	scroll.set_meta("mobile_scroll_axis", normalized)
	scroll.set_meta("mobile_scroll_registered", true)
	scroll.scroll_deadzone = 100000
	registrations.append({"scroll": weakref(scroll), "axis": normalized})

func axis_for(scroll: ScrollContainer) -> String:
	if scroll == null:
		return ""
	return String(scroll.get_meta("mobile_scroll_axis", ""))

func simulate_drag(scroll: ScrollContainer, finger_delta: Vector2) -> Vector2:
	if scroll == null:
		return Vector2.ZERO
	var before := Vector2(scroll.scroll_horizontal, scroll.scroll_vertical)
	_suppress_descendant_buttons(scroll)
	_apply_content_delta(scroll, -finger_delta)
	_restore_buttons()
	return Vector2(scroll.scroll_horizontal, scroll.scroll_vertical) - before

func _input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin_pointer(touch.position, touch.index)
		elif pointer_active and touch.index == pointer_index:
			var was_dragging := dragging
			_finish_pointer()
			if was_dragging:
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if pointer_active and drag.index == pointer_index:
			_update_pointer(drag.position, drag.relative)
	elif mouse_preview and event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed:
				_begin_pointer(mouse_button.position, -2)
			elif pointer_active and pointer_index == -2:
				var was_dragging := dragging
				_finish_pointer()
				if was_dragging:
					get_viewport().set_input_as_handled()
	elif mouse_preview and event is InputEventMouseMotion and pointer_active and pointer_index == -2:
		var motion := event as InputEventMouseMotion
		_update_pointer(motion.position, motion.relative)

func _process(delta: float) -> void:
	if not enabled or pointer_active or inertia_scroll == null:
		return
	if not is_instance_valid(inertia_scroll) or not inertia_scroll.is_inside_tree():
		inertia_scroll = null
		inertia_velocity = Vector2.ZERO
		return
	if inertia_velocity.length() <= INERTIA_STOP_SPEED:
		inertia_scroll = null
		inertia_velocity = Vector2.ZERO
		return
	_apply_content_delta(inertia_scroll, inertia_velocity * delta)
	inertia_velocity = inertia_velocity.lerp(Vector2.ZERO, clampf(delta * INERTIA_DECAY, 0.0, 1.0))

func _begin_pointer(position: Vector2, index: int) -> void:
	pointer_active = true
	pointer_index = index
	pointer_start = position
	pointer_last = position
	pointer_total = Vector2.ZERO
	dragging = false
	active_scroll = null
	content_velocity = Vector2.ZERO
	inertia_scroll = null
	inertia_velocity = Vector2.ZERO

func _update_pointer(position: Vector2, relative: Vector2) -> void:
	if not pointer_active:
		return
	var frame_delta := relative
	if frame_delta == Vector2.ZERO:
		frame_delta = position - pointer_last
	pointer_last = position
	pointer_total += frame_delta
	if not dragging:
		if pointer_total.length() < DRAG_THRESHOLD:
			return
		active_scroll = _choose_scroll(pointer_start, pointer_total)
		if active_scroll == null:
			_reset_pointer()
			return
		dragging = true
		_suppress_descendant_buttons(active_scroll)
	var content_delta := -frame_delta
	_apply_content_delta(active_scroll, content_delta)
	content_velocity = content_velocity.lerp(content_delta * 60.0, 0.42)
	get_viewport().set_input_as_handled()

func _finish_pointer() -> void:
	if dragging and active_scroll != null and is_instance_valid(active_scroll):
		inertia_scroll = active_scroll
		inertia_velocity = content_velocity
	_restore_buttons_deferred()
	_reset_pointer()

func _reset_pointer() -> void:
	pointer_active = false
	pointer_index = -1
	pointer_start = Vector2.ZERO
	pointer_last = Vector2.ZERO
	pointer_total = Vector2.ZERO
	dragging = false
	active_scroll = null
	content_velocity = Vector2.ZERO

func _choose_scroll(position: Vector2, drag_delta: Vector2) -> ScrollContainer:
	var preferred_axis := AXIS_HORIZONTAL if absf(drag_delta.x) > absf(drag_delta.y) else AXIS_VERTICAL
	var candidates: Array = []
	for entry in registrations:
		var reference: WeakRef = entry.get("scroll")
		var scroll = reference.get_ref() if reference != null else null
		if not (scroll is ScrollContainer):
			continue
		if not scroll.is_inside_tree() or not scroll.is_visible_in_tree():
			continue
		if not scroll.get_global_rect().has_point(position):
			continue
		var axis := String(entry.get("axis", AXIS_VERTICAL))
		if axis != AXIS_BOTH and axis != preferred_axis:
			continue
		candidates.append({"scroll": scroll, "depth": _node_depth(scroll)})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary): return int(a["depth"]) > int(b["depth"]))
	return candidates[0]["scroll"] if not candidates.is_empty() else null

func _apply_content_delta(scroll: ScrollContainer, delta: Vector2) -> void:
	if scroll == null or not is_instance_valid(scroll):
		return
	var axis := axis_for(scroll)
	if axis == AXIS_HORIZONTAL or axis == AXIS_BOTH:
		scroll.scroll_horizontal = maxi(0, scroll.scroll_horizontal + int(round(delta.x)))
	if axis == AXIS_VERTICAL or axis == AXIS_BOTH:
		scroll.scroll_vertical = maxi(0, scroll.scroll_vertical + int(round(delta.y)))

func _suppress_descendant_buttons(root: Node) -> void:
	_restore_buttons()
	var buttons: Array = []
	_collect_buttons(root, buttons)
	for button in buttons:
		if not is_instance_valid(button):
			continue
		suppressed_buttons.append({"button": weakref(button), "disabled": button.disabled})
		if not button.disabled:
			button.disabled = true

func _collect_buttons(node: Node, result: Array) -> void:
	for child in node.get_children():
		if child is BaseButton:
			result.append(child)
		_collect_buttons(child, result)

func _restore_buttons_deferred() -> void:
	call_deferred("_restore_buttons")

func _restore_buttons() -> void:
	for entry in suppressed_buttons:
		var reference: WeakRef = entry.get("button")
		var button = reference.get_ref() if reference != null else null
		if button is BaseButton and is_instance_valid(button):
			button.disabled = bool(entry.get("disabled", false))
	suppressed_buttons.clear()

func _node_depth(node: Node) -> int:
	var depth := 0
	var current := node.get_parent()
	while current != null:
		depth += 1
		current = current.get_parent()
	return depth
