extends PanelContainer
class_name TabbedPanel

signal tab_selected(index: int)

const CrystalButtonScript = preload("res://scripts/ui/components/CrystalButton.gd")

var tab_bar: HBoxContainer
var content: Control
var tabs: Array = []
var selected_index := 0

func _ready() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	tab_bar = HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 6)
	root.add_child(tab_bar)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.custom_minimum_size.x = 520
	root.add_child(content)

func set_tabs(values: Array) -> void:
	tabs = values.duplicate()
	_refresh_tabs()

func set_selected(index: int) -> void:
	selected_index = clampi(index, 0, maxi(tabs.size() - 1, 0))
	_refresh_tabs()
	tab_selected.emit(selected_index)

func _refresh_tabs() -> void:
	if tab_bar == null:
		return
	for child in tab_bar.get_children():
		child.queue_free()
	for i in range(tabs.size()):
		var button = CrystalButtonScript.new()
		button.setup(String(tabs[i]), Color(1.0, 0.86, 0.28) if i == selected_index else Color(0.42, 0.82, 1.0), Vector2(0, 38))
		button.pressed.connect(set_selected.bind(i))
		tab_bar.add_child(button)
