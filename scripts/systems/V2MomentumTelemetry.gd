extends RefCounted
class_name V2MomentumTelemetry

const DEFAULT_PATH := "user://v2_momentum_telemetry.csv"

var enabled := false
var rows: Array = []
var max_rows := 4096

func configure(value: bool, row_limit: int = 4096) -> void:
	enabled = value
	max_rows = maxi(32, row_limit)

func record(state, trigger_type: String = "") -> void:
	if not enabled:
		return
	rows.append(snapshot(state, trigger_type))
	while rows.size() > max_rows:
		rows.pop_front()

func snapshot(state, trigger_type: String = "") -> Dictionary:
	var weighted_time := maxf(0.001, float(state.v2_momentum_weighted_time))
	return {
		"elapsed_seconds": float(state.elapsed_seconds),
		"momentum_active": float(state.v2_momentum_timer) > 0.0,
		"momentum_tier": int(state.v2_momentum_tier),
		"remaining_seconds": float(state.v2_momentum_timer),
		"trigger_type": trigger_type if trigger_type != "" else String(state.v2_momentum_reason),
		"trigger_count": int(state.v2_momentum_triggers),
		"active_time_total": float(state.v2_momentum_active_time_total),
		"score_base": int(state.v2_momentum_score_base),
		"score_momentum_bonus": int(state.v2_momentum_score_bonus),
		"weighted_multiplier": float(state.v2_momentum_weighted_multiplier_sum) / weighted_time,
		"kill_streak": int(state.v2_kill_streak),
		"no_hit_seconds": float(state.v2_no_damage_timer),
		"boss_kills": int(state.v2_momentum_trigger_counts.get("boss_defeat", 0)),
		"evolutions": int(state.v2_momentum_trigger_counts.get("evolution", 0)),
		"global_collection_count": int(state.global_gem_collections),
		"suppressed_duplicates": int(state.v2_momentum_suppressed_duplicates)
	}

func write_csv(path: String = DEFAULT_PATH) -> bool:
	if rows.is_empty():
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var headers := [
		"elapsed_seconds",
		"momentum_active",
		"momentum_tier",
		"remaining_seconds",
		"trigger_type",
		"trigger_count",
		"active_time_total",
		"score_base",
		"score_momentum_bonus",
		"weighted_multiplier",
		"kill_streak",
		"no_hit_seconds",
		"boss_kills",
		"evolutions",
		"global_collection_count",
		"suppressed_duplicates"
	]
	file.store_line(",".join(headers))
	for row in rows:
		var values: Array = []
		for key in headers:
			values.append(str(row.get(key, "")))
		file.store_line(",".join(values))
	return true
