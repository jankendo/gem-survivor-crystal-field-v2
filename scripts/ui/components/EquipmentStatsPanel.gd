extends PanelContainer
class_name EquipmentStatsPanel

var label: Label

func _ready() -> void:
	if label != null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.060, 0.085, 0.96)
	style.border_color = Color(0.52, 1.0, 0.78)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)
	label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.88, 0.96, 0.98))
	add_child(label)

func set_stats(kind: String, owned: int, unlocked: int, total: int, over_cap: int) -> void:
	if label == null:
		_ready()
	label.text = "%s：所持%d / 解放%d / 全%d / 枠超過+%d" % ["武器" if kind == "weapon" else "パッシブ", owned, unlocked, total, over_cap]
