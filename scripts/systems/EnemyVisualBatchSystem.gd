extends RefCounted
class_name EnemyVisualBatchSystem

func batch_commands(snapshot: Dictionary) -> Dictionary:
	var batches: Dictionary = {}
	var critical: Array = []
	for command in snapshot.get("commands", []):
		var row: Dictionary = command
		if bool(row.get("critical", false)):
			critical.append(row)
			continue
		var key := "%s:%d:%d" % [String(row.get("type", "")), int(row.get("phase", 0)), int(row.get("outline_layers", 1))]
		if not batches.has(key):
			batches[key] = {"type": row.get("type", ""), "phase": row.get("phase", 0), "count": 0, "positions": []}
		batches[key]["count"] = int(batches[key].get("count", 0)) + 1
		if (batches[key]["positions"] as Array).size() < 8:
			(batches[key]["positions"] as Array).append(row.get("position", Vector2.ZERO))
	return {
		"batches": batches.values(),
		"critical": critical,
		"batch_count": batches.size(),
		"critical_count": critical.size(),
		"render_commands": batches.size() + critical.size()
	}

func estimated_command_reduction(standard_commands: int, batched_commands: int) -> float:
	return 1.0 - float(batched_commands) / float(maxi(1, standard_commands))
