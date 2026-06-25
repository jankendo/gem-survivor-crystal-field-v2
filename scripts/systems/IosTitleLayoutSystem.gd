extends RefCounted
class_name IosTitleLayoutSystem

const HIDDEN_TOUCH_ACTIONS := ["quit"]
const DEFAULT_ACTION_IDS := [
	"start",
	"characters",
	"shop",
	"loadout",
	"collection",
	"quests",
	"settings",
	"help",
	"reset",
	"quit"
]

const DEVICE_PROFILES := [
	{"id": "iphone_se_landscape", "size": Vector2(1334, 750), "orientation": "landscape_left"},
	{"id": "iphone_11_landscape", "size": Vector2(1792, 828), "orientation": "landscape_left"},
	{"id": "iphone_13_landscape", "size": Vector2(2532, 1170), "orientation": "landscape_left"},
	{"id": "iphone_15_landscape", "size": Vector2(2556, 1179), "orientation": "landscape_left"},
	{"id": "iphone_15_pro_max_landscape", "size": Vector2(2796, 1290), "orientation": "landscape_left"},
	{"id": "ipad_11_landscape", "size": Vector2(2388, 1668), "orientation": "landscape_left"},
	{"id": "ipad_12_9_landscape", "size": Vector2(2732, 2048), "orientation": "landscape_left"}
]

func device_profiles() -> Array:
	return DEVICE_PROFILES.duplicate(true)

func visible_action_ids(action_ids: Array = DEFAULT_ACTION_IDS) -> Array:
	var result: Array = []
	for raw_id in action_ids:
		var action_id := String(raw_id)
		if HIDDEN_TOUCH_ACTIONS.has(action_id):
			continue
		result.append(action_id)
	return result

func classify(viewport_size: Vector2, safe_rect: Rect2) -> String:
	var safe_size := _safe_size(viewport_size, safe_rect)
	var aspect := maxf(safe_size.x, safe_size.y) / maxf(1.0, minf(safe_size.x, safe_size.y))
	if viewport_size.x >= 2300.0 and aspect <= 1.55:
		return "tablet"
	if viewport_size.x <= 1599.0:
		return "compact_phone"
	if viewport_size.x <= 2299.0:
		return "regular_phone"
	return "large_phone"

func metrics(viewport_size: Vector2, safe_rect: Rect2, action_ids: Array = DEFAULT_ACTION_IDS) -> Dictionary:
	var safe_size := _safe_size(viewport_size, safe_rect)
	var profile := classify(viewport_size, safe_rect)
	var short_side := minf(safe_size.x, safe_size.y)
	var visible_actions := visible_action_ids(action_ids)
	var columns := 1
	if safe_size.x >= 860.0:
		columns = 2
	if profile == "tablet" and safe_size.x >= 1500.0:
		columns = 3
	var gap := 8.0 if profile == "compact_phone" else 12.0
	var title_font := int(clampf(round(short_side * (0.052 if profile != "tablet" else 0.035)), 24.0, 42.0))
	var subtitle_font := int(clampf(round(short_side * 0.025), 14.0, 22.0))
	var body_font := int(clampf(round(short_side * 0.024), 15.0, 20.0))
	var key_visual_height := clampf(short_side * (0.13 if profile == "compact_phone" else 0.15), 72.0, 150.0)
	var status_min_height := key_visual_height + body_font * 4.0 + gap * 4.0
	var button_height := clampf(short_side * (0.090 if profile != "tablet" else 0.060), 64.0, 76.0)
	var secondary_button_height := clampf(button_height - 4.0, 64.0, 72.0)
	var grid_button_count := maxi(0, visible_actions.size() - 1)
	var grid_rows := int(ceil(float(grid_button_count) / float(maxi(1, columns))))
	var header_height := float(title_font + subtitle_font + 16 + int(gap * 2.0))
	var content_height := header_height + status_min_height + button_height + gap * 5.0
	if grid_rows > 0:
		content_height += grid_rows * secondary_button_height + maxi(0, grid_rows - 1) * gap
	content_height += 14.0
	return {
		"profile": profile,
		"columns": columns,
		"gap": gap,
		"title_font": title_font,
		"subtitle_font": subtitle_font,
		"version_font": 13,
		"body_font": body_font,
		"key_visual_height": key_visual_height,
		"status_min_height": status_min_height,
		"button_height": button_height,
		"secondary_button_height": secondary_button_height,
		"content_width": maxf(320.0, safe_size.x),
		"content_height": content_height,
		"scroll_required": content_height > safe_size.y,
		"visible_actions": visible_actions
	}

func contract(viewport_size: Vector2, safe_rect: Rect2, action_ids: Array = DEFAULT_ACTION_IDS) -> Dictionary:
	var safe := _safe_rect(viewport_size, safe_rect)
	var data := metrics(viewport_size, safe, action_ids)
	var width := float(data.get("content_width", safe.size.x))
	var gap := float(data.get("gap", 10.0))
	var rects: Dictionary = {}
	var y := 0.0
	var header_height := float(data.get("title_font", 28)) + float(data.get("subtitle_font", 16)) + 29.0
	rects["title_header"] = Rect2(Vector2(0, y), Vector2(width, header_height))
	y += header_height + gap
	rects["status_card"] = Rect2(Vector2(0, y), Vector2(width, float(data.get("status_min_height", 120.0))))
	y += rects["status_card"].size.y + gap
	rects["button.start"] = Rect2(Vector2(0, y), Vector2(width, float(data.get("button_height", 64.0))))
	y += rects["button.start"].size.y + gap
	var visible_actions: Array = data.get("visible_actions", visible_action_ids(action_ids))
	var grid_actions: Array = []
	for action_id in visible_actions:
		if String(action_id) != "start":
			grid_actions.append(String(action_id))
	var columns := int(data.get("columns", 2))
	var secondary_height := float(data.get("secondary_button_height", 60.0))
	var button_width := (width - gap * float(columns - 1)) / float(maxi(1, columns))
	for i in range(grid_actions.size()):
		var col := i % columns
		var row := int(floor(float(i) / float(columns)))
		rects["button.%s" % String(grid_actions[i])] = Rect2(
			Vector2(float(col) * (button_width + gap), y + float(row) * (secondary_height + gap)),
			Vector2(button_width, secondary_height)
		)
	var rows := int(ceil(float(grid_actions.size()) / float(maxi(1, columns))))
	if rows > 0:
		y += float(rows) * secondary_height + float(maxi(0, rows - 1)) * gap
	y += 14.0
	return {
		"safe_rect": safe,
		"scroll_rect": safe,
		"content_size": Vector2(width, y),
		"rects": rects,
		"metrics": data,
		"scroll_required": y > safe.size.y
	}

func all_buttons_fit_width(viewport_size: Vector2, safe_rect: Rect2, action_ids: Array = DEFAULT_ACTION_IDS) -> bool:
	var layout := contract(viewport_size, safe_rect, action_ids)
	var content_width := (layout.get("content_size", Vector2.ZERO) as Vector2).x
	for key in (layout.get("rects", {}) as Dictionary).keys():
		var rect: Rect2 = layout["rects"][key]
		if String(key).begins_with("button.") and (rect.position.x < -0.01 or rect.end.x > content_width + 0.01):
			return false
	return true

func _safe_rect(viewport_size: Vector2, safe_rect: Rect2) -> Rect2:
	if safe_rect.size.x <= 0.0 or safe_rect.size.y <= 0.0:
		return Rect2(Vector2.ZERO, viewport_size)
	return safe_rect

func _safe_size(viewport_size: Vector2, safe_rect: Rect2) -> Vector2:
	return _safe_rect(viewport_size, safe_rect).size
