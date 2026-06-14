extends RefCounted
class_name UiDirtyFlagSystem

var signatures: Dictionary = {}
var elapsed: Dictionary = {}
var intervals: Dictionary = {}
var update_counts: Dictionary = {}

func configure(defaults: Dictionary = {}) -> void:
	intervals = defaults.duplicate(true)

func tick(delta: float) -> void:
	for key in elapsed:
		elapsed[key] = float(elapsed[key]) + delta

func should_update(key: String, signature: String, interval: float = -1.0) -> bool:
	var wait := interval if interval >= 0.0 else float(intervals.get(key, 0.0))
	var changed := String(signatures.get(key, "")) != signature
	var due := float(elapsed.get(key, INF)) >= wait
	if not changed and not due:
		return false
	signatures[key] = signature
	elapsed[key] = 0.0
	update_counts[key] = int(update_counts.get(key, 0)) + 1
	return true

func mark_dirty(key: String) -> void:
	signatures.erase(key)

func count(key: String) -> int:
	return int(update_counts.get(key, 0))
