extends Node
class_name TouchHitTestDebugSystem

const DEFAULT_PATH := "user://touch_hit_test_log.csv"
const TouchActionAuditSystemScript = preload("res://scripts/systems/TouchActionAuditSystem.gd")

var enabled := false
var mouse_preview := false
var inspected_root: Node
var path := DEFAULT_PATH
var audit = TouchActionAuditSystemScript.new()

func configure(root: Node, should_enable: bool, enable_mouse_preview: bool = false, custom_path: String = "") -> void:
	inspected_root = root
	enabled = should_enable
	mouse_preview = should_enable and enable_mouse_preview
	path = custom_path if custom_path != "" else DEFAULT_PATH
	audit.configure(path)
	set_process_input(enabled)

func _input(event: InputEvent) -> void:
	if not enabled or inspected_root == null:
		return
	var position := Vector2.ZERO
	var accepted := false
	if event is InputEventScreenTouch and event.pressed:
		position = event.position
		accepted = true
	elif mouse_preview and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		position = event.position
		accepted = true
	if not accepted:
		return
	var top := audit.top_control_at(inspected_root, position)
	var button := _nearest_button(top)
	audit.record(
		"hit_test",
		top,
		"tap",
		position,
		button.name if button != null else "control",
		button.name if button != null else (top.name if top != null else "none"),
		""
	)

func _nearest_button(control: Control) -> BaseButton:
	var current: Node = control
	while current != null:
		if current is BaseButton:
			return current
		current = current.get_parent()
	return null
