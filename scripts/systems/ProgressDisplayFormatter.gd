extends RefCounted
class_name ProgressDisplayFormatter

func format_value(current: float, target: float, value_type: String = "number") -> String:
	if value_type == "time":
		return "%s / %s" % [_time(current), _time(target)]
	if value_type == "rank":
		return "%s / %s" % [_rank_name(int(current)), _rank_name(int(target))]
	return "%s / %s" % [_number(current), _number(target)]

func format_progress(progress: Dictionary, include_percent: bool = true) -> String:
	if bool(progress.get("hidden", false)):
		return "進捗：条件発見後に表示"
	var prefix := "達成済み " if bool(progress.get("complete", false)) else ""
	var line := "%s%s：%s" % [
		prefix,
		String(progress.get("label", "進捗")),
		format_value(float(progress.get("current", 0.0)), float(progress.get("target", 1.0)), String(progress.get("value_type", "number")))
	]
	if include_percent:
		line += "\n進捗：%d%%" % int(round(float(progress.get("ratio", 0.0)) * 100.0))
	return line

func _number(value: float) -> String:
	return "%d" % int(round(value))

func _time(value: float) -> String:
	var seconds := maxi(0, int(round(value)))
	return "%d:%02d" % [seconds / 60, seconds % 60]

func _rank_name(value: int) -> String:
	var ranks := ["D", "C", "B", "A", "S", "SS"]
	return ranks[clampi(value, 0, ranks.size() - 1)]
