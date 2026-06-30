extends PanelContainer
class_name RewardPopup

const JaText = preload("res://scripts/ui/JaText.gd")
const RewardCardScript = preload("res://scripts/ui/components/RewardCard.gd")
const CrystalButtonScript = preload("res://scripts/ui/components/CrystalButton.gd")
const TouchSelectionSystemScript = preload("res://scripts/systems/TouchSelectionSystem.gd")
const SelectionContextSystemScript = preload("res://scripts/systems/SelectionContextSystem.gd")

signal reward_chosen(reward_id: String)
signal reroll_requested
signal banish_requested(reward_id: String)
signal skip_requested

var list: VBoxContainer
var selection = TouchSelectionSystemScript.new()
var touch_mode := false

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
	selection.option_selected.connect(func(option_id: String): reward_chosen.emit(option_id))
	selection.reroll_requested.connect(func(): reroll_requested.emit())
	selection.banish_requested.connect(func(option_id: String): banish_requested.emit(option_id))
	selection.skipped.connect(func(): skip_requested.emit())

func show_options(options: Array, controls: Dictionary = {}, use_touch_mode: bool = false) -> void:
	visible = true
	_clear()
	touch_mode = use_touch_mode
	var rerolls := int(controls.get("rerolls", 0))
	var banishes := int(controls.get("seal_remaining", controls.get("banishes", 0)))
	var banish_max := int(controls.get("seal_max", banishes))
	var skip_remaining := int(controls.get("skip_remaining", 0))
	var skip_max := int(controls.get("skip_max", skip_remaining))
	var skip_allowed := bool(controls.get("can_skip", false))
	var seal_allowed := bool(controls.get("can_seal", banishes > 0))
	var level_up_actions := bool(controls.get("level_up_actions", String(controls.get("context", "level_up")) == SelectionContextSystemScript.LEVEL_UP))
	var can_decline := bool(controls.get("can_decline", false))
	selection.configure(options, rerolls, banishes, skip_allowed, level_up_actions)
	var title = Label.new()
	var first_kind = String(options[0].get("kind", "")) if not options.is_empty() else ""
	title.text = String(controls.get("title", "ルーン契約" if first_kind.begins_with("contract") else "レベルアップ！"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	list.add_child(title)
	var index = 1
	for reward in options:
		var button = RewardCardScript.new()
		button.setup(reward, index, touch_mode)
		var reward_id = String(reward.get("uid", reward.get("id", "")))
		button.pressed.connect(func(): selection.select_id(reward_id))
		list.add_child(button)
		index += 1
	var button_size := Vector2(150, 56) if touch_mode else Vector2(132, 44)
	if level_up_actions:
		var actions := GridContainer.new()
		actions.columns = 3
		actions.add_theme_constant_override("h_separation", 10)
		actions.add_theme_constant_override("v_separation", 8)
		list.add_child(actions)
		var reroll = CrystalButtonScript.new()
		reroll.setup("再抽選\n残り%d" % rerolls, Color(0.42, 0.82, 1.0), button_size)
		reroll.disabled = rerolls <= 0
		reroll.pressed.connect(func(): selection.request_reroll())
		actions.add_child(reroll)
		var banish = CrystalButtonScript.new()
		banish.setup("封印\n%d/%d" % [banishes, banish_max], Color(1.0, 0.52, 0.42), button_size, true)
		banish.disabled = banishes <= 0 or not seal_allowed
		banish.pressed.connect(func(): selection.request_banish())
		actions.add_child(banish)
		var skip = CrystalButtonScript.new()
		var skip_text := "スキップ\n%d/%d" % [skip_remaining, skip_max] if skip_max > 0 else "スキップ"
		skip.setup(skip_text, Color(0.72, 0.78, 0.90), button_size)
		skip.disabled = not skip_allowed
		skip.pressed.connect(func(): selection.request_skip())
		actions.add_child(skip)
	elif can_decline:
		var decline = CrystalButtonScript.new()
		decline.setup(String(controls.get("decline_text", "取得しない")), Color(0.72, 0.78, 0.90), Vector2(button_size.x * 1.35, button_size.y))
		decline.pressed.connect(func(): skip_requested.emit())
		list.add_child(decline)

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
