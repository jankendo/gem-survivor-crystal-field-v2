extends PanelContainer
class_name EquipmentDetailSheet

var title_label: Label
var body_label: Label

func _ready() -> void:
	if title_label != null:
		return
	add_theme_stylebox_override("panel", _panel_style())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.38))
	box.add_child(title_label)
	body_label = Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 16)
	body_label.add_theme_color_override("font_color", Color(0.86, 0.92, 0.98))
	box.add_child(body_label)

func show_equipment(kind: String, id: String, data: Dictionary, level: int, is_unlocked: bool) -> void:
	if title_label == null:
		_ready()
	title_label.text = "%s / %s" % [String(data.get("name_ja", id)), "武器" if kind == "weapon" else "パッシブ"]
	body_label.text = "\n".join([
		"状態：%s" % ("Lv%d" % level if level > 0 else ("解放済み" if is_unlocked else "未解放")),
		"説明：%s" % String(data.get("description_ja", data.get("effect_ja", ""))),
		"次の判断：%s" % ("伸ばす価値あり" if level > 0 else ("候補で見つけたら取得検討" if is_unlocked else "解放条件を先に進める"))
	])

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.048, 0.070, 0.98)
	style.border_color = Color(0.46, 0.75, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	return style
