extends Node
class_name AudioManager

var audio_event_count := 0
var audio_disabled := true

func play_sfx(_name: String) -> bool:
	return false

func stop_all() -> void:
	pass
