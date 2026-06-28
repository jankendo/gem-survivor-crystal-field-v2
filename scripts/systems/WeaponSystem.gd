extends RefCounted
class_name WeaponSystem

const ProjectileScript = preload("res://scripts/core/Projectile.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")

var exp_system = preload("res://scripts/systems/ExpSystem.gd").new()
var chest_system = preload("res://scripts/systems/ChestSystem.gd").new()
var field_system = preload("res://scripts/systems/CrystalFieldSystem.gd").new()
var rune_contract_system = preload("res://scripts/systems/RuneContractSystem.gd").new()
var shock_stack_system = preload("res://scripts/systems/ShockStackSystem.gd").new()
var melee_rush_system = preload("res://scripts/systems/MeleeRushSystem.gd").new()
var enemy_projectile_policy = preload("res://scripts/systems/EnemyProjectilePolicySystem.gd").new()
var field_gimmick_system = preload("res://scripts/systems/FieldGimmickSystem.gd").new()
var knockback_resolver = preload("res://scripts/systems/KnockbackResolver.gd").new()
var enemy_grid = preload("res://scripts/performance/SpatialHashGrid2D.gd").new(160.0)

func process(state, delta: float, events: Array) -> void:
	if state.game_over or state.level_up_pending or state.chest_pending:
		return
	var event_start = events.size()
	enemy_grid.rebuild(state.enemies)
	for enemy in state.enemies:
		enemy.tick_cooldowns(delta)
	_update_cooldowns(state, delta)
	_process_magic_bolt(state, events)
	_process_ice_orbit(state, delta, events)
	_process_thunder_chain(state, events)
	_process_bomb_seed(state, events)
	_process_blade_fan(state, events)
	_process_laser_lance(state, events)
	_process_poison_mist(state, events)
	_process_drone_bit(state, events)
	_process_crystal_mine(state, events)
	_process_black_hole(state, events)
	_process_rune_gate(state, events)
	_process_comet_staff(state, events)
	_process_soul_scythe(state, events)
	_process_mirror_shard(state, events)
	_process_sonic_wave(state, events)
	_process_gem_turret(state, events)
	_process_expansion_weapons(state, events)
	_emit_attack_visuals(state, events, event_start)
	_process_projectiles(state, delta, events)
	_process_bombs(state, delta, events)
	state.trim_runtime_arrays()

func _emit_attack_visuals(state, events: Array, event_start: int) -> void:
	for index in range(event_start, events.size()):
		var event: Dictionary = events[index]
		if String(event.get("type", "")) != "attack":
			continue
		var weapon_id = String(event.get("weapon", ""))
		if weapon_id == "" or state.weapon_effect(weapon_id).is_empty():
			continue
		var target = _nearest_damageable(state, state.player_position, float(state.weapon_defs.get(weapon_id, {}).get("range", 420.0)))
		var pos = target.position if target != null else state.player_position
		var density_mult = 0.72 if state.effect_density == "low" else (1.28 if state.effect_density == "high" else 1.0)
		state.add_hit_flash({
			"pos": pos,
			"life": 0.24 * density_mult,
			"source": weapon_id,
			"radius": (24.0 + float(state.weapons.get(weapon_id, 1)) * 2.0) * density_mult,
			"evolved": state.is_weapon_evolved(weapon_id)
		})

func _update_cooldowns(state, delta: float) -> void:
	for key in state.weapon_cooldowns.keys():
		state.weapon_cooldowns[key] = maxf(0.0, float(state.weapon_cooldowns[key]) - delta)

func _projectile_bonus(state) -> int:
	return int(state.passives.get("projectile_count", 0))

func _process_magic_bolt(state, events: Array) -> void:
	if not state.weapons.has("magic_bolt") or float(state.weapon_cooldowns.get("magic_bolt", 0.0)) > 0.0:
		return
	var target = _nearest_damageable(state, state.player_position, 900.0)
	if target == null:
		return
	var level = int(state.weapons.get("magic_bolt", 1))
	var evolved = state.is_weapon_evolved("magic_bolt")
	var count = 1 + _projectile_bonus(state)
	if level >= 3:
		count += 1
	if level >= 6:
		count += 1
	if evolved:
		count += 2
	if state.has_overclock("magic_bolt", "meteor_swarm"):
		count += 3
	var damage = int(round(float(2 + level) * state.get_damage_multiplier_for_weapon("magic_bolt")))
	if state.has_overclock("magic_bolt", "meteor_swarm"):
		damage = maxi(1, int(round(float(damage) * 0.80)))
	var pierce = 0
	if level >= 5:
		pierce += 1
	if evolved:
		pierce += 2
	var splash = 38.0 * state.get_area_multiplier_for_weapon("magic_bolt") if level >= 7 else 0.0
	if evolved:
		damage += 4
		splash = 68.0 * state.get_area_multiplier_for_weapon("magic_bolt")
	if state.has_overclock("magic_bolt", "supernova"):
		splash *= 1.8
	var target_pos: Vector2 = target.position
	var base_dir = (target_pos - state.player_position).normalized()
	for i in range(count):
		var spread = (float(i) - float(count - 1) * 0.5) * 0.12
		var direction = base_dir.rotated(spread)
		var speed = 560.0 + float(level) * 20.0
		var projectile = _projectile(state, "magic_bolt", state.player_position, direction * speed, damage, pierce, 2.2, 8.0, splash, evolved)
		state.projectiles.append(projectile)
	events.append({"type": "attack", "weapon": "magic_bolt", "count": count})
	var interval = (0.62 if level < 4 else 0.48) * state.get_cooldown_multiplier_for_weapon("magic_bolt")
	if evolved:
		interval *= 0.70
	if state.has_overclock("magic_bolt", "supernova"):
		interval *= 1.15
	state.weapon_cooldowns["magic_bolt"] = interval

func _process_ice_orbit(state, delta: float, events: Array) -> void:
	if not state.weapons.has("ice_orbit"):
		return
	var level = int(state.weapons.get("ice_orbit", 1))
	var evolved = state.is_weapon_evolved("ice_orbit")
	var orbit_speed = (2.6 + float(level) * 0.08 + (0.55 if evolved else 0.0)) * (0.80 if state.has_overclock("ice_orbit", "glacier_expand") else 1.0)
	state.orbit_angle += delta * orbit_speed
	var orbit_count = 1 + int(floor(float(level) / 3.0)) + (2 if evolved else 0)
	var radius = (78.0 + float(level) * 8.0) * state.get_area_multiplier_for_weapon("ice_orbit") * (1.28 if evolved else 1.0) * (1.60 if state.has_overclock("ice_orbit", "glacier_expand") else 1.0)
	var damage = int(round(float(1 + int(floor(float(level) / 2.0))) * 0.82 * state.get_damage_multiplier_for_weapon("ice_orbit")))
	if evolved:
		damage += 3
	for i in range(orbit_count):
		var angle = state.orbit_angle + TAU * float(i) / float(orbit_count)
		var orb_pos = state.player_position + Vector2(cos(angle), sin(angle)) * radius
		for enemy in enemy_grid.query_radius(orb_pos, 96.0):
			if enemy.position.distance_to(orb_pos) <= enemy.radius + 19.0 and enemy.can_take_periodic_hit("ice_orbit", 0.34 if not evolved else 0.25):
				enemy.slow_timer = maxf(enemy.slow_timer, 1.0 + float(level) * 0.12)
				var actual_damage = damage * (2 if state.has_overclock("ice_orbit", "absolute_zero") and enemy.slow_timer > 0.0 else 1)
				_damage_enemy(state, enemy, actual_damage, events, "ice_orbit", orb_pos)
		field_system.damage_walls_in_radius(state, orb_pos, 20.0, damage, events, "ice_orbit")
	for enemy in enemy_grid.query_radius(state.player_position, radius + 64.0):
		var ring_distance = abs(enemy.position.distance_to(state.player_position) - radius)
		if ring_distance <= enemy.radius + 18.0 and enemy.can_take_periodic_hit("ice_orbit_ring", 0.38):
			enemy.slow_timer = maxf(enemy.slow_timer, 1.0 + float(level) * 0.12)
			var actual_damage = damage * (2 if state.has_overclock("ice_orbit", "absolute_zero") and enemy.slow_timer > 0.0 else 1)
			_damage_enemy(state, enemy, actual_damage, events, "ice_orbit", enemy.position)

func _process_thunder_chain(state, events: Array) -> void:
	if not state.weapons.has("thunder_chain") or float(state.weapon_cooldowns.get("thunder_chain", 0.0)) > 0.0:
		return
	var level = int(state.weapons.get("thunder_chain", 1))
	var evolved = state.is_weapon_evolved("thunder_chain")
	var current = _nearest_enemy(state, state.player_position, 540.0 * state.get_area_multiplier_for_weapon("thunder_chain"))
	if current == null:
		return
	var hit: Array = []
	var chains = 1 + int(floor(float(level) / 2.0)) + _projectile_bonus(state) + (4 if evolved else 0) + (5 if state.has_overclock("thunder_chain", "judgement_amp") else 0)
	var damage = int(round(float(3 + level) * state.get_damage_multiplier_for_weapon("thunder_chain")))
	if evolved:
		damage += 5
	var origin = state.player_position
	for i in range(chains):
		var target = _nearest_enemy_excluding(state, origin, 330.0 * state.get_area_multiplier_for_weapon("thunder_chain"), hit)
		if target == null:
			break
		hit.append(target)
		state.add_effect_line({"start": origin, "end": target.position, "life": 0.18 + float(i) * 0.025, "source": "thunder_chain", "index": i, "evolved": evolved})
		_damage_enemy(state, target, damage, events, "thunder_chain", target.position)
		field_system.damage_walls_in_radius(state, target.position, 34.0 * state.get_area_multiplier_for_weapon("thunder_chain"), max(1, int(damage * 0.45)), events, "thunder_chain")
		origin = target.position
	events.append({"type": "attack", "weapon": "thunder_chain", "count": hit.size()})
	var interval = maxf(0.36, (1.25 - float(level) * 0.04) * state.get_cooldown_multiplier_for_weapon("thunder_chain"))
	if evolved:
		interval *= 0.68
	if state.has_overclock("thunder_chain", "judgement_amp"):
		interval *= 1.10
	if state.has_overclock("thunder_chain", "thunder_field"):
		_explode(state, state.player_position, 115.0 * state.get_area_multiplier_for_weapon("thunder_chain"), max(2, int(damage * 0.75)), events, "thunder_field")
	state.weapon_cooldowns["thunder_chain"] = interval

func _process_bomb_seed(state, events: Array) -> void:
	if not state.weapons.has("bomb_seed") or float(state.weapon_cooldowns.get("bomb_seed", 0.0)) > 0.0:
		return
	var level = int(state.weapons.get("bomb_seed", 1))
	var evolved = state.is_weapon_evolved("bomb_seed")
	var count = 1 + int(floor(float(level) / 4.0)) + _projectile_bonus(state) + (3 if evolved else 0)
	var target = _nearest_enemy(state, state.player_position, 420.0)
	for i in range(count):
		var angle = state.rng.range_float(0.0, TAU)
		var offset = Vector2(cos(angle), sin(angle)) * state.rng.range_float(40.0, 170.0)
		if target != null:
			offset = (target.position - state.player_position) + Vector2(cos(angle), sin(angle)) * state.rng.range_float(0.0, 34.0)
		var damage = int(round(float(5 + level * 2) * state.get_damage_multiplier_for_weapon("bomb_seed")))
		var radius = (84.0 + level * 8.0) * state.get_area_multiplier_for_weapon("bomb_seed") * (1.35 if evolved else 1.0)
		var bomb = _projectile(state, "bomb_seed", state.player_position + offset, Vector2.ZERO, damage, 0, 0.78 if not evolved else 0.52, 12.0, radius, evolved)
		state.bombs.append(bomb)
	events.append({"type": "attack", "weapon": "bomb_seed", "count": count})
	state.weapon_cooldowns["bomb_seed"] = maxf(0.75, (2.15 - float(level) * 0.08) * state.get_cooldown_multiplier_for_weapon("bomb_seed") * (0.78 if evolved else 1.0))

func _process_blade_fan(state, events: Array) -> void:
	if not state.weapons.has("blade_fan") or float(state.weapon_cooldowns.get("blade_fan", 0.0)) > 0.0:
		return
	var level = int(state.weapons.get("blade_fan", 1))
	var evolved = state.is_weapon_evolved("blade_fan")
	var target = _nearest_enemy(state, state.player_position, 680.0)
	if target == null:
		return
	var count = 3 + int(floor(float(level) / 3.0)) + _projectile_bonus(state) + (3 if evolved else 0)
	var base_dir = (target.position - state.player_position).normalized()
	if evolved and state.player_velocity.length() > 10.0:
		base_dir = state.player_velocity.normalized()
	var damage = int(round(float(3 + level) * state.get_damage_multiplier_for_weapon("blade_fan")))
	for i in range(count):
		var spread = (float(i) - float(count - 1) * 0.5) * (0.18 if not evolved else 0.14)
		var direction = base_dir.rotated(spread)
		var projectile = _projectile(state, "blade_fan", state.player_position + direction * 18.0, direction * (610.0 + level * 16.0 + (160.0 if evolved else 0.0)), damage, 1 + (2 if evolved else 0), 1.15, 15.0 if evolved else 12.0, 0.0, evolved)
		state.projectiles.append(projectile)
	events.append({"type": "attack", "weapon": "blade_fan", "count": count})
	state.weapon_cooldowns["blade_fan"] = maxf(0.34, (0.86 - float(level) * 0.025) * state.get_cooldown_multiplier_for_weapon("blade_fan") * (0.75 if evolved else 1.0))

func _process_laser_lance(state, events: Array) -> void:
	if not state.weapons.has("laser_lance") or float(state.weapon_cooldowns.get("laser_lance", 0.0)) > 0.0:
		return
	var level = int(state.weapons.get("laser_lance", 1))
	var evolved = state.is_weapon_evolved("laser_lance")
	var target = _nearest_damageable(state, state.player_position, 980.0)
	if target == null:
		return
	var direction = (target.position - state.player_position).normalized()
	var range = (760.0 + level * 28.0) * state.get_area_multiplier_for_weapon("laser_lance") * (1.25 if evolved else 1.0)
	var width = 22.0 + level * 1.4 + (18.0 if evolved else 0.0)
	var start = state.player_position
	var end = start + direction * range
	var damage = int(round(float(8 + level * 2) * state.get_damage_multiplier_for_weapon("laser_lance")))
	if evolved:
		damage = int(round(float(damage) * 1.35))
	var beam_center: Vector2 = start + direction * range * 0.5
	for enemy in enemy_grid.query_radius(beam_center, range * 0.5 + width + 64.0):
		if _distance_to_segment(enemy.position, start, end) <= enemy.radius + width:
			_damage_enemy(state, enemy, damage, events, "laser_lance", enemy.position)
	field_system.damage_walls_in_radius(state, beam_center, range * 0.5 + width, damage, events, "laser_lance")
	field_gimmick_system.damage_gimmicks_in_radius(state, beam_center, range * 0.5 + width, damage, events, "laser_lance")
	state.add_effect_line({"start": start, "end": end, "life": 0.16, "source": "laser_lance", "evolved": evolved})
	state.add_hit_flash({"pos": end, "life": 0.20, "source": "laser_lance"})
	events.append({"type": "attack", "weapon": "laser_lance", "count": 1, "start": start, "end": end})
	state.weapon_cooldowns["laser_lance"] = maxf(0.55, (1.35 - float(level) * 0.045) * state.get_cooldown_multiplier_for_weapon("laser_lance") * (0.72 if evolved else 1.0))

func _process_poison_mist(state, events: Array) -> void:
	if not state.weapons.has("poison_mist") or float(state.weapon_cooldowns.get("poison_mist", 0.0)) > 0.0:
		return
	var level = int(state.weapons.get("poison_mist", 1))
	var evolved = state.is_weapon_evolved("poison_mist")
	var radius = (130.0 + level * 18.0) * state.get_area_multiplier_for_weapon("poison_mist") * (1.45 if evolved else 1.0)
	var damage = int(round(float(3 + level) * state.get_damage_multiplier_for_weapon("poison_mist") * (1.0 + 0.09 * float(state.passives.get("curse", 0)))))
	if evolved:
		damage += 4
	for enemy in enemy_grid.query_radius(state.player_position, radius + 64.0):
		if enemy.position.distance_to(state.player_position) <= radius + enemy.radius and enemy.can_take_periodic_hit("poison_mist", 0.42 if not evolved else 0.30):
			_damage_enemy(state, enemy, damage, events, "poison_mist", enemy.position)
	field_system.damage_walls_in_radius(state, state.player_position, radius, max(1, int(damage * 0.55)), events, "poison_mist")
	events.append({"type": "attack", "weapon": "poison_mist", "count": 1, "radius": radius})
	state.weapon_cooldowns["poison_mist"] = (0.56 if not evolved else 0.40) * state.get_cooldown_multiplier_for_weapon("poison_mist")

func _process_drone_bit(state, events: Array) -> void:
	if not state.weapons.has("drone_bit") or float(state.weapon_cooldowns.get("drone_bit", 0.0)) > 0.0:
		return
	var level = int(state.weapons.get("drone_bit", 1))
	var evolved = state.is_weapon_evolved("drone_bit")
	var bit_count = 1 + int(floor(float(level) / 3.0)) + int(floor(float(state.passives.get("luck", 0)) / 3.0)) + (2 if evolved else 0)
	var fired = 0
	for i in range(bit_count):
		var angle = state.orbit_angle + TAU * float(i) / float(bit_count)
		var origin = state.player_position + Vector2(cos(angle), sin(angle)) * (68.0 + level * 3.0)
		var target = _nearest_enemy(state, origin, 720.0)
		if target == null:
			continue
		var direction = (target.position - origin).normalized()
		var damage = int(round(float(3 + level) * state.get_damage_multiplier_for_weapon("drone_bit")))
		var projectile = _projectile(state, "drone_bit", origin, direction * 650.0, damage, 0 + (1 if evolved else 0), 1.4, 7.5, 0.0, evolved)
		state.projectiles.append(projectile)
		fired += 1
	if fired > 0:
		events.append({"type": "attack", "weapon": "drone_bit", "count": fired})
	state.weapon_cooldowns["drone_bit"] = maxf(0.42, (0.98 - float(level) * 0.035) * state.get_cooldown_multiplier_for_weapon("drone_bit") * (0.72 if evolved else 1.0))

func _process_crystal_mine(state, events: Array) -> void:
	if not state.weapons.has("crystal_mine") or float(state.weapon_cooldowns.get("crystal_mine", 0.0)) > 0.0:
		return
	var level = int(state.weapons.get("crystal_mine", 1))
	var count = 1 + int(floor(float(level) / 4.0)) + _projectile_bonus(state)
	var damage = int(round(float(7 + level * 2) * state.get_damage_multiplier_for_weapon("crystal_mine")))
	for i in range(count):
		var angle = state.rng.range_float(0.0, TAU)
		var offset = Vector2(cos(angle), sin(angle)) * state.rng.range_float(26.0, 120.0)
		var mine = _projectile(state, "crystal_mine", state.player_position + offset, Vector2.ZERO, damage, 0, 1.15, 10.0, (92.0 + level * 9.0) * state.get_area_multiplier_for_weapon("crystal_mine"), false)
		state.bombs.append(mine)
	events.append({"type": "attack", "weapon": "crystal_mine", "count": count})
	state.weapon_cooldowns["crystal_mine"] = maxf(0.78, (1.85 - float(level) * 0.06) * state.get_cooldown_multiplier_for_weapon("crystal_mine"))

func _process_black_hole(state, events: Array) -> void:
	if not state.weapons.has("black_hole") or float(state.weapon_cooldowns.get("black_hole", 0.0)) > 0.0:
		return
	var level = int(state.weapons.get("black_hole", 1))
	var target = _nearest_enemy(state, state.player_position, 680.0)
	if target == null:
		return
	var evolved = state.is_weapon_evolved("black_hole")
	var damage = int(round(float(2 + level) * state.get_damage_multiplier_for_weapon("black_hole")))
	var radius = (95.0 + level * 12.0) * state.get_area_multiplier_for_weapon("black_hole") * (1.25 if evolved else 1.0)
	var projectile = _projectile(state, "black_hole", target.position, Vector2.ZERO, damage, 99, 2.2 + float(level) * 0.06, 24.0, radius, evolved)
	state.projectiles.append(projectile)
	events.append({"type": "attack", "weapon": "black_hole", "count": 1})
	state.weapon_cooldowns["black_hole"] = maxf(1.05, (3.2 - float(level) * 0.11) * state.get_cooldown_multiplier_for_weapon("black_hole") * (0.76 if evolved else 1.0))

func _process_rune_gate(state, events: Array) -> void:
	if not state.weapons.has("rune_gate") or float(state.weapon_cooldowns.get("rune_gate", 0.0)) > 0.0:
		return
	var level = int(state.weapons.get("rune_gate", 1))
	var evolved = state.is_weapon_evolved("rune_gate")
	var count = 1 + int(floor(float(level) / 4.0)) + (2 if evolved else 0)
	var target = _nearest_enemy(state, state.player_position, 520.0)
	for i in range(count):
		var pos = state.player_position + Vector2(170.0 + i * 45.0, 0).rotated(state.rng.range_float(0.0, TAU))
		if target != null:
			pos = target.position + Vector2(60.0, 0).rotated(state.rng.range_float(0.0, TAU))
		var radius = (70.0 + level * 8.0) * state.get_area_multiplier_for_weapon("rune_gate") * (1.35 if evolved else 1.0) * (1.35 if state.has_overclock("rune_gate", "wide_gate") else 1.0)
		var damage = int(round(float(4 + level) * state.get_damage_multiplier_for_weapon("rune_gate") * (1.4 if state.has_overclock("rune_gate", "hot_rune") else 1.0)))
		state.projectiles.append(_projectile(state, "rune_gate", pos, Vector2.ZERO, damage, 99, 3.0 + float(level) * 0.08, 22.0, radius, evolved))
	events.append({"type": "attack", "weapon": "rune_gate", "count": count})
	state.weapon_cooldowns["rune_gate"] = maxf(1.05, (2.45 - float(level) * 0.08) * state.get_cooldown_multiplier_for_weapon("rune_gate") * (0.78 if evolved else 1.0))

func _process_comet_staff(state, events: Array) -> void:
	if not state.weapons.has("comet_staff") or float(state.weapon_cooldowns.get("comet_staff", 0.0)) > 0.0:
		return
	var level = int(state.weapons.get("comet_staff", 1))
	var evolved = state.is_weapon_evolved("comet_staff")
	var count = 1 + int(floor(float(level) / 3.0)) + (3 if evolved else 0) + (1 if state.has_overclock("comet_staff", "double_impact") else 0)
	for i in range(count):
		var target = _nearest_enemy(state, state.player_position, 760.0)
		var pos = state.player_position + Vector2(state.rng.range_float(-300.0, 300.0), state.rng.range_float(-240.0, 240.0))
		if target != null:
			pos = target.position + Vector2(state.rng.range_float(-70.0, 70.0), state.rng.range_float(-70.0, 70.0))
		var damage = int(round(float(8 + level * 2) * state.get_damage_multiplier_for_weapon("comet_staff")))
		var radius = (86.0 + level * 9.0) * state.get_area_multiplier_for_weapon("comet_staff") * (1.25 if evolved else 1.0)
		state.bombs.append(_projectile(state, "comet_staff", pos, Vector2.ZERO, damage, 0, 0.62, 18.0, radius, evolved))
	events.append({"type": "attack", "weapon": "comet_staff", "count": count})
	state.weapon_cooldowns["comet_staff"] = maxf(1.1, (3.0 - float(level) * 0.10) * state.get_cooldown_multiplier_for_weapon("comet_staff") * (0.82 if evolved else 1.0))

func _process_soul_scythe(state, events: Array) -> void:
	if not state.weapons.has("soul_scythe") or float(state.weapon_cooldowns.get("soul_scythe", 0.0)) > 0.0:
		return
	var level = int(state.weapons.get("soul_scythe", 1))
	var evolved = state.is_weapon_evolved("soul_scythe")
	var radius = (110.0 + level * 12.0) * state.get_area_multiplier_for_weapon("soul_scythe") * (1.45 if evolved or state.has_overclock("soul_scythe", "wide_reap") else 1.0)
	var damage = int(round(float(5 + level * 2) * state.get_damage_multiplier_for_weapon("soul_scythe")))
	var direction = state.player_velocity.normalized() if state.player_velocity.length() > 8.0 else Vector2.RIGHT
	var hit_count = 0
	for enemy in enemy_grid.query_radius(state.player_position, radius + 64.0):
		var to_enemy = enemy.position - state.player_position
		if to_enemy.length() <= radius + enemy.radius and direction.dot(to_enemy.normalized()) > -0.25:
			_damage_enemy(state, enemy, damage, events, "soul_scythe", enemy.position)
			hit_count += 1
	field_system.damage_walls_in_radius(state, state.player_position + direction * radius * 0.45, radius * 0.55, damage, events, "soul_scythe")
	field_gimmick_system.damage_gimmicks_in_radius(state, state.player_position + direction * radius * 0.45, radius * 0.55, damage, events, "soul_scythe")
	state.add_hit_flash({"pos": state.player_position + direction * radius * 0.50, "life": 0.20, "source": "soul_scythe", "radius": radius, "direction": direction})
	events.append({"type": "attack", "weapon": "soul_scythe", "count": hit_count, "radius": radius})
	state.weapon_cooldowns["soul_scythe"] = maxf(0.62, (1.45 - float(level) * 0.045) * state.get_cooldown_multiplier_for_weapon("soul_scythe") * (0.78 if evolved else 1.0))

func _process_mirror_shard(state, events: Array) -> void:
	if not state.weapons.has("mirror_shard") or float(state.weapon_cooldowns.get("mirror_shard", 0.0)) > 0.0:
		return
	var level = int(state.weapons.get("mirror_shard", 1))
	var evolved = state.is_weapon_evolved("mirror_shard")
	var count = 1 + int(floor(float(level) / 3.0)) + _projectile_bonus(state) + (2 if evolved else 0)
	var target = _nearest_enemy(state, state.player_position, 800.0)
	var base_dir = Vector2.RIGHT.rotated(state.rng.range_float(0.0, TAU))
	if target != null:
		base_dir = (target.position - state.player_position).normalized()
	for i in range(count):
		var dir = base_dir.rotated((float(i) - float(count - 1) * 0.5) * 0.18)
		var damage = int(round(float(4 + level) * state.get_damage_multiplier_for_weapon("mirror_shard") * (1.35 if state.has_overclock("mirror_shard", "sharp_mirror") else 1.0)))
		var p = _projectile(state, "mirror_shard", state.player_position + dir * 20.0, dir * (540.0 + level * 18.0), damage, 1 + (2 if evolved else 0), 2.6, 9.0, 0.0, evolved)
		p.bounce_left = 2 + int(floor(float(level) / 4.0)) + (2 if evolved else 0)
		state.projectiles.append(p)
	events.append({"type": "attack", "weapon": "mirror_shard", "count": count})
	state.weapon_cooldowns["mirror_shard"] = maxf(0.55, (1.05 - float(level) * 0.035) * state.get_cooldown_multiplier_for_weapon("mirror_shard") * (0.76 if evolved else 1.0))

func _process_sonic_wave(state, events: Array) -> void:
	if not state.weapons.has("sonic_wave") or float(state.weapon_cooldowns.get("sonic_wave", 0.0)) > 0.0:
		return
	var level = int(state.weapons.get("sonic_wave", 1))
	var evolved = state.is_weapon_evolved("sonic_wave")
	var radius = (120.0 + level * 16.0) * state.get_area_multiplier_for_weapon("sonic_wave") * (1.35 if evolved else 1.0)
	var damage = int(round(float(3 + level) * state.get_damage_multiplier_for_weapon("sonic_wave")))
	var hit_count = 0
	for enemy in enemy_grid.query_radius(state.player_position, radius + 64.0):
		var distance = enemy.position.distance_to(state.player_position)
		if distance <= radius + enemy.radius:
			var direction = (enemy.position - state.player_position).normalized()
			knockback_resolver.apply(state, enemy, direction, (80.0 + level * 8.0) * (1.20 if state.active_synergies.has("guardian_field") else 1.0), events, "sonic_wave")
			_damage_enemy(state, enemy, damage, events, "sonic_wave", enemy.position)
			hit_count += 1
	field_system.damage_walls_in_radius(state, state.player_position, radius, max(1, int(damage * 0.45)), events, "sonic_wave")
	field_gimmick_system.damage_gimmicks_in_radius(state, state.player_position, radius, max(1, int(damage * 0.45)), events, "sonic_wave")
	state.add_hit_flash({"pos": state.player_position, "life": 0.22, "source": "sonic_wave", "radius": radius})
	events.append({"type": "attack", "weapon": "sonic_wave", "count": hit_count, "radius": radius})
	state.weapon_cooldowns["sonic_wave"] = maxf(0.78, (1.70 - float(level) * 0.06) * state.get_cooldown_multiplier_for_weapon("sonic_wave") * (0.70 if evolved else 1.0))

func _process_gem_turret(state, events: Array) -> void:
	if not state.weapons.has("gem_turret") or float(state.weapon_cooldowns.get("gem_turret", 0.0)) > 0.0:
		return
	if state.gem_turret_charge <= 0 and not state.is_weapon_evolved("gem_turret"):
		return
	var level = int(state.weapons.get("gem_turret", 1))
	var evolved = state.is_weapon_evolved("gem_turret")
	var target = _nearest_enemy(state, state.player_position, 920.0)
	if target == null:
		return
	state.gem_turret_charge = maxi(0, state.gem_turret_charge - 1)
	var count = 1 + int(floor(float(level) / 4.0)) + (2 if evolved else 0)
	var base_dir = (target.position - state.player_position).normalized()
	for i in range(count):
		var dir = base_dir.rotated((float(i) - float(count - 1) * 0.5) * 0.10)
		var damage = int(round(float(9 + level * 2) * state.get_damage_multiplier_for_weapon("gem_turret")))
		state.projectiles.append(_projectile(state, "gem_turret", state.player_position + dir * 22.0, dir * 720.0, damage, 1 + (2 if evolved else 0), 1.5, 10.0, 28.0 * state.get_area_multiplier_for_weapon("gem_turret"), evolved))
	events.append({"type": "attack", "weapon": "gem_turret", "count": count})
	state.weapon_cooldowns["gem_turret"] = maxf(0.46, (1.18 - float(level) * 0.035) * state.get_cooldown_multiplier_for_weapon("gem_turret") * (0.72 if evolved else 1.0))

func _process_projectiles(state, delta: float, events: Array) -> void:
	var original_count: int = state.projectiles.size()
	var write_index := 0
	for read_index in range(original_count):
		var projectile = state.projectiles[read_index]
		var keep := true
		projectile.lifetime -= delta
		if projectile.kind == "magic_bolt" and state.has_overclock("magic_bolt", "comet_orbit"):
			var homing_target = _nearest_enemy(state, projectile.position, 360.0)
			if homing_target != null and projectile.velocity.length() > 1.0:
				projectile.velocity = projectile.velocity.lerp((homing_target.position - projectile.position).normalized() * projectile.velocity.length(), minf(1.0, delta * 3.0))
		projectile.position += projectile.velocity * delta
		field_gimmick_system.reflect_projectile_if_needed(state, projectile, events)
		if projectile.kind in ["mirror_shard", "wall_bounce_blaster", "void_mirror", "compass_star"]:
			keep = _process_mirror_bounce(state, projectile, events)
		if projectile.lifetime <= 0.0:
			keep = false
		elif keep and projectile.kind in ["black_hole", "gravity_anchor"]:
			_process_black_hole_projectile(state, projectile, delta, events)
		elif keep and projectile.kind in ["rune_gate", "burning_afterglow", "comet_crater", "mine_lantern", "shrine_beam", "thorn_seed", "frost_wall", "magma_core", "guardian_wall"]:
			_process_rune_gate_projectile(state, projectile, delta, events)
		elif keep:
			var wall_hits = field_system.damage_walls_in_radius(state, projectile.position, projectile.radius, projectile.damage, events, projectile.kind)
			var gimmick_hits = field_gimmick_system.damage_gimmicks_in_radius(state, projectile.position, projectile.radius, projectile.damage, events, projectile.kind)
			if wall_hits > 0 or gimmick_hits > 0:
				if projectile.pierce_left > 0:
					projectile.pierce_left -= 1
				else:
					keep = false
			if keep:
				for enemy in enemy_grid.query_radius(projectile.position, projectile.radius + 80.0):
					var enemy_id: int = enemy.get_instance_id()
					if projectile.hit_target_ids.has(enemy_id):
						continue
					if enemy.position.distance_to(projectile.position) <= enemy.radius + projectile.radius:
						projectile.hit_targets.append(enemy)
						projectile.hit_target_ids[enemy_id] = true
						_damage_enemy(state, enemy, projectile.damage, events, projectile.kind, projectile.position)
						if projectile.splash_radius > 0.0:
							_explode(state, projectile.position, projectile.splash_radius, max(1, int(projectile.damage * 0.55)), events, "bolt_blast")
						if projectile.pierce_left > 0:
							projectile.pierce_left -= 1
						else:
							keep = false
							break
		if keep:
			state.projectiles[write_index] = projectile
			write_index += 1
		else:
			state.release_runtime("projectile", projectile)
	var appended_count: int = state.projectiles.size() - original_count
	for appended_index in range(appended_count):
		state.projectiles[write_index] = state.projectiles[original_count + appended_index]
		write_index += 1
	state.projectiles.resize(write_index)

func _process_rune_gate_projectile(state, projectile, delta: float, events: Array) -> void:
	var periodic_interval := 0.50 if projectile.kind == "rune_gate" else (0.46 if projectile.kind in ["mine_lantern", "frost_wall"] else 0.38)
	for enemy in enemy_grid.query_radius(projectile.position, projectile.splash_radius + 64.0):
		if enemy.position.distance_to(projectile.position) <= projectile.splash_radius + enemy.radius and enemy.can_take_periodic_hit(projectile.kind, periodic_interval):
			_damage_enemy(state, enemy, projectile.damage, events, projectile.kind, enemy.position)
			if projectile.kind == "frost_wall":
				enemy.slow_timer = maxf(enemy.slow_timer, 1.4)
	field_system.damage_walls_in_radius(state, projectile.position, projectile.splash_radius, max(1, int(projectile.damage * 0.40)), events, projectile.kind)
	field_gimmick_system.damage_gimmicks_in_radius(state, projectile.position, projectile.splash_radius, max(1, int(projectile.damage * 0.40)), events, projectile.kind)

func _process_mirror_bounce(state, projectile, events: Array) -> bool:
	var bounced = false
	if projectile.position.x < 0.0 or projectile.position.x > state.field_size.x:
		projectile.velocity.x *= -1.0
		projectile.position.x = clampf(projectile.position.x, 0.0, state.field_size.x)
		bounced = true
	if projectile.position.y < 0.0 or projectile.position.y > state.field_size.y:
		projectile.velocity.y *= -1.0
		projectile.position.y = clampf(projectile.position.y, 0.0, state.field_size.y)
		bounced = true
	if bounced:
		projectile.bounce_left -= 1
		events.append({"type": "projectile_bounce", "weapon": projectile.kind, "pos": projectile.position})
		if projectile.evolved and state.has_overclock("mirror_shard", "split_reflect") and projectile.bounce_left >= 0:
			var p = _projectile(state, "mirror_shard", projectile.position, projectile.velocity.rotated(0.42), projectile.damage, projectile.pierce_left, projectile.lifetime, projectile.radius, projectile.splash_radius, projectile.evolved)
			p.bounce_left = projectile.bounce_left
			state.projectiles.append(p)
		if projectile.bounce_left < 0:
			return false
	return true

func _process_black_hole_projectile(state, projectile, delta: float, events: Array) -> void:
	var periodic_interval := 0.52 if projectile.kind == "gravity_anchor" else 0.48
	var pull_speed := 185.0 if projectile.kind == "gravity_anchor" else 155.0
	for enemy in enemy_grid.query_radius(projectile.position, projectile.splash_radius + 64.0):
		var distance = enemy.position.distance_to(projectile.position)
		if distance <= projectile.splash_radius + enemy.radius:
			var direction = (projectile.position - enemy.position).normalized()
			knockback_resolver.move_by(state, enemy, direction * pull_speed * delta, events, projectile.kind)
			if enemy.can_take_periodic_hit(projectile.kind, periodic_interval):
				_damage_enemy(state, enemy, projectile.damage, events, projectile.kind, enemy.position)
	for gem in state.gems:
		if gem.position.distance_to(projectile.position) <= projectile.splash_radius:
			gem.attracting = true
			gem.velocity = gem.velocity.lerp((projectile.position - gem.position).normalized() * 360.0, minf(1.0, delta * 5.0))
	field_system.damage_walls_in_radius(state, projectile.position, projectile.splash_radius, max(1, int(projectile.damage * 0.45)), events, projectile.kind)
	field_gimmick_system.damage_gimmicks_in_radius(state, projectile.position, projectile.splash_radius, max(1, int(projectile.damage * 0.45)), events, projectile.kind)

func _process_bombs(state, delta: float, events: Array) -> void:
	var write_index := 0
	for read_index in range(state.bombs.size()):
		var bomb = state.bombs[read_index]
		bomb.lifetime -= delta
		if bomb.lifetime <= 0.0:
			state.release_runtime("projectile", bomb)
			_explode(state, bomb.position, bomb.splash_radius, bomb.damage, events, "final_fireworks" if bomb.evolved else bomb.kind)
			if bomb.evolved:
				var bloom_count = 5 if state.has_overclock("bomb_seed", "triple_bloom") else 3
				for i in range(bloom_count):
					var angle = TAU * float(i) / 3.0 + state.rng.range_float(-0.2, 0.2)
					_explode(state, bomb.position + Vector2(cos(angle), sin(angle)) * bomb.splash_radius * 0.55, bomb.splash_radius * 0.55, max(1, int(bomb.damage * 0.55)), events, "final_fireworks")
				if state.has_overclock("bomb_seed", "burning_afterglow"):
					state.projectiles.append(_projectile(state, "burning_afterglow", bomb.position, Vector2.ZERO, max(1, int(bomb.damage * 0.28)), 99, 2.4, 12.0, bomb.splash_radius * 0.55, true))
				if state.has_overclock("bomb_seed", "overloaded_firework") and state.rng.chance(0.08):
					var self_damage = maxi(1, int(round(float(state.max_hp) * 0.03)))
					state.hp -= self_damage
					state.record_damage_taken(self_damage)
					events.append({"type": "player_damage", "damage": self_damage, "hp": state.hp, "enemy": "花火過積載"})
			elif bomb.kind == "comet_staff" and state.has_overclock("comet_staff", "crater_bonus"):
				state.projectiles.append(_projectile(state, "comet_crater", bomb.position, Vector2.ZERO, max(1, int(bomb.damage * 0.24)), 99, 1.8, 12.0, bomb.splash_radius * 0.62, true))
		else:
			state.bombs[write_index] = bomb
			write_index += 1
	state.bombs.resize(write_index)

func _explode(state, pos: Vector2, radius: float, damage: int, events: Array, source: String) -> void:
	events.append({"type": "explosion", "pos": pos, "radius": radius, "source": source})
	state.add_hit_flash({"pos": pos, "life": 0.28, "source": source, "radius": radius})
	field_system.damage_walls_in_radius(state, pos, radius, damage, events, source)
	field_gimmick_system.damage_gimmicks_in_radius(state, pos, radius, damage, events, source)
	for enemy in enemy_grid.query_radius(pos, radius + 64.0):
		if enemy.position.distance_to(pos) <= radius + enemy.radius:
			_damage_enemy(state, enemy, damage, events, source, pos)

func _damage_enemy(state, enemy, damage: int, events: Array, source: String, hit_pos: Vector2) -> void:
	if enemy == null or enemy.hp <= 0 or damage <= 0:
		return
	var actual_damage = _adjust_damage_for_enemy(state, enemy, damage, source)
	enemy.hp -= actual_damage
	state.record_damage(actual_damage)
	state.weapon_damage_by_id[source] = int(state.weapon_damage_by_id.get(source, 0)) + actual_damage
	var category := String(state.weapon_defs.get(source, {}).get("category", "other"))
	state.damage_by_category[category] = int(state.damage_by_category.get(category, 0)) + actual_damage
	if enemy.boss:
		state.boss_damage_by_weapon_id[source] = int(state.boss_damage_by_weapon_id.get(source, 0)) + actual_damage
	else:
		state.enemy_damage_by_weapon_id[source] = int(state.enemy_damage_by_weapon_id.get(source, 0)) + actual_damage
	state.add_hit_flash({"pos": hit_pos, "life": 0.18, "source": source})
	events.append({"type": "enemy_hit", "enemy": enemy.type, "damage": actual_damage, "hp": enemy.hp, "source": source, "pos": hit_pos})
	if state.weapon_has_tag(source, "lightning") or source in ["thunder_field"]:
		shock_stack_system.apply_lightning_hit(state, enemy, actual_damage, hit_pos, events)
	if state.weapon_has_tag(source, "poison"):
		enemy.poison_timer = 2.0
	if enemy.hp > 0:
		return
	var death_pos = enemy.position
	state.enemies.erase(enemy)
	state.kills += 1
	state.terrain_kills[state.current_terrain_id] = int(state.terrain_kills.get(state.current_terrain_id, 0)) + 1
	state.weapon_kill_counts[source] = int(state.weapon_kill_counts.get(source, 0)) + 1
	melee_rush_system.record_kill(state, source, events)
	state.add_score(enemy.score, death_pos)
	exp_system.drop_for_enemy(state, enemy, events)
	if enemy.splits > 0 and enemy.split_type != "":
		_spawn_split_children(state, enemy, death_pos, events)
	if enemy.behavior == "bomber" and enemy_projectile_policy.can_emit_explosive(enemy):
		_explode(state, death_pos, 108.0, maxi(5, int(enemy.damage * 0.75)), events, "bomber")
	if source == "ice_orbit" and state.has_overclock("ice_orbit", "powder_chain"):
		_slow_nearby(state, death_pos, 170.0, 1.8)
	if source in ["thunder_chain", "thunder_field"] and state.has_overclock("thunder_chain", "shock_burst"):
		_explode(state, death_pos, 82.0, maxi(2, int(actual_damage * 0.40)), events, "shock_burst")
	if source == "soul_scythe" and (state.is_weapon_evolved("soul_scythe") or state.has_overclock("soul_scythe", "life_reap")):
		var chance = 0.18 if state.is_weapon_evolved("soul_scythe") else 0.08
		if state.has_overclock("soul_scythe", "life_reap"):
			chance += 0.18
		if state.rng.chance(chance) and state.hp < state.max_hp:
			var heal = 2 + int(state.passives.get("regen", 0))
			state.hp = mini(state.max_hp, state.hp + heal)
			state.healing_by_source["soul_scythe"] = int(state.healing_by_source.get("soul_scythe", 0)) + heal
			events.append({"type": "player_heal", "amount": heal, "source": "soul_scythe", "hp": state.hp})
	if enemy.boss:
		var boss_id = String(enemy.type)
		if not state.boss_defeated_ids.has(boss_id):
			state.boss_defeated_ids.append(boss_id)
		chest_system.drop_chest(state, death_pos, events, "normal", "boss")
		if int(enemy.data.get("minute", 0)) >= 30:
			state.title_badges.append("終末核撃破")
			state.add_score(25000, death_pos)
		rune_contract_system.offer_after_boss(state, events)
	elif enemy.guaranteed_chest or enemy.elite or enemy.type == "elite":
		if state.event_elite_reward_pending or state.can_drop_elite_chest():
			chest_system.drop_chest(state, death_pos, events, "normal", "elite")
			state.reset_elite_chest_cooldown()
			state.event_elite_reward_pending = false
	if source == "magic_bolt" and state.is_weapon_evolved("magic_bolt"):
		_explode(state, death_pos, 76.0 * state.get_area_multiplier_for_weapon("magic_bolt"), max(1, int(actual_damage * 0.45)), events, "star_fragment")
	events.append({"type": "enemy_die", "enemy": enemy.type, "pos": death_pos, "kills": state.kills})
	state.release_runtime("enemy", enemy)

func _adjust_damage_for_enemy(state, enemy, damage: int, source: String) -> int:
	var value = damage
	if enemy.behavior == "shield" and source != "black_hole" and source != "poison_mist":
		value = maxi(1, int(ceil(float(value) * 0.62)))
	if enemy.elite or enemy.boss:
		var elite_bonus = minf(1.0, 0.12 * float(state.passives.get("elite_hunter", 0)) + 0.08 * float(state.passives.get("hunter_mark", 0)))
		value = int(round(float(value) * (1.0 + elite_bonus)))
		value = int(round(float(value) * state.rune_contract_multiplier("elite_damage_mult", 1.0)))
	else:
		value = int(round(float(value) * state.rune_contract_multiplier("normal_damage_mult", 1.0)))
	return maxi(1, value)

func _process_expansion_weapons(state, events: Array) -> void:
	for raw_id in state.weapons.keys():
		var weapon_id = String(raw_id)
		var data: Dictionary = state.weapon_defs.get(weapon_id, {})
		var pattern = String(data.get("attack_pattern", ""))
		if pattern == "" or float(state.weapon_cooldowns.get(weapon_id, 0.0)) > 0.0:
			continue
		var level = int(state.weapons.get(weapon_id, 1))
		var evolved = state.is_weapon_evolved(weapon_id)
		var range_value = float(data.get("range", 420.0)) * state.get_area_multiplier_for_weapon(weapon_id)
		var target = _nearest_damageable(state, state.player_position, range_value)
		if target == null and pattern not in ["orbit", "pulse"]:
			continue
		var damage = int(round(float(data.get("base_damage", 6) + level * 2) * float(data.get("runtime_damage_mult", 1.0)) * state.get_damage_multiplier_for_weapon(weapon_id)))
		var area = (54.0 + float(level) * 7.0) * state.get_area_multiplier_for_weapon(weapon_id) * (1.35 if evolved else 1.0)
		match pattern:
			"melee_arc":
				var direction = (target.position - state.player_position).normalized()
				var reach = minf(range_value, 125.0 + float(level) * 18.0)
				var hit_pos = state.player_position + direction * reach
				state.add_effect_line({"start": state.player_position, "end": hit_pos, "life": 0.20, "source": weapon_id, "evolved": evolved})
				_explode(state, hit_pos, area, damage, events, weapon_id)
				if weapon_id == "drill_charge":
					field_system.damage_walls_in_radius(state, hit_pos, area * 1.35, damage * 2, events, weapon_id)
			"ricochet":
				var direction = (target.position - state.player_position).normalized()
				var count = 1 + int(floor(float(level) / 4.0)) + (1 if evolved else 0)
				for i in range(count):
					var projectile = _projectile(state, weapon_id, state.player_position, direction.rotated((float(i) - float(count - 1) * 0.5) * 0.16) * (500.0 + level * 18.0), damage, 1 if evolved else 0, 3.4, 9.0, area * 0.45 if evolved else 0.0, evolved)
					projectile.bounce_left = 2 + int(floor(float(level) / 3.0)) + int(state.passives.get("reflect_prism", 0)) + (3 if evolved else 0)
					state.projectiles.append(projectile)
			"deploy_area":
				var target_pos: Vector2 = target.position
				var field = _projectile(state, weapon_id, target_pos, Vector2.ZERO, maxi(1, int(damage * 0.38)), 99, 2.4 + float(level) * 0.14 + (1.4 if evolved else 0.0), 10.0, area * 1.35, evolved)
				state.projectiles.append(field)
			"orbit":
				var count = 3 + int(floor(float(level) / 2.0)) + (3 if evolved else 0)
				for i in range(count):
					var angle = state.orbit_angle + TAU * float(i) / float(count)
					_explode(state, state.player_position + Vector2(cos(angle), sin(angle)) * (90.0 + level * 8.0), area * 0.42, damage, events, weapon_id)
			"pulse":
				var pulse_count = 2 if state.current_terrain_id == "crystal_corridor" else 1
				if evolved:
					pulse_count += 1
				for i in range(pulse_count):
					_explode(state, state.player_position, area * (1.0 + float(i) * 0.36), maxi(1, int(float(damage) * (1.0 - float(i) * 0.18))), events, weapon_id)
			"gravity":
				var anchor = _projectile(state, weapon_id, target.position, Vector2.ZERO, maxi(1, int(damage * 0.28)), 99, 3.0 + (1.5 if evolved else 0.0), 12.0, area * 1.58, evolved)
				state.projectiles.append(anchor)
		events.append({"type": "attack", "weapon": weapon_id, "count": 1})
		var cooldown = maxf(0.32, (float(data.get("cooldown", 1.5)) - float(level) * 0.045) * state.get_cooldown_multiplier_for_weapon(weapon_id) * (0.76 if evolved else 1.0))
		state.weapon_cooldowns[weapon_id] = cooldown

func _slow_nearby(state, pos: Vector2, radius: float, duration: float) -> void:
	for enemy in enemy_grid.query_radius(pos, radius + 64.0):
		if enemy.position.distance_to(pos) <= radius + enemy.radius:
			enemy.slow_timer = maxf(enemy.slow_timer, duration)

func _spawn_split_children(state, enemy, pos: Vector2, events: Array) -> void:
	for i in range(enemy.splits):
		var angle = TAU * float(i) / float(maxi(1, enemy.splits)) + state.rng.range_float(-0.25, 0.25)
		var child_pos = state.resolve_walkable_position(pos + Vector2(cos(angle), sin(angle)) * 34.0, 18.0, pos)
		var child = EnemyScript.new(enemy.split_type, state.enemy_defs.get(enemy.split_type, {}), child_pos, 0, 1.0)
		state.enemies.append(child)
		events.append({"type": "enemy_spawn", "enemy": child.type, "pos": child.position, "source": "split"})

func _nearest_damageable(state, origin: Vector2, max_distance: float):
	var enemy = _nearest_enemy(state, origin, max_distance)
	if enemy != null:
		return enemy
	var best = null
	var best_dist = max_distance
	for wall in state.crystal_walls:
		if not wall.breakable:
			continue
		var distance = wall.position.distance_to(origin)
		if distance < best_dist:
			best = wall
			best_dist = distance
	return best

func _nearest_enemy(state, origin: Vector2, max_distance: float):
	return _nearest_enemy_excluding(state, origin, max_distance, [])

func _nearest_enemy_excluding(state, origin: Vector2, max_distance: float, excluded: Array):
	var best = null
	var best_dist = max_distance
	for enemy in enemy_grid.query_radius(origin, max_distance):
		if excluded.has(enemy):
			continue
		var distance = enemy.position.distance_to(origin)
		if distance < best_dist:
			best = enemy
			best_dist = distance
	return best

func _projectile(state, projectile_kind: String, pos: Vector2, vel: Vector2, dmg: int, pierce: int, life: float, hit_radius: float, splash: float, is_evolved: bool):
	return state.acquire_projectile([projectile_kind, pos, vel, dmg, pierce, life, hit_radius, splash, is_evolved])

func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment = end - start
	var length_sq = segment.length_squared()
	if length_sq <= 0.001:
		return point.distance_to(start)
	var t = clampf((point - start).dot(segment) / length_sq, 0.0, 1.0)
	var projection = start + segment * t
	return point.distance_to(projection)
