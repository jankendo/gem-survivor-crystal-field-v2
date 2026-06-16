extends HBoxContainer
class_name EquipmentFilterChips

signal filter_changed(filter_id: String)

var selected_filter := "all"
var buttons: Dictionary = {}

func setup(filters: Array = ["all", "owned", "unlocked", "locked"]) -> void:
	for child in get_children():
		child.queue_free()
	buttons.clear()
	add_theme_constant_override("separation", 8)
	for filter_id in filters:
		var id := String(filter_id)
		var button := Button.new()
		button.text = _label_for(id)
		button.custom_minimum_size = Vector2(104, 42)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(func(): select_filter(id))
		add_child(button)
		buttons[id] = button
	_refresh()

func select_filter(filter_id: String) -> void:
	selected_filter = filter_id
	_refresh()
	filter_changed.emit(filter_id)

func _refresh() -> void:
	for id in buttons.keys():
		var button: Button = buttons[id]
		button.modulate = Color(1.0, 0.86, 0.38) if String(id) == selected_filter else Color(0.82, 0.92, 1.0)

func _label_for(filter_id: String) -> String:
	match filter_id:
		"owned":
			return "所持"
		"unlocked":
			return "解放済み"
		"locked":
			return "未解放"
	return "すべて"
