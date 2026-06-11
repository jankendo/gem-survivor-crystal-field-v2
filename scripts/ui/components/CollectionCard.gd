extends PanelContainer
class_name CollectionCard

const UiNavigation = preload("res://scripts/ui/UiNavigation.gd")

var label: Label

func setup(data: Dictionary) -> void:
	var known = bool(data.get("known", false))
	var unlocked = bool(data.get("unlocked", known))
	custom_minimum_size = Vector2(310, 132)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", UiNavigation.card_style(Color(0.42, 0.82, 1.0) if known else Color(0.44, 0.34, 0.62), false, not known))
	label = Label.new()
	var detail = String(data.get("detail_ja", ""))
	var unlock_text = String(data.get("unlock_text_ja", ""))
	label.text = "%s\n%s\n%s%s" % [
		String(data.get("name_ja", "？？？")),
		String(data.get("status_ja", "発見済み" if known else "未発見")),
		detail if known else unlock_text,
		"\n条件：%s" % unlock_text if not unlocked and unlock_text != "" else ""
	]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 280
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(0.88, 0.94, 0.98) if known else Color(0.68, 0.66, 0.78))
	add_child(label)

