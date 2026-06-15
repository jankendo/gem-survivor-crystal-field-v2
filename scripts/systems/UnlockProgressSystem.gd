extends RefCounted
class_name UnlockProgressSystem

const TrackerScript = preload("res://scripts/systems/ProgressTrackerSystem.gd")

var tracker = TrackerScript.new()

func for_condition(save_data: Dictionary, condition: Dictionary) -> Dictionary:
	return tracker.progress_for_condition(save_data, condition)

func text(save_data: Dictionary, condition: Dictionary) -> String:
	return tracker.progress_text(save_data, condition)
