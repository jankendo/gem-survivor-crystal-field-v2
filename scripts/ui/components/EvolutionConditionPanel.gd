extends PanelContainer
class_name EvolutionConditionPanel

const UiNavigation = preload("res://scripts/ui/UiNavigation.gd")

var label: Label

func _ready() -> void:
	add_theme_stylebox_override("panel", UiNavigation.card_style(UiNavigation.accent_for_kind("evolution")))
	label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 420
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.82))
	add_child(label)
	custom_minimum_size = Vector2(460, 88)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

func set_text(value: String) -> void:
	if label == null:
		_ready()
	label.text = value
