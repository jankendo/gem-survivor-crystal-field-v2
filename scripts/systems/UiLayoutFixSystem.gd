extends RefCounted
class_name UiLayoutFixSystem

func prepare_scroll(scroll: ScrollContainer) -> void:
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

func prepare_scroll_child(control: Control, minimum_width: float = 720.0) -> void:
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.custom_minimum_size.x = maxf(control.custom_minimum_size.x, minimum_width)

func prepare_text(control: Control, minimum_width: float = 180.0) -> void:
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.custom_minimum_size.x = maxf(control.custom_minimum_size.x, minimum_width)
	if control is Label:
		(control as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	elif control is RichTextLabel:
		(control as RichTextLabel).fit_content = true

func prepare_card(control: Control, minimum_width: float = 240.0) -> void:
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.custom_minimum_size.x = maxf(control.custom_minimum_size.x, minimum_width)

func menu_content_width(viewport_width: float, side_margin: float = 84.0) -> float:
	return maxf(720.0, viewport_width - side_margin * 2.0)

func columns_for_width(width: float, card_width: float, max_columns: int = 3) -> int:
	return clampi(int(floor(width / maxf(card_width, 1.0))), 1, max_columns)

