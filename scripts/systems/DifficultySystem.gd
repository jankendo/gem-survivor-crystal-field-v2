extends RefCounted
class_name DifficultySystem

func snapshot(state) -> Dictionary:
	var seconds = float(state.elapsed_seconds)
	var minutes = seconds / 60.0
	var row = _curve_row(state, minutes)
	var tier = _tier_for_seconds(state, seconds)
	var factor = (float(row.get("hp", 1.0)) + float(row.get("damage", 1.0)) + float(row.get("spawn", 1.0))) / 3.0
	return {
		"elapsed_minutes": minutes,
		"difficulty_tier": tier,
		"difficulty_factor": factor,
		"enemy_hp_multiplier": float(row.get("hp", 1.0)),
		"enemy_damage_multiplier": float(row.get("damage", 1.0)),
		"enemy_speed_multiplier": float(row.get("speed", 1.0)),
		"enemy_spawn_multiplier": float(row.get("spawn", 1.0)),
		"enemy_special_rate": float(row.get("special", 0.0)),
		"enemy_projectile_rate": float(row.get("projectile", 0.0)),
		"elite_rate": float(row.get("elite", 0.02)),
		"boss_hp_multiplier": float(row.get("boss_hp", 1.0)),
		"crystal_hp_multiplier": float(row.get("crystal_hp", 1.0)),
		"gem_value_multiplier": float(row.get("gem_value", 1.0))
	}

func value(state, key: String, fallback: float = 1.0) -> float:
	return float(snapshot(state).get(key, fallback))

func tier(state) -> int:
	return int(snapshot(state).get("difficulty_tier", 1))

func _tier_for_seconds(state, seconds: float) -> int:
	for row in state.difficulty_curve.get("tiers", []):
		if seconds >= float(row.get("from", 0.0)) and seconds < float(row.get("to", 99999.0)):
			return int(row.get("tier", 1))
	return 7

func _curve_row(state, minutes: float) -> Dictionary:
	var curve: Array = state.difficulty_curve.get("curve", [])
	if curve.is_empty():
		return {}
	var previous: Dictionary = curve[0]
	for i in range(1, curve.size()):
		var next: Dictionary = curve[i]
		var prev_min = float(previous.get("minute", 0.0))
		var next_min = float(next.get("minute", prev_min))
		if minutes <= next_min:
			var t = 0.0 if next_min <= prev_min else clampf((minutes - prev_min) / (next_min - prev_min), 0.0, 1.0)
			return _lerp_row(previous, next, t)
		previous = next
	var overflow = maxf(0.0, minutes - float(previous.get("minute", minutes)))
	var result = previous.duplicate(true)
	result["hp"] = float(result.get("hp", 1.0)) + overflow * 2.0
	result["damage"] = float(result.get("damage", 1.0)) + overflow * 0.24
	result["speed"] = float(result.get("speed", 1.0)) + overflow * 0.035
	result["spawn"] = float(result.get("spawn", 1.0)) + overflow * 0.18
	result["projectile"] = minf(1.0, float(result.get("projectile", 0.0)) + overflow * 0.035)
	result["special"] = minf(0.92, float(result.get("special", 0.0)) + overflow * 0.025)
	result["elite"] = minf(0.75, float(result.get("elite", 0.0)) + overflow * 0.018)
	result["boss_hp"] = float(result.get("boss_hp", 1.0)) + overflow * 1.8
	result["crystal_hp"] = float(result.get("crystal_hp", 1.0)) + overflow * 2.4
	result["gem_value"] = float(result.get("gem_value", 1.0)) + overflow * 0.025
	return result

func _lerp_row(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var result = b.duplicate(true)
	for key in ["hp", "damage", "speed", "spawn", "special", "projectile", "elite", "boss_hp", "crystal_hp", "gem_value"]:
		result[key] = lerpf(float(a.get(key, b.get(key, 1.0))), float(b.get(key, a.get(key, 1.0))), t)
	return result
