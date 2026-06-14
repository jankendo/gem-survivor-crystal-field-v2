extends RefCounted
class_name ShockStackSystem

func process(state, delta: float, events: Array = []) -> void:
	for enemy in state.enemies:
		if enemy.shock_stacks > 0 and enemy.shock_timer <= 0.0:
			enemy.shock_stacks = 0

func apply_lightning_hit(state, enemy, base_damage: int, hit_pos: Vector2, events: Array) -> void:
	if enemy == null or not state.enemies.has(enemy):
		return
	enemy.shock_stacks = clampi(enemy.shock_stacks + 1, 0, 3)
	enemy.shock_timer = 4.0
	var spark_damage = maxi(1, int(round(float(base_damage) * 0.16 * float(state.active_synergies.get("thunder_circuit", {}).get("effects", {}).get("shock_damage_mult", 1.0)))))
	enemy.hp -= spark_damage
	state.record_damage(spark_damage)
	state.add_hit_flash({"pos": hit_pos, "life": 0.22, "source": "thunder_chain", "shock": enemy.shock_stacks})
	events.append({"type": "shock_stack", "enemy": enemy.type, "stacks": enemy.shock_stacks, "pos": hit_pos})
	if enemy.shock_stacks >= 3:
		_trigger_shock_explosion(state, enemy.position, base_damage, events, enemy)
		enemy.shock_stacks = 0
		enemy.shock_timer = 0.0

func nearby_lightning_crystal_multiplier(state, pos: Vector2) -> float:
	for gimmick in state.field_gimmicks:
		if String(gimmick.get("id", "")) == "lightning_crystal" and not bool(gimmick.get("destroyed", false)):
			if (gimmick.get("position", Vector2.ZERO) as Vector2).distance_to(pos) <= 380.0:
				return 1.30
	return 1.0

func _trigger_shock_explosion(state, pos: Vector2, base_damage: int, events: Array, trigger_enemy = null) -> void:
	var radius = 96.0 * nearby_lightning_crystal_multiplier(state, pos)
	var damage = maxi(2, int(round(float(base_damage) * 0.55)))
	state.shock_explosions += 1
	state.add_hit_flash({"pos": pos, "life": 0.36, "source": "shock_stack", "radius": radius})
	for other in state.enemies.duplicate():
		if other == trigger_enemy:
			continue
		if other.position.distance_to(pos) <= radius + other.radius:
			other.hp -= damage
			state.record_damage(damage)
			state.add_hit_flash({"pos": other.position, "life": 0.18, "source": "thunder_chain", "shock": 3})
			if other.hp <= 0 and state.enemies.has(other):
				state.enemies.erase(other)
				state.kills += 1
				state.add_score(other.score, other.position)
	events.append({"type": "shock_explosion", "pos": pos, "radius": radius, "damage": damage})
