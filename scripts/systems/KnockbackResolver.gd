extends RefCounted
class_name KnockbackResolver

var movement_resolver = preload("res://scripts/systems/PlayerMovementResolver.gd").new()

func apply(state, enemy, direction: Vector2, distance: float, events: Array, source: String = "knockback") -> Dictionary:
	if enemy == null or distance <= 0.0:
		return {"moved": false, "blocked": false, "position": Vector2.ZERO}
	var actual_direction: Vector2 = direction.normalized()
	if actual_direction.length_squared() <= 0.0001:
		actual_direction = Vector2.RIGHT
	return move_by(state, enemy, actual_direction * distance, events, source)

func move_by(state, enemy, motion: Vector2, events: Array, source: String = "knockback") -> Dictionary:
	if enemy == null or motion.length_squared() <= 0.0001:
		return {"moved": false, "blocked": false, "position": enemy.position if enemy != null else Vector2.ZERO}
	var origin: Vector2 = enemy.position
	var movement: Dictionary = movement_resolver.resolve(state, origin, motion, 1.0, enemy.radius)
	var requested: Vector2 = origin + motion
	var resolved: Vector2 = movement.get("position", origin)
	var blocked: bool = bool(movement.get("collided", false))
	if not state.is_walkable_position(resolved, enemy.radius):
		var recovered: Vector2 = state.resolve_walkable_position(resolved, enemy.radius, origin)
		blocked = true
		if not state.is_walkable_position(recovered, enemy.radius):
			recovered = state.random_walkable_position(state.player_position, 96.0, 360.0)
		resolved = recovered
		events.append({"type": "enemy_position_recovered", "enemy": enemy.type, "source": source, "from": requested, "to": resolved})
	enemy.position = resolved
	enemy.recovery_timer = maxf(enemy.recovery_timer, 0.06)
	if blocked:
		state.knockback_blocked_count += 1
		events.append({"type": "knockback_blocked", "enemy": enemy.type, "source": source, "from": origin, "requested": requested, "to": resolved})
	return {"moved": resolved.distance_to(origin) > 0.01, "blocked": blocked, "position": resolved}
