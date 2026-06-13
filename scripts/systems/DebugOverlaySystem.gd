extends RefCounted
class_name DebugOverlaySystem

const FORBIDDEN_IOS_TEXT := [
	"CPU", "FPS", "MEM", "memory", "draw calls", "physics", "profiler",
	"debug", "collision", "pathing", "safe area", "touch point", "node count"
]

var enabled := false
var platform_name := ""
var release_build := false
var hidden_unlocked := false

func configure(settings: Dictionary = {}, platform: String = OS.get_name(), is_release: bool = OS.has_feature("release")) -> void:
	platform_name = platform
	release_build = is_release
	hidden_unlocked = false
	enabled = bool(settings.get("developer_overlay", false))

func should_show() -> bool:
	if platform_name == "iOS" or release_build:
		return false
	return enabled and hidden_unlocked

func toggle_hidden() -> bool:
	if platform_name == "iOS" or release_build:
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
