extends RefCounted
class_name EnemyProjectilePolicySystem

const ALLOWED_CLASSES := ["boss", "elite", "gimmick", "event"]

func source_class(enemy) -> String:
	if enemy == null:
		return ""
	if bool(enemy.boss):
		return "boss"
	if bool(enemy.elite):
		return "elite"
	var data: Dictionary = enemy.data
	if bool(data.get("gimmick", false)):
		return "gimmick"
	if bool(data.get("event_enemy", false)):
		return "event"
	return "trash"

func can_emit_projectile(enemy) -> bool:
	return ALLOWED_CLASSES.has(source_class(enemy))

func requires_warning(enemy) -> bool:
	return can_emit_projectile(enemy)
