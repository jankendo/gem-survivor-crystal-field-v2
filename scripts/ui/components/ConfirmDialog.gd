extends PanelContainer
class_name ConfirmDialog

signal confirmed
signal canceled

const CrystalButtonScript = preload("res://scripts/ui/components/CrystalButton.gd")

func setup(title: String, body: String, confirm_label: String = "決定", cancel_label: String = "戻る", touch_mode: bool = false) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	for child in get_children():
		child.queue_free()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	var title_label := Label.new()
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.36))
	root.add_child(title_label)
	var body_label := Label.new()
	body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_label.text = body
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.add_theme_font_size_override("font_size", 18)
	body_label.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0))
	root.add_child(body_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	root.add_child(row)
	var cancel_button = CrystalButtonScript.new()
	cancel_button.setup(cancel_label, Color(0.42, 0.82, 1.0), Vector2(160, 64 if touch_mode else 42))
	cancel_button.pressed.connect(func(): canceled.emit())
	row.add_child(cancel_button)
	var confirm_button = CrystalButtonScript.new()
	confirm_button.setup(confirm_label, Color(1.0, 0.32, 0.42), Vector2(160, 64 if touch_mode else 42), true)
	confirm_button.pressed.connect(func(): confirmed.emit())
	row.add_child(confirm_button)
