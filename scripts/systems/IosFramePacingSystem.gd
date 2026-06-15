extends RefCounted
class_name IosFramePacingSystem

var previous_max_fps := 0
var applied_target_fps := 0
var has_previous := false

func apply(profile: Dictionary, enabled: bool) -> int:
	if not enabled:
		return Engine.max_fps
	if not has_previous:
		previous_max_fps = Engine.max_fps
		has_previous = true
	applied_target_fps = clampi(int(profile.get("target_fps", 60)), 30, 120)
	Engine.max_fps = applied_target_fps
	return applied_target_fps

func restore() -> void:
	if has_previous:
		Engine.max_fps = previous_max_fps
	previous_max_fps = 0
	applied_target_fps = 0
	has_previous = false
