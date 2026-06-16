extends RefCounted
class_name NotchLetterboxSystem

func bars_for(viewport_size: Vector2, play_rect: Rect2) -> Array:
	return preload("res://scripts/systems/IosSafePlayAreaSystem.gd").new().letterbox_bars(viewport_size, play_rect)

func apply_to_color_rects(left: ColorRect, right: ColorRect, viewport_size: Vector2, play_rect: Rect2) -> void:
	var bars := bars_for(viewport_size, play_rect)
	var left_rect := Rect2(Vector2.ZERO, Vector2.ZERO)
	var right_rect := Rect2(Vector2(viewport_size.x, 0.0), Vector2.ZERO)
	if bars.size() >= 1:
		left_rect = bars[0]
	if bars.size() >= 2:
		right_rect = bars[1]
	_apply_rect(left, left_rect)
	_apply_rect(right, right_rect)

func _apply_rect(control: Control, rect: Rect2) -> void:
	if control == null:
		return
	control.visible = rect.size.x > 0.0 and rect.size.y > 0.0
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.end.x
	control.offset_bottom = rect.end.y
