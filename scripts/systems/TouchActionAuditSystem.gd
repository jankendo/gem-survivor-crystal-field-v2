extends RefCounted
class_name TouchActionAuditSystem

const DEFAULT_PATH := "user://ios_touch_action_audit.csv"

var path := DEFAULT_PATH

func configure(custom_path: String = "") -> void:
	path = custom_path if custom_path != "" else DEFAULT_PATH

func control_snapshot(control: Control) -> Dictionary:
	if control == null:
		return {}
	var canvas_layer := _canvas_layer_for(control)
	return {
		"control_name": control.name,
		"visible": control.visible and control.is_visible_in_tree(),
		"disabled": control.disabled if control is BaseButton else false,
		"rect": control.get_global_rect(),
		"mouse_filter": control.mouse_filter,
		"canvas_layer": canvas_layer,
		"z_index": control.z_index
	}

func top_control_at(root: Node, position: Vector2) -> Control:
	var hits: Array = []
	_collect_hits(root, position, hits, [0])
	if hits.is_empty():
		return null
	hits.sort_custom(func(a: Dictionary, b: Dictionary):
		if int(a["canvas_layer"]) != int(b["canvas_layer"]):
			return int(a["canvas_layer"]) > int(b["canvas_layer"])
		if int(a["z_index"]) != int(b["z_index"]):
			return int(a["z_index"]) > int(b["z_index"])
		return int(a["order"]) > int(b["order"])
	)
	return hits[0]["control"]

func blocking_control_for(button: BaseButton, root: Node) -> Control:
	if button == null:
		return null
	var top := top_control_at(root, button.get_global_rect().get_center())
	if top == null or top == button or button.is_ancestor_of(top) or top.is_ancestor_of(button):
		return null
	return top

func is_reachable(button: BaseButton, root: Node, safe_rect: Rect2 = Rect2()) -> bool:
	if button == null or button.disabled or not button.is_visible_in_tree():
		return false
	var rect := button.get_global_rect()
	if rect.size.x < 44.0 or rect.size.y < 44.0:
		return false
	if safe_rect.size != Vector2.ZERO and not safe_rect.has_point(rect.get_center()):
		return false
	return blocking_control_for(button, root) == null

func record(
	screen: String,
	control: Control,
	action: String,
	tap_position: Vector2,
	expected: String,
	result: String,
	blocked_by: String = ""
) -> void:
	var snapshot := control_snapshot(control)
	var header := "screen,control_name,action,tap_x,tap_y,expected,result,blocked_by,disabled,visible,rect,mouse_filter,canvas_layer,z_index"
	var row := [
		screen,
		String(snapshot.get("control_name", "")),
		action,
		"%.1f" % tap_position.x,
		"%.1f" % tap_position.y,
		expected,
		result,
		blocked_by,
		str(snapshot.get("disabled", false)),
		str(snapshot.get("visible", false)),
		_csv_value(str(snapshot.get("rect", Rect2()))),
		str(snapshot.get("mouse_filter", -1)),
		str(snapshot.get("canvas_layer", 0)),
		str(snapshot.get("z_index", 0))
	]
	_append_csv(header, ",".join(row))

func _collect_hits(node: Node, position: Vector2, hits: Array, order_counter: Array) -> void:
	for child in node.get_children():
		order_counter[0] = int(order_counter[0]) + 1
		if child is Control:
			var control := child as Control
			if control.is_visible_in_tree() and control.mouse_filter != Control.MOUSE_FILTER_IGNORE and control.get_global_rect().has_point(position):
				hits.append({
					"control": control,
					"canvas_layer": _canvas_layer_for(control),
					"z_index": control.z_index,
					"order": order_counter[0]
				})
		_collect_hits(child, position, hits, order_counter)

func _canvas_layer_for(node: Node) -> int:
	var current := node.get_parent()
	while current != null:
		if current is CanvasLayer:
			return (current as CanvasLayer).layer
		current = current.get_parent()
	return 0

func _append_csv(header: String, row: String) -> void:
	var exists := FileAccess.file_exists(path)
	var file := FileAccess.open(path, FileAccess.READ_WRITE if exists else FileAccess.WRITE)
	if file == null:
		return
	if exists:
		file.seek_end()
	else:
		file.store_line(header)
	file.store_line(row)

func _csv_value(value: String) -> String:
	return "\"%s\"" % value.replace("\"", "\"\"")
