extends RefCounted
class_name BossAlertSystem

var warning_timer := 0.0
var warning_text := ""
var planned_position := Vector2.ZERO

func ingest(event: Dictionary) -> void:
	match String(event.get("type", "")):
		"boss_warning":
			warning_timer = float(event.get("duration", 5.0))
			warning_text = String(event.get("message", "ボス接近"))
			planned_position = event.get("pos", Vector2.ZERO)
		"boss_spawn":
			warning_timer = 0.0
			warning_text = ""

func tick(delta: float) -> void:
	warning_timer = maxf(0.0, warning_timer - delta)

func active_boss_snapshot(state) -> Dictionary:
	var boss = state.active_boss()
	if boss == null:
		return {}
	return {
		"name": boss.name_ja,
		"hp": boss.hp,
		"max_hp": boss.max_hp,
		"ratio": float(boss.hp) / float(maxi(1, boss.max_hp)),
		"position": boss.position
	}
