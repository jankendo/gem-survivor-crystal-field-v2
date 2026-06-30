extends RefCounted
class_name EnemyRenderSnapshotSystem

const PhaseCacheScript = preload("res://scripts/systems/EnemyAnimationPhaseCache.gd")

var phase_cache = PhaseCacheScript.new()

func build_snapshot(enemies: Array, camera_position: Vector2, viewport_size: Vector2, elapsed_seconds: float, settings: Dictionary = {}) -> Dictionary:
	var started := Time.get_ticks_usec()
	var minimal := String(settings.get("enemy_visual_quality", "standard")) == "minimal" or bool(settings.get("minimal", false))
	var margin := 80.0
	var rect := Rect2(camera_position - viewport_size * 0.5 - Vector2(margin, margin), viewport_size + Vector2(margin * 2.0, margin * 2.0))
	var commands: Array = []
	var critical_missing := 0
	var omitted_offscreen := 0
	for enemy in enemies:
		if enemy == null:
			continue
		var pos: Vector2 = enemy.position
		var visible := rect.has_point(pos)
		var critical := bool(enemy.boss) or bool(enemy.elite)
		if not visible:
			omitted_offscreen += 1
			continue
		var normal_hp_enabled := bool(settings.get("normal_enemy_hp_bar", not minimal))
		var command := {
			"type": String(enemy.type),
			"position": pos,
			"radius": float(enemy.radius),
			"boss": bool(enemy.boss),
			"elite": bool(enemy.elite),
			"critical": critical,
			"hp_ratio": clampf(float(enemy.hp) / maxf(1.0, float(enemy.max_hp)), 0.0, 1.0),
			"phase": 0 if minimal and not critical else phase_cache.phase_for(String(enemy.type), elapsed_seconds, int(settings.get("enemy_animation_hz", 8)), 8),
			"draw_hp": critical or normal_hp_enabled,
			"draw_shadow": critical or bool(settings.get("normal_enemy_shadow", not minimal)),
			"draw_glow": critical or bool(settings.get("normal_enemy_glow", not minimal)),
			"outline_layers": 1 if minimal and not critical else 2
		}
		commands.append(command)
	return {
		"commands": commands,
		"visible_count": commands.size(),
		"omitted_offscreen": omitted_offscreen,
		"critical_missing": critical_missing,
		"snapshot_us": maxi(0, Time.get_ticks_usec() - started),
		"minimal": minimal
	}

func simulation_signature(enemies: Array) -> String:
	var parts: Array = []
	for enemy in enemies:
		if enemy == null:
			continue
		parts.append("%s:%d:%d:%d" % [String(enemy.type), int(enemy.position.x), int(enemy.position.y), int(enemy.hp)])
	return "|".join(parts)
