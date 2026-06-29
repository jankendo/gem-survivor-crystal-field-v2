extends VBoxContainer
class_name SettingsChoiceOption

signal choice_selected(key: String, value)

var setting_key := ""
var option_button: OptionButton

func setup(title: String, key: String, current, choices: Array, labels: Dictionary, effective_text: String = "") -> void:
	setting_key = key
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	var title_label := Label.new()
	title_label.text = title
	title_label.custom_minimum_size.x = 220.0
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 18)
	row.add_child(title_label)
	option_button = OptionButton.new()
	option_button.name = "Choice_%s" % key
	option_button.custom_minimum_size = Vector2(260, 52)
	option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option_button.fit_to_longest_item = true
	var selected_index := 0
	for index in range(choices.size()):
		var value = choices[index]
		option_button.add_item(String(labels.get(str(value), str(value))))
		option_button.set_item_metadata(index, value)
		if _same_value(value, current):
			selected_index = index
	option_button.select(selected_index)
	option_button.item_selected.connect(_on_item_selected)
	row.add_child(option_button)
	if effective_text != "":
		var effective_label := Label.new()
		effective_label.text = "省電力モードにより実効値：%s" % effective_text
		effective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effective_label.add_theme_font_size_override("font_size", 14)
		effective_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
		add_child(effective_label)

func _on_item_selected(index: int) -> void:
	choice_selected.emit(setting_key, option_button.get_item_metadata(index))

func _same_value(a, b) -> bool:
	if a is float or b is float:
		return is_equal_approx(float(a), float(b))
	return a == b
