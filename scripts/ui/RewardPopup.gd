extends PanelContainer
class_name RewardPopup

const JaText = preload("res://scripts/ui/JaText.gd")
const RewardCardScript = preload("res://scripts/ui/components/RewardCard.gd")

signal reward_chosen(reward_id: String)

var list: VBoxContainer

func _ready() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.09, 0.12, 0.96)
	style.border_color = Color(0.47, 0.75, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", style)
	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	add_child(list)

func show_options(options: Array) -> void:
	visible = true
	_clear()
	var title = Label.new()
	var first_kind = String(options[0].get("kind", "")) if not options.is_empty() else ""
	title.text = "ルーン契約" if first_kind.begins_with("contract") else "レベルアップ！"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	list.add_child(title)
	var index = 1
	for reward in options:
		var button = RewardCardScript.new()
		button.setup(reward, index)
		var reward_id = String(reward.get("uid", reward.get("id", "")))
		button.pressed.connect(func(): reward_chosen.emit(reward_id))
		list.add_child(button)
		index += 1

func hide_popup() -> void:
	visible = false

func _clear() -> void:
	if list == null:
		return
	for child in list.get_children():
		child.queue_free()

func _hint_suffix(reward: Dictionary) -> String:
	var hint = String(reward.get("evolution_hint", ""))
	if hint == "":
		return ""
	return "\n%s" % hint

func _button_style(kind: String, hover: bool) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	var color = Color(0.12, 0.15, 0.20, 0.96)
	var border = Color(0.38, 0.62, 0.90)
	if kind == "weapon":
		color = Color(0.13, 0.17, 0.25, 0.96)
		border = Color(0.42, 0.72, 1.0)
	elif kind == "passive":
		color = Color(0.14, 0.20, 0.16, 0.96)
		border = Color(0.48, 0.92, 0.58)
	elif kind == "infinite":
		color = Color(0.20, 0.14, 0.25, 0.96)
		border = Color(0.86, 0.48, 1.0)
	elif kind == "overclock":
		color = Color(0.22, 0.15, 0.09, 0.96)
		border = Color(1.0, 0.70, 0.20)
	elif kind == "contract":
		color = Color(0.20, 0.08, 0.10, 0.96)
		border = Color(1.0, 0.30, 0.34)
	if hover:
		color = color.lightened(0.08)
		border = border.lightened(0.10)
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
