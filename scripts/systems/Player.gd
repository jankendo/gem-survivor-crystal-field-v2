extends RefCounted
class_name Player

var movement_resolver = preload("res://scripts/systems/PlayerMovementResolver.gd").new()

func input_direction() -> Vector2:
	var direction = Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	return direction.normalized()

func process_input_movement(state, delta: float) -> void:
	process_movement(state, input_direction(), delta)

func process_movement(state, direction: Vector2, delta: float) -> void:
	var normalized = direction.normalized() if direction.length() > 1.0 else direction
	state.player_velocity = normalized * state.get_move_speed()
	var result := movement_resolver.resolve(state, state.player_position, state.player_velocity, delta, 18.0)
	state.player_position = result.get("position", state.player_position)

func process_survival(state, delta: float, events: Array) -> void:
	state.invincible_timer = maxf(0.0, state.invincible_timer - delta)
	var regen_level = int(state.passives.get("regen", 0))
	if regen_level > 0 and state.hp < state.max_hp:
		state.regen_meter += delta
		if state.regen_meter >= 1.0:
			state.regen_meter -= 1.0
			var heal = mini(3, int(ceil(float(regen_level) * 0.6)))
			state.hp = mini(state.max_hp, state.hp + heal)
			state.add_floating_text("+%d HP" % heal, state.player_position + Vector2(0, -34), Color(0.42, 1.0, 0.52))
			events.append({"type": "player_heal", "amount": heal, "source": "regen", "hp": state.hp})
	for enemy in state.enemies:
		enemy.contact_cooldown = maxf(0.0, enemy.contact_cooldown - delta)
		if state.invincible_timer > 0.0 or enemy.contact_cooldown > 0.0:
			continue
		if enemy.position.distance_to(state.player_position) <= enemy.radius + 18.0:
			var damage = _reduced_damage(state, enemy.damage)
			damage = maxi(1, int(round(float(damage) * state.rune_contract_damage_taken_multiplier() * state.modifier_mult("damage_taken_mult", 1.0))))
			if state.active_synergies.has("guardian_field"):
				damage = maxi(1, int(round(float(damage) * 0.90)))
			if state.current_terrain_id == "crystal_corridor":
				damage = maxi(1, int(round(float(damage) * float(state.character_modifiers.get("corridor_defense_mult", 1.0)))))
			if state.boss_alive():
				damage = maxi(1, int(round(float(damage) * maxf(0.65, 1.0 - 0.05 * float(state.passives.get("boss_pressure", 0))))))
			state.hp -= damage
			state.record_damage_taken(damage)
			state.damage_flash_timer = 0.22
			state.invincible_timer = 0.55
			enemy.contact_cooldown = 0.70
			events.append({"type": "player_damage", "damage": damage, "hp": state.hp, "enemy": enemy.type})
			if state.hp <= 0:
				if _try_revival(state, events):
					break
				state.game_over = true
				state.game_over_reason = "%sに囲まれました" % enemy.name_ja
			break

func _reduced_damage(state, base_damage: int) -> int:
	var armor_level = int(state.passives.get("armor", 0))
	var reduced = int(round(float(base_damage) * maxf(0.58, 1.0 - 0.07 * float(armor_level))))
	return maxi(1, reduced - armor_level)

func _try_revival(state, events: Array) -> bool:
	if state.revival_used or int(state.passives.get("revival", 0)) <= 0:
		return false
	state.revival_used = true
	state.hp = maxi(1, int(round(float(state.max_hp) * 0.5)))
	state.invincible_timer = 2.0
	state.damage_flash_timer = 0.0
	state.add_floating_text("復活", state.player_position + Vector2(0, -42), Color(1.0, 0.92, 0.44))
	events.append({"type": "revival", "hp": state.hp})
	return true
