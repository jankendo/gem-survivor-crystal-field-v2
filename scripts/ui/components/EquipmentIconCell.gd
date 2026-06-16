extends Button
class_name EquipmentIconCell

var equipment_kind := "weapon"
var equipment_id := ""
var unlocked := true
var equipped_level := 0

func setup(kind: String, id: String, data: Dictionary, level: int, is_unlocked: bool, is_enabled: bool = true) -> void:
	equipment_kind = kind
	equipment_id = id
	equipped_level = level
	unlocked = is_unlocked
	name = "EquipmentIconCell_%s_%s" % [kind, id]
	var label := String(data.get("name_ja", id))
	text = "%s\n%s" % [label, "Lv%d" % level if level > 0 else ("解放済み" if is_unlocked else "未解放")]
	tooltip_text = "%s\n%s" % [label, String(data.get("description_ja", data.get("effect_ja", "")))]
	custom_minimum_size = Vector2(132, 104)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_ALL
	disabled = not is_enabled
	add_theme_font_size_override("font_size", 15)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.055, 0.075, 0.105, 0.96) if is_unlocked else Color(0.055, 0.055, 0.065, 0.88)
	normal.border_color = Color(0.42, 0.82, 1.0) if is_unlocked else Color(0.28, 0.31, 0.36)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.09, 0.13, 0.18, 0.98)
	hover.border_color = Color(1.0, 0.82, 0.34)
	add_theme_stylebox_override("hover", hover)
	var icon_path := String(data.get("generated_icon", data.get("generated_sprite", data.get("icon", ""))))
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon = load(icon_path)
		set("expand_icon", true)
		set("icon_alignment", HORIZONTAL_ALIGNMENT_LEFT)
