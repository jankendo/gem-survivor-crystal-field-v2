extends RefCounted
class_name AchievementProgressSystem

const TrackerScript = preload("res://scripts/systems/ProgressTrackerSystem.gd")

var tracker = TrackerScript.new()

func row(save_data: Dictionary, quest: Dictionary, completed: bool) -> Dictionary:
	var progress := tracker.progress_for_condition(save_data, quest.get("condition", {}))
	progress["complete"] = completed or bool(progress.get("complete", false))
	progress["title"] = String(quest.get("name_ja", "実績"))
	progress["description"] = String(quest.get("description_ja", ""))
	return progress

func is_in_progress(progress: Dictionary) -> bool:
	return float(progress.get("current", 0.0)) > 0.0 and not bool(progress.get("complete", false))

func is_near(progress: Dictionary) -> bool:
	return not bool(progress.get("complete", false)) and float(progress.get("ratio", 0.0)) >= 0.75
