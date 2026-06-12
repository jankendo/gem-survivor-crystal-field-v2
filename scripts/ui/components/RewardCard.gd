extends Button
class_name RewardCard

const JaText = preload("res://scripts/ui/JaText.gd")
const UiNavigation = preload("res://scripts/ui/UiNavigation.gd")

var reward: Dictionary = {}

func setup(value: Dictionary, index: int, touch_mode: bool = false) -> void:
	reward = value.duplicate(true)
	var kind := String(reward.get("kind", ""))
	var tag := String(reward.get("type_label", "選択"))
	var evo := String(reward.get("evolution_hint", ""))
	var suffix := "\n%s" % evo if evo != "" else ""
	var prefix := "" if touch_mode else "%d　" % index
	text = "%s[%s] %s\n%s%s\n%s" % [prefix, tag, JaText.reward_name(reward), JaText.reward_description(reward), suffix, "タップして選択" if touch_mode else "クリックして選択"]
	custom_minimum_size = Vector2(520, 124 if touch_mode else 108)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_theme_font_size_override("font_size", 18)
	add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	var accent := UiNavigation.accent_for_kind("evolution" if evo != "" else kind)
	add_theme_stylebox_override("normal", UiNavigation.card_style(accent, false, kind == "secret"))
	add_theme_stylebox_override("hover", UiNavigation.card_style(accent, true, kind == "secret"))
	add_theme_stylebox_override("pressed", UiNavigation.card_style(accent.lightened(0.08), true, kind == "secret"))
