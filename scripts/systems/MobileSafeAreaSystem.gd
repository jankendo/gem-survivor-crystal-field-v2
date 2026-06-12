extends RefCounted
class_name MobileSafeAreaSystem

const LANDSCAPE_PRESETS := {
	"1334x750": Vector4(50, 12, 50, 24),
	"1792x828": Vector4(44, 12, 44, 24),
	"2532x1170": Vector4(88, 18, 88, 34),
	"2556x1179": Vector4(92, 18, 92, 34),
	"2796x1290": Vector4(96, 20, 96, 36),
	"2388x1668": Vector4(36, 24, 36, 30),
	"2732x2048": Vector4(42, 28, 42, 34)
}

func insets_for(viewport_size: Vector2, extra_margin: float = 0.0) -> Vector4:
	var key := "%dx%d" % [int(viewport_size.x), int(viewport_size.y)]
	var insets: Vector4 = LANDSCAPE_PRESETS.get(key, _estimated_insets(viewport_size))
	return Vector4(
		insets.x + extra_margin,
		insets.y + extra_margin,
		insets.z + extra_margin,
		insets.w + extra_margin
	)

func safe_rect(viewport_size: Vector2, extra_margin: float = 0.0) -> Rect2:
	var insets := insets_for(viewport_size, extra_margin)
	return Rect2(
		Vector2(insets.x, insets.y),
		Vector2(maxf(1.0, viewport_size.x - insets.x - insets.z), maxf(1.0, viewport_size.y - insets.y - insets.w))
	)

func runtime_safe_rect(viewport_size: Vector2, extra_margin: float = 0.0) -> Rect2:
	var fallback := safe_rect(viewport_size, extra_margin)
	if OS.get_name() != "iOS":
		return fallback
	var usable := DisplayServer.screen_get_usable_rect()
	if usable.size.x <= 1 or usable.size.y <= 1:
		return fallback
	var scale := Vector2(viewport_size.x / float(usable.size.x), viewport_size.y / float(usable.size.y))
	var rect := Rect2(Vector2(usable.position) * scale, Vector2(usable.size) * scale)
	return rect.grow(-extra_margin)

func contains(rect: Rect2, viewport_size: Vector2, extra_margin: float = 0.0) -> bool:
	return safe_rect(viewport_size, extra_margin).encloses(rect)

func _estimated_insets(viewport_size: Vector2) -> Vector4:
	var is_tablet := viewport_size.y >= 1500.0
	var side := clampf(viewport_size.x * (0.016 if is_tablet else 0.036), 28.0, 100.0)
	var top := clampf(viewport_size.y * 0.016, 12.0, 32.0)
	var bottom := clampf(viewport_size.y * 0.028, 22.0, 40.0)
	return Vector4(side, top, side, bottom)
