extends HBoxContainer
class_name SettingsSlider

signal value_changed(value: float)

var label: Label
var slider: HSlider

func setup(title: String, value: float, min_value: float = 0.0, max_value: float = 1.0) -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(520, 56)
	if label == null:
		label = Label.new()
		label.custom_minimum_size = Vector2(190, 30)
		label.add_theme_font_size_override("font_size", 18)
		add_child(label)
		slider = HSlider.new()
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.x = 260
		add_child(slider)
	label.text = title
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 0.01
	slider.value = value
	slider.value_changed.connect(func(v): value_changed.emit(float(v)))
