extends Button
class_name CharacterCard

const UiNavigation = preload("res://scripts/ui/UiNavigation.gd")

func setup(character_name, role_text, trait_text, unlocked, selected, secret, cost_text = "", weapon_text = "", weakness_text = "") -> void:
	text = "%s%s\n役割：%s\n初期武器：%s\n特性：%s\n弱点：%s\n%s%s" % [
		"★ " if selected else "",
		String(character_name),
		String(role_text),
		String(weapon_text) if weapon_text != "" else "不明",
		String(trait_text) if bool(unlocked) else "未解放",
		String(weakness_text) if bool(unlocked) else "条件達成後に表示",
		"選択中" if selected else ("解放済み" if unlocked else "未解放"),
		"\n%s" % cost_text if cost_text != "" else ""
	]
	custom_minimum_size = Vector2(310, 188)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_color", Color(0.96, 0.98, 1.0) if bool(unlocked) else Color(0.72, 0.68, 0.82))
	var accent = Color(1.0, 0.86, 0.28) if bool(selected) else UiNavigation.accent_for_kind("secret" if bool(secret) else "settings")
	add_theme_stylebox_override("normal", UiNavigation.card_style(accent, false, bool(secret)))
	add_theme_stylebox_override("hover", UiNavigation.card_style(accent, true, bool(secret)))
	add_theme_stylebox_override("pressed", UiNavigation.card_style(accent.lightened(0.08), true, bool(secret)))

func setup_compact(character_name, role_text, unlocked, selected, secret, cost_text: String, min_size: Vector2) -> void:
	text = "%s%s\n%s\n%s" % [
		"● " if bool(selected) else "",
		String(character_name),
		String(role_text) if String(role_text) != "" else "役割未設定",
		"選択中" if bool(selected) else ("解放済み" if bool(unlocked) else ("未解放\n%s" % cost_text if cost_text != "" else "未解放"))
	]
	custom_minimum_size = min_size
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 18)
	add_theme_color_override("font_color", Color(0.98, 1.0, 1.0) if bool(unlocked) else Color(0.76, 0.72, 0.84))
	var accent = Color(1.0, 0.86, 0.28) if bool(selected) else UiNavigation.accent_for_kind("secret" if bool(secret) else "settings")
	add_theme_stylebox_override("normal", UiNavigation.card_style(accent, false, bool(secret)))
	add_theme_stylebox_override("hover", UiNavigation.card_style(accent, true, bool(secret)))
	add_theme_stylebox_override("pressed", UiNavigation.card_style(accent.lightened(0.08), true, bool(secret)))
	set("icon_max_width", 58)

func set_icon_path(path: String) -> void:
	if path == "" or not ResourceLoader.exists(path):
		return
	icon = load(path)
	set("expand_icon", true)
	set("icon_alignment", HORIZONTAL_ALIGNMENT_LEFT)
