extends ScrollContainer
class_name ScrollableList

var list: VBoxContainer

func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.custom_minimum_size.x = 720
	list.add_theme_constant_override("separation", 10)
	add_child(list)

func clear_items() -> void:
	if list == null:
		return
	for child in list.get_children():
		child.queue_free()

func add_item(node: Control) -> void:
	if list == null:
		_ready()
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_child(node)
