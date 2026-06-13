extends RefCounted
class_name DebugOverlayPolicySystem

const FORBIDDEN_IOS_TEXT := [
	"CPU", "FPS", "GPU", "Metal", "MEM", "memory", "available memory",
	"app memory", "frame interval", "game mode", "draw calls", "physics",
	"profiler", "debug", "collision", "pathing", "safe area", "touch point",
	"node count", "internal id", "build profile"
]

var enabled := false
var platform_name := ""
var release_build := false
var touch_mode := false
var desktop_touch_preview := false
var hidden_unlocked := false

func configure(
	settings: Dictionary = {},
	platform: String = OS.get_name(),
	is_release: bool = OS.has_feature("release"),
	is_touch_mode: bool = false,
	is_desktop_touch_preview: bool = false
) -> void:
	platform_name = platform
	release_build = is_release
	touch_mode = is_touch_mode
	desktop_touch_preview = is_desktop_touch_preview
	hidden_unlocked = false
	enabled = bool(settings.get("developer_mode", settings.get("developer_overlay", false)))

func can_create_overlay_node() -> bool:
	return platform_name != "iOS" and not release_build and not touch_mode and not desktop_touch_preview

func should_show() -> bool:
	return can_create_overlay_node() and enabled and hidden_unlocked

func toggle_hidden() -> bool:
	if not can_create_overlay_node():
		enabled = false
		hidden_unlocked = false
		return false
	hidden_unlocked = not hidden_unlocked
	if hidden_unlocked:
		enabled = true
	return should_show()

func normal_ui_contains_forbidden_text(text: String) -> bool:
	var lower := text.to_lower()
	for term in FORBIDDEN_IOS_TEXT:
		if lower.contains(String(term).to_lower()):
			return true
	return false

func overlay_text() -> String:
	if not should_show():
		return ""
	return "DEV\nFPS %d\nMEM %.1f MB\nOBJECTS %d" % [
		Engine.get_frames_per_second(),
		float(OS.get_static_memory_usage()) / 1048576.0,
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	]
