extends RefCounted
class_name EnemyPositionRecoverySystem

func process(state, events: Array) -> int:
	var recovered: int = 0
	for enemy in state.enemies:
		if recover_enemy(state, enemy, events, "enemy_position_audit"):
			recovered += 1
	return recovered

func recover_enemy(state, enemy, events: Array, source: String = "enemy_position_recovery") -> bool:
	if enemy == null:
		return false
	if state.is_walkable_position(enemy.position, enemy.radius):
		return false
	var before: Vector2 = enemy.position
	var resolved: Vector2 = state.resolve_walkable_position(before, enemy.radius, state.player_position)
	if not state.is_walkable_position(resolved, enemy.radius):
		resolved = state.random_walkable_position(state.player_position, 120.0, 420.0)
	enemy.position = resolved
	enemy.charge_timer = 0.0
	enemy.telegraph_timer = 0.0
	enemy.recovery_timer = 0.12
	enemy.special_phase = ""
	enemy.ai_update_timer = 0.0
	enemy.ai_accumulator = 0.0
	state.enemy_position_recovery_count += 1
	events.append({"type": "enemy_position_recovered", "enemy": enemy.type, "source": source, "from": before, "to": resolved})
	return true
