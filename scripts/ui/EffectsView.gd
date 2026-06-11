extends Control
class_name EffectsView

var flash_alpha := 0.0
var flash_color := Color.WHITE
var red_alpha := 0.0
var pop_text := ""
var pop_alpha := 0.0
var pop_scale := 1.0
var pop_color := Color.WHITE

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	flash_alpha = maxf(0.0, flash_alpha - delta * 3.0)
	red_alpha = maxf(0.0, red_alpha - delta * 2.2)
	pop_alpha = maxf(0.0, pop_alpha - delta * 1.9)
	pop_scale = lerpf(pop_scale, 1.0, delta * 5.0)
	if flash_alpha > 0.0 or red_alpha > 0.0 or pop_alpha > 0.0:
		queue_redraw()

func show_pop(label: String, color: Color) -> void:
	pop_text = label
	pop_color = color
	pop_alpha = 1.0
	pop_scale = 1.28
	flash_alpha = maxf(flash_alpha, 0.18)
	flash_color = Color(color.r, color.g, color.b, 0.25)
	queue_redraw()

func show_soft_flash(color: Color) -> void:
	flash_color = color
	flash_alpha = maxf(flash_alpha, color.a)
	queue_redraw()

func show_damage_flash() -> void:
	red_alpha = 0.55
	queue_redraw()

func _draw() -> void:
	if flash_alpha > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(flash_color.r, flash_color.g, flash_color.b, flash_alpha), true)
	if red_alpha > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.05, 0.02, red_alpha), false, 18.0)
	if pop_alpha > 0.0 and pop_text != "":
		var font := get_theme_default_font()
		var font_size := int(52 * pop_scale)
		var pos := Vector2(0, size.y * 0.39)
		draw_string(font, pos, pop_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, Color(pop_color.r, pop_color.g, pop_color.b, pop_alpha))
