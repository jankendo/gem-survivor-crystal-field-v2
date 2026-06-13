extends Button
class_name TouchActionButton

signal action_started(action: String)
signal action_ended(action: String)

const UiNavigation = preload("res://scripts/ui/UiNavigation.gd")

var action_name := ""
var hold_action := false
var accent_color := Color(0.42, 0.88, 1.0)
var haptics_enabled := true
var hold_progress := 0.0
var holding := false

func _process(delta: float) -> void:
	if not hold_action or not holding:
		return
	hold_progress = minf(1.0, hold_progress + delta / 0.55)
	queue_redraw()

func setup(action: String, label: String, accent: Color, extent: float, hold: bool = false, opacity: float = 0.78) -> void:
	action_name = action
	text = label
	accent_color = Color(accent.r, accent.g, accent.b, clampf(opacity, 0.35, 1.0))
	hold_action = hold
	custom_minimum_size = Vector2(extent, extent)
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_font_size_override("font_size", 20)
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_stylebox_override("normal", UiNavigation.button_style(accent_color, false, false))
	add_theme_stylebox_override("hover", UiNavigation.button_style(accent_color, true, false))
	add_theme_stylebox_override("pressed", UiNavigation.button_style(accent_color.lightened(0.14), true, false))
	add_theme_stylebox_override("disabled", UiNavigation.button_style(Color(0.20, 0.24, 0.30, 0.70), false, false))
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	set_process(hold_action)

func set_ready_state(ready: bool) -> void:
	disabled = not ready
	modulate = Color.WHITE if ready else Color(0.64, 0.68, 0.74)

func set_active_state(active: bool, active_label: String = "") -> void:
	if active_label != "":
		text = active_label if active else text
	modulate = Color(1.18, 1.18, 1.18) if active else Color.WHITE

func _on_button_down() -> void:
	if disabled:
		return
	if haptics_enabled:
		Input.vibrate_handheld(22)
	holding = hold_action
	hold_progress = 0.0
	action_started.emit(action_name)
	if not hold_action:
		action_ended.emit(action_name)

func _on_button_up() -> void:
	if hold_action:
		holding = false
		hold_progress = 0.0
		queue_redraw()
		action_ended.emit(action_name)

func _draw() -> void:
	if not hold_action or hold_progress <= 0.0:
		return
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.43
	draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * hold_progress, 48, Color(1.0, 0.92, 0.34, 0.95), 5.0)
