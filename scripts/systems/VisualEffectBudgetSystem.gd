extends RefCounted
class_name VisualEffectBudgetSystem

const PROFILE_PATH := "res://data/visual_effect_profiles.json"
const PRIORITY_CRITICAL := 0
const PRIORITY_SIGNATURE := 1
const PRIORITY_COMBAT := 2
const PRIORITY_DECORATIVE := 3

var profiles: Dictionary = {}
var profile_id := "desktop_standard"
var profile: Dictionary = {}
var qa_metrics_enabled := false
var metrics: Dictionary = {}
var thermal_level := "nominal"
var stable_seconds := 0.0
var pressure_seconds := 0.0
var selection_buckets: Array = [[], [], [], []]

func _init() -> void:
	reload()
	set_profile(profile_id)

func reload() -> void:
	profiles = _load_json(PROFILE_PATH).get("profiles", {})

func set_profile(value: String) -> void:
	profile_id = value if profiles.has(value) else ("desktop_standard" if profiles.has("desktop_standard") else "")
	profile = profiles.get(profile_id, {})

func configure_metrics(enabled: bool) -> void:
	qa_metrics_enabled = enabled
	metrics.clear()

func rendered_limit(kind: String, fallback: int) -> int:
	var key := "max_rendered_%s" % kind
	var base := int(profile.get(key, fallback))
	match thermal_level:
		"fair":
			if kind in ["effects", "damage_numbers", "background_particles"]:
				return maxi(1, int(round(base * 0.80)))
		"serious":
			if kind == "background_particles":
				return 0
			if kind in ["effects", "damage_numbers", "projectiles", "gems"]:
				return maxi(1, int(round(base * 0.62)))
		"critical":
			if kind == "background_particles":
				return 0
			if kind in ["effects", "damage_numbers", "projectiles", "gems"]:
				return maxi(1, int(round(base * 0.48)))
	return base

func select_visual_items(
		items: Array,
		camera_position: Vector2,
		visible_size: Vector2,
		limit: int,
		margin: float = 96.0
	) -> Array:
	var result: Array = []
	if limit <= 0:
		return result
	var rect := Rect2(camera_position - visible_size * 0.5, visible_size).grow(margin)
	for bucket in selection_buckets:
		bucket.clear()
	for item in items:
		if not _visible(item, rect):
			continue
		selection_buckets[_priority(item)].append(item)
	for priority in range(PRIORITY_CRITICAL, PRIORITY_DECORATIVE + 1):
		for item in selection_buckets[priority]:
			if result.size() >= limit and priority != PRIORITY_CRITICAL:
				_metric("budget_rejected_commands")
				continue
			result.append(item)
			_metric("rendered_effects")
	return result

func adaptive_arc_segments(radius_screen_pixels: float, critical: bool = false) -> int:
	if critical:
		return 48
	var scale := float(profile.get("arc_segment_scale", 1.0))
	var radius := maxf(0.0, radius_screen_pixels)
	var segments := 10
	if radius >= 48.0:
		segments = 18
	if radius >= 120.0:
		segments = 28
	if thermal_level == "serious":
		scale *= 0.75
	elif thermal_level == "critical":
		scale *= 0.58
	return clampi(int(round(float(segments) * scale)), 8, 32)

func update_frame_pressure(frame_time_ms: float, delta: float) -> String:
	if frame_time_ms >= 33.0:
		pressure_seconds += delta
		stable_seconds = 0.0
	elif frame_time_ms <= 17.5:
		stable_seconds += delta
		pressure_seconds = maxf(0.0, pressure_seconds - delta * 0.5)
	else:
		pressure_seconds = maxf(0.0, pressure_seconds - delta * 0.2)
		stable_seconds = 0.0
	if pressure_seconds >= 4.0:
		thermal_level = _next_lower(thermal_level)
		pressure_seconds = 0.0
		stable_seconds = 0.0
	elif stable_seconds >= 10.0:
		thermal_level = _next_higher(thermal_level)
		stable_seconds = 0.0
	return thermal_level

func target_fps() -> int:
	return 30 if thermal_level == "critical" else 60

func snapshot() -> Dictionary:
	return {
		"enabled": qa_metrics_enabled,
		"profile_id": profile_id,
		"thermal_level": thermal_level,
		"metrics": metrics.duplicate(true)
	}

func _priority(item) -> int:
	if item is Dictionary:
		return clampi(int(item.get("priority", PRIORITY_COMBAT)), PRIORITY_CRITICAL, PRIORITY_DECORATIVE)
	if item.get("evolved") == true:
		return PRIORITY_SIGNATURE
	return PRIORITY_COMBAT

func _visible(item, rect: Rect2) -> bool:
	var pos: Vector2
	var end := Vector2.INF
	if item is Dictionary:
		pos = item.get("pos", item.get("position", item.get("start", rect.get_center())))
		end = item.get("end", Vector2.INF)
	else:
		pos = item.position
	return rect.has_point(pos) or (end != Vector2.INF and rect.has_point(end))

func _metric(key: String, amount: int = 1) -> void:
	if qa_metrics_enabled:
		metrics[key] = int(metrics.get(key, 0)) + amount

func _next_lower(value: String) -> String:
	match value:
		"nominal":
			return "fair"
		"fair":
			return "serious"
		"serious":
			return "critical"
	return "critical"

func _next_higher(value: String) -> String:
	match value:
		"critical":
			return "serious"
		"serious":
			return "fair"
		"fair":
			return "nominal"
	return "nominal"

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
