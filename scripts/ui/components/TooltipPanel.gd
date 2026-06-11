extends PanelContainer
class_name TooltipPanel

var label: Label

func _ready() -> void:
	label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(300, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0))
	add_child(label)
	custom_minimum_size = Vector2(330, 96)
	hide()

func show_tooltip(text: String, global_pos: Vector2) -> void:
	if label == null:
		_ready()
	label.text = text
	position = global_pos
	show()
