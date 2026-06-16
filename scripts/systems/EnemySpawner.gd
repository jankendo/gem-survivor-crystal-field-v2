extends RefCounted
class_name EnemySpawner

const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")

var field_system = preload("res://scripts/systems/CrystalFieldSystem.gd").new()
var projectile_policy = preload("res://scripts/systems/EnemyProjectilePolicySystem.gd").new()
var pathing = preload("res://scripts/systems/EnemyPathingSystem.gd").new()
var ios_budget = preload("res://scripts/systems/IosPerformanceBudgetSystem.gd").new()
var movement_resolver = preload("res://scripts/systems/PlayerMovementResolver.gd").new()

func process(state, delta: float, events: Array) -> void:
	if state.game_over or state.level_up_pending or state.chest_pending:
		return
	_process_boss_schedule(state, events)
	_process_ruin_contract(state, events)
	state.spawn_meter += delta
	var interval = spawn_interval_for_state(state)
	while state.spawn_meter >= interval:
		state.spawn_meter -= interval
		var count = spawn_count_for_state(state)
		for i in range(count):
			if state.enemies.size() >= state.max_enemies():
				break
			spawn_enemy(state, pick_enemy_type(state), events)
	process_enemies(state, delta, events)
	_process_attack_warnings(state, delta)
	_process_enemy_projectiles(state, delta, events)
	state.trim_runtime_arrays()

func process_enemies(state, delta: float, events: Array) -> void:
	state.ios_pathing_update_count = 0
	for enemy in state.enemies.duplicate():
		enemy.tick_cooldowns(delta)
		enemy.action_timer = maxf(0.0, enemy.action_timer - delta)
		enemy.charge_timer = maxf(0.0, enemy.charge_timer - delta)
		enemy.telegraph_timer = maxf(0.0, enemy.telegraph_timer - delta)
		enemy.recovery_timer = maxf(0.0, enemy.recovery_timer - delta)
		if enemy.slow_timer > 0.0:
			enemy.slow_timer = maxf(0.0, enemy.slow_timer - delta)
		_process_enemy_special(state, enemy, delta, events)
		enemy.ai_accumulator += delta
		enemy.ai_update_timer -= delta
		if enemy.ai_update_timer > 0.0:
			continue
		var movement_delta: float = enemy.ai_accumulator
		enemy.ai_accumulator = 0.0
		enemy.ai_update_timer = _ai_update_interval(state, enemy)
		state.ios_pathing_update_count += 1
		var previous = enemy.position
		var direction = pathing.direction_to_target(state, enemy.position, state.player_position, enemy.radius)
		if enemy.charge_timer > 0.0 and enemy.attack_direction.length_squared() > 0.01:
			direction = enemy.attack_direction
		var slow_multiplier = 0.52 if enemy.slow_timer > 0.0 else 1.0
		if enemy.shock_stacks >= 2:
			slow_multiplier *= 0.90
		var charge_multiplier = 2.35 if enemy.charge_timer > 0.0 else 1.0
		if enemy.recovery_timer > 0.0:
			charge_multiplier = 0.18
		var velocity: Vector2 = direction * float(enemy.speed) * slow_multiplier * charge_multiplier
		var movement := movement_resolver.resolve(state, enemy.position, velocity, movement_delta, enemy.radius)
		enemy.position = movement.get("position", enemy.position)
		if enemy.position.distance_to(previous) < 0.1 and enemy.behavior == "charger":
			enemy.charge_timer = 0.0
		if enemy.position.distance_to(state.player_position) > 1650.0:
			enemy.position = pathing.recycle_position(state, state.player_position)
			events.append({"type": "enemy_recycle", "enemy": enemy.type})

func _ai_update_interval(state, enemy) -> float:
	if not String(state.performance_profile_id).begins_with("ios") or enemy.boss:
		return 0.0
	var distance: float = enemy.position.distance_to(state.player_position)
	if distance <= 720.0:
		return ios_budget.get_float("near_enemy_ai_update_interval", 0.05)
	if distance <= 1280.0:
		return ios_budget.get_float("far_enemy_ai_update_interval", 0.20)
	return ios_budget.get_float("offscreen_ai_update_interval", 0.35)

func spawn_interval(seconds: float) -> float:
	var phases = _curve_phases_from_file()
	return _phase_value(phases, seconds, "interval", 0.45)

func spawn_count(seconds: float) -> int:
	var phases = _curve_phases_from_file()
	return int(_phase_value(phases, seconds, "count", 4.0))

func spawn_interval_for_state(state) -> float:
	var phases = state.spawn_curve.get("phases", [])
	var base = _phase_value(phases, state.elapsed_seconds, "interval", spawn_interval(state.elapsed_seconds))
	var multiplier = state.get_danger_spawn_multiplier() * state.enemy_spawn_multiplier() * state.terrain_spawn_multiplier()
	return maxf(0.08, base / multiplier)

func spawn_count_for_state(state) -> int:
	var phases = state.spawn_curve.get("phases", [])
	var base = int(_phase_value(phases, state.elapsed_seconds, "count", spawn_count(state.elapsed_seconds)))
	var multiplier = state.get_danger_spawn_multiplier() * state.enemy_spawn_multiplier() * state.terrain_spawn_multiplier() * (1.0 + 0.08 * float(state.passives.get("curse", 0)))
	return maxi(1, int(ceil(float(base) * multiplier)))

func pick_enemy_type(state) -> String:
	var choices: Array = []
	for raw_id in state.enemy_defs.keys():
		var id = String(raw_id)
		var data = state.enemy_defs[id]
		if bool(data.get("boss", false)):
			continue
		var unlock = float(data.get("unlock_seconds", 0.0))
		var weight = float(data.get("weight", 0.0))
		if weight <= 0.0 or state.elapsed_seconds < unlock:
			continue
		var behavior = String(data.get("behavior", ""))
		if bool(data.get("elite", false)):
			weight *= state.elite_spawn_multiplier()
		if behavior in ["charger", "shooter", "healer", "shield", "reaper", "leech", "bomber", "crystal_sniper", "swarm_mother", "void_knight", "curse_eye"]:
			weight *= 1.0 + state.enemy_special_rate() * 2.0
		if state.elapsed_seconds >= 900.0 and behavior in ["shooter", "healer", "shield", "reaper", "bomber", "crystal_sniper"]:
			weight *= 1.45
		if state.elapsed_seconds >= 1500.0 and id == "reaper":
			weight *= 2.4
		choices.append({"type": id, "weight": weight})
	if choices.is_empty():
		return "slime"
	return String(state.rng.weighted_choice(choices).get("type", "slime"))

func spawn_enemy(state, enemy_type: String, events: Array, pos_override = null):
	var pos = state.random_walkable_position(state.player_position, 420.0, 760.0)
	if pos_override != null:
		pos = state.resolve_walkable_position(pos_override, float(state.enemy_defs.get(enemy_type, {}).get("radius", 18.0)), pos)
	pos = field_system.resolve_circle_position(state, pos, float(state.enemy_defs.get(enemy_type, {}).get("radius", 18.0)))
	var hp_bonus = int(floor(maxf(0.0, state.elapsed_seconds - 180.0) / 55.0))
	var speed_bonus = state.enemy_speed_multiplier()
	var enemy = state.acquire_enemy([enemy_type, state.enemy_defs.get(enemy_type, {}), pos, hp_bonus, speed_bonus])
	enemy.max_hp = maxi(1, int(round(float(enemy.max_hp) * state.enemy_hp_multiplier())))
	enemy.hp = enemy.max_hp
	enemy.damage = maxi(1, int(round(float(enemy.damage) * state.enemy_damage_multiplier() * state.terrain_enemy_damage_multiplier())))
	state.enemies.append(enemy)
	if not state.enemy_seen.has(enemy.type):
		state.enemy_seen.append(enemy.type)
	events.append({"type": "enemy_spawn", "enemy": enemy.type, "pos": enemy.position})
	return enemy

func spawn_boss(state, boss_id: String, events: Array, scheduled_minute: int = -1):
	var data = state.boss_defs.get(boss_id, {}).duplicate(true)
	if data.is_empty():
		return null
	while state.enemies.size() >= state.max_enemies() and not state.enemies.is_empty():
		state.release_runtime("enemy", state.enemies.pop_front())
	data["boss"] = true
	data["elite"] = true
	data["guaranteed_chest"] = true
	var minute = scheduled_minute if scheduled_minute > 0 else int(data.get("minute", 5))
	data["minute"] = minute
	data["hp"] = int(round(float(data.get("hp", 500)) * state.boss_hp_multiplier_for_minute(minute)))
	data["damage"] = int(round(float(data.get("damage", 28)) * state.enemy_damage_multiplier() * state.terrain_enemy_damage_multiplier()))
	var pos = state.boss_room_position()
	pos = field_system.resolve_circle_position(state, pos, float(data.get("radius", 54.0)))
	var enemy = state.acquire_enemy([boss_id, data, pos, 0, 1.0])
	enemy.action_timer = 1.2
	state.enemies.append(enemy)
	if not state.enemy_seen.has(enemy.type):
		state.enemy_seen.append(enemy.type)
	events.append({"type": "boss_spawn", "enemy": boss_id, "name": enemy.name_ja, "pos": enemy.position})
	return enemy

func _process_boss_schedule(state, events: Array) -> void:
	var current_checkpoint = int(floor(state.elapsed_seconds / 300.0)) * 5
	var next_minute = maxi(5, current_checkpoint)
	if current_checkpoint < 5 or state.boss_spawned_minutes.has(current_checkpoint):
		next_minute = maxi(5, current_checkpoint + 5)
	var boss_id = _boss_id_for_minute(state, next_minute)
	if boss_id == "":
		return
	var data = state.boss_defs.get(boss_id, {})
	var seconds = float(next_minute * 60)
	if state.elapsed_seconds >= seconds - 5.0 and not state.boss_warned_minutes.has(next_minute):
		state.boss_warned_minutes.append(next_minute)
		state.boss_warning_timer = 5.0
		state.boss_warning_text = "%d:00 ボス接近：%s" % [next_minute, String(data.get("name_ja", "ボス"))]
		events.append({"type": "boss_warning", "minute": next_minute, "message": state.boss_warning_text, "duration": 5.0, "pos": state.boss_room_position()})
	if state.elapsed_seconds >= seconds and not state.boss_spawned_minutes.has(next_minute):
		state.boss_spawned_minutes.append(next_minute)
		if state.boss_alive():
			state.strengthen_active_boss(events, next_minute)
		else:
			spawn_boss(state, boss_id, events, next_minute)

func _boss_id_for_minute(state, minute: int) -> String:
	var best_id = ""
	var best_minute = -1
	for raw_id in state.boss_defs.keys():
		var id = String(raw_id)
		var boss_minute = int(state.boss_defs[id].get("minute", 0))
		if boss_minute == minute:
			return id
		if boss_minute <= minute and boss_minute > best_minute:
			best_id = id
			best_minute = boss_minute
	return best_id

func _process_enemy_special(state, enemy, delta: float, events: Array) -> void:
	if enemy.boss:
		_process_boss_special(state, enemy, delta, events)
		return
	if enemy.behavior == "charger" and enemy.action_timer <= 0.0 and enemy.position.distance_to(state.player_position) < 430.0:
		enemy.charge_timer = 0.75
		enemy.action_timer = 3.0
		events.append({"type": "enemy_charge", "enemy": enemy.type, "pos": enemy.position})
	elif enemy.behavior == "shooter":
		_process_shooter_dash(state, enemy, events)
	elif enemy.behavior == "healer" and enemy.action_timer <= 0.0:
		enemy.action_timer = 2.4
		for other in state.enemies:
			if other != enemy and other.position.distance_to(enemy.position) <= 160.0 and other.hp < other.max_hp:
				other.hp = mini(other.max_hp, other.hp + 4)
		events.append({"type": "enemy_heal", "enemy": enemy.type, "pos": enemy.position})
	elif enemy.behavior == "leech" and enemy.action_timer <= 0.0 and enemy.position.distance_to(state.player_position) < 92.0:
		enemy.action_timer = 0.72
		var damage = maxi(1, int(round(float(enemy.damage) * 0.45 * state.rune_contract_damage_taken_multiplier() * state.modifier_mult("damage_taken_mult", 1.0))))
		state.hp -= damage
		state.record_damage_taken(damage)
		state.damage_flash_timer = 0.18
		events.append({"type": "player_damage", "damage": damage, "hp": state.hp, "enemy": enemy.type})
		if state.hp <= 0:
			state.game_over = true
			state.game_over_reason = "%sに吸い尽くされました" % enemy.name_ja
	elif enemy.behavior == "crystal_sniper":
		if projectile_policy.can_emit_ground_attack(enemy):
			_process_crystal_spike(state, enemy, events)
		elif enemy.action_timer <= 0.0:
			enemy.action_timer = 3.2
			events.append({"type": "enemy_special_blocked", "blocked": "ground_attack", "enemy": enemy.type})
	elif enemy.behavior == "swarm_mother" and enemy.action_timer <= 0.0:
		enemy.action_timer = 5.0
		_spawn_boss_minions(state, enemy.position, "bat", 3, events)
	elif enemy.behavior == "curse_eye" and enemy.action_timer <= 0.0:
		enemy.action_timer = 7.0
		var danger_pos = state.random_walkable_position(state.player_position, 90.0, 280.0)
		state.danger_zones.append({"id": "curse_eye_%d" % state.danger_zones.size(), "position": danger_pos, "radius": 260.0, "biome": state.current_biome_id})
		events.append({"type": "danger_spawn", "source": "curse_eye", "pos": state.player_position})

func _process_boss_special(state, enemy, delta: float, events: Array) -> void:
	if enemy.action_timer > 0.0:
		return
	var minute = int(enemy.data.get("minute", 5))
	var interval = maxf(0.55, (2.2 - float(minute) * 0.03) / state.enemy_projectile_multiplier())
	enemy.action_timer = interval
	events.append({"type": "boss_attack", "enemy": enemy.type, "minute": minute, "pos": enemy.position})
	if minute == 5:
		_spawn_boss_minions(state, enemy.position, "slime", 4, events)
		_fire_radial_projectiles(state, enemy, enemy.position, 8, enemy.damage, 210.0, "slime_wave", events)
	elif minute == 10:
		enemy.charge_timer = 1.2
		events.append({"type": "boss_charge_warning", "pos": enemy.position})
		_fire_enemy_projectile(state, enemy, enemy.position, state.player_position, enemy.damage, 340.0, 12.0, "charge_line", events)
	elif minute == 15:
		_spawn_temporary_crystal(state, enemy.position, events)
		_fire_radial_projectiles(state, enemy, enemy.position, 10, enemy.damage, 235.0, "crystal_shard", events)
	elif minute == 20:
		_expand_danger_zone(state, enemy.position)
		_fire_homing_burst(state, enemy, enemy.position, enemy.damage, events)
	elif minute == 25:
		enemy.charge_timer = 1.6
		_fire_radial_projectiles(state, enemy, enemy.position, 14, enemy.damage, 280.0, "reaper_wave", events)
	elif minute >= 30:
		_expand_danger_zone(state, enemy.position)
		_spawn_boss_minions(state, enemy.position, "reaper", 3, events)
		_spawn_boss_minions(state, enemy.position, "shooter", 5, events)
		_fire_radial_projectiles(state, enemy, enemy.position, 22, enemy.damage, 310.0, "doom_core", events)

func _fire_enemy_projectile(state, source_enemy, origin: Vector2, target: Vector2, damage: int, speed: float, radius: float, kind: String, events: Array) -> bool:
	if not projectile_policy.can_emit_projectile(source_enemy):
		events.append({"type": "enemy_projectile_blocked", "enemy": source_enemy.type if source_enemy != null else "", "kind": kind})
		return false
	if state.enemy_projectiles.size() >= state.max_enemy_projectiles():
		state.enemy_projectiles.pop_front()
	var direction = (target - origin).normalized()
	var source_class = projectile_policy.source_class(source_enemy)
	state.enemy_projectiles.append({"position": origin, "velocity": direction * speed, "damage": damage, "radius": radius, "life": 4.0, "kind": kind, "source_enemy": source_enemy.type, "source_class": source_class, "warned": true})
	state.enemy_attack_warnings.append({"kind": "line", "position": origin, "target": target, "radius": radius + 9.0, "life": 0.38, "source_class": source_class})
	events.append({"type": "enemy_attack_warning", "kind": kind, "pos": origin, "target": target, "source_class": source_class})
	events.append({"type": "enemy_projectile", "kind": kind, "pos": origin, "source_class": source_class})
	return true

func _fire_radial_projectiles(state, source_enemy, origin: Vector2, count: int, damage: int, speed: float, kind: String, events: Array) -> void:
	var actual_count = int(round(float(count) * minf(2.2, state.enemy_projectile_multiplier())))
	for i in range(actual_count):
		var angle = TAU * float(i) / float(actual_count)
		_fire_enemy_projectile(state, source_enemy, origin, origin + Vector2(cos(angle), sin(angle)) * 100.0, maxi(2, int(damage * 0.55)), speed, 8.0, kind, events)

func _fire_homing_burst(state, source_enemy, origin: Vector2, damage: int, events: Array) -> void:
	for i in range(5):
		var target = state.player_position + Vector2(cos(float(i)), sin(float(i))) * 90.0
		_fire_enemy_projectile(state, source_enemy, origin, target, maxi(3, int(damage * 0.50)), 250.0, 9.0, "mist_orb", events)

func _process_shooter_dash(state, enemy, events: Array) -> void:
	if enemy.special_phase == "dash_warning":
		if enemy.telegraph_timer <= 0.0:
			enemy.special_phase = "dash"
			enemy.charge_timer = 0.58
			enemy.recovery_timer = 1.25
			events.append({"type": "enemy_dash", "enemy": enemy.type, "pos": enemy.position, "direction": enemy.attack_direction})
		return
	if enemy.special_phase == "dash" and enemy.charge_timer <= 0.0:
		enemy.special_phase = "recovery"
		return
	if enemy.special_phase == "recovery":
		if enemy.recovery_timer <= 0.0:
			enemy.special_phase = ""
		return
	if enemy.special_phase == "" and enemy.action_timer <= 0.0 and enemy.position.distance_to(state.player_position) < 440.0:
		enemy.special_phase = "dash_warning"
		enemy.telegraph_timer = 0.72
		enemy.action_timer = maxf(2.7, 3.5 / state.enemy_projectile_multiplier())
		enemy.attack_direction = (state.player_position - enemy.position).normalized()
		enemy.attack_target = enemy.position + enemy.attack_direction * 360.0
		state.enemy_attack_warnings.append({"kind": "dash", "position": enemy.position, "target": enemy.attack_target, "radius": enemy.radius, "life": enemy.telegraph_timer, "enemy": enemy.type})
		events.append({"type": "enemy_dash_warning", "enemy": enemy.type, "pos": enemy.position, "target": enemy.attack_target, "duration": enemy.telegraph_timer})

func _process_crystal_spike(state, enemy, events: Array) -> void:
	if enemy.special_phase == "spike_warning":
		if enemy.telegraph_timer <= 0.0:
			enemy.special_phase = "recovery"
			enemy.recovery_timer = 1.0
			var radius = 52.0 if not enemy.elite else 66.0
			state.add_hit_flash({"pos": enemy.attack_target, "life": 0.35, "source": "crystal_spike", "radius": radius})
			events.append({"type": "enemy_ground_attack", "enemy": enemy.type, "pos": enemy.attack_target, "radius": radius})
			if state.player_position.distance_to(enemy.attack_target) <= radius + 18.0 and state.invincible_timer <= 0.0:
				var damage = maxi(1, int(round(float(enemy.damage) * 0.85 * state.rune_contract_damage_taken_multiplier() * state.modifier_mult("damage_taken_mult", 1.0))))
				state.hp -= damage
				state.record_damage_taken(damage)
				state.invincible_timer = 0.45
				state.damage_flash_timer = 0.22
				events.append({"type": "player_damage", "damage": damage, "hp": state.hp, "enemy": enemy.type})
				if state.hp <= 0:
					state.game_over = true
					state.game_over_reason = "予兆結晶に貫かれました"
		return
	if enemy.special_phase == "recovery":
		if enemy.recovery_timer <= 0.0:
			enemy.special_phase = ""
		return
	if enemy.special_phase == "" and enemy.action_timer <= 0.0 and enemy.position.distance_to(state.player_position) < 720.0:
		enemy.special_phase = "spike_warning"
		enemy.telegraph_timer = 1.15
		enemy.action_timer = maxf(2.8, 3.7 / state.enemy_projectile_multiplier())
		enemy.attack_target = state.player_position
		state.enemy_attack_warnings.append({"kind": "ground_spike", "position": enemy.attack_target, "target": enemy.attack_target, "radius": 52.0 if not enemy.elite else 66.0, "life": enemy.telegraph_timer, "enemy": enemy.type})
		events.append({"type": "enemy_ground_attack_warning", "enemy": enemy.type, "pos": enemy.attack_target, "duration": enemy.telegraph_timer})

func _process_attack_warnings(state, delta: float) -> void:
	for warning in state.enemy_attack_warnings.duplicate():
		warning["life"] = float(warning.get("life", 0.0)) - delta
		if float(warning.get("life", 0.0)) <= 0.0:
			state.enemy_attack_warnings.erase(warning)

func _process_enemy_projectiles(state, delta: float, events: Array) -> void:
	for shot in state.enemy_projectiles.duplicate():
		shot["life"] = float(shot.get("life", 0.0)) - delta
		shot["position"] = shot.get("position", Vector2.ZERO) + shot.get("velocity", Vector2.ZERO) * delta
		if float(shot.get("life", 0.0)) <= 0.0:
			state.enemy_projectiles.erase(shot)
			continue
		if shot.get("position", Vector2.ZERO).distance_to(state.player_position) <= float(shot.get("radius", 7.0)) + 18.0 and state.invincible_timer <= 0.0:
			var damage = maxi(1, int(round(float(shot.get("damage", 4)) * state.rune_contract_damage_taken_multiplier() * state.modifier_mult("damage_taken_mult", 1.0))))
			state.hp -= damage
			state.record_damage_taken(damage)
			state.invincible_timer = 0.45
			state.damage_flash_timer = 0.22
			state.enemy_projectiles.erase(shot)
			events.append({"type": "player_damage", "damage": damage, "hp": state.hp, "enemy": String(shot.get("kind", "弾"))})
			if state.hp <= 0:
				state.game_over = true
				state.game_over_reason = "敵弾に撃たれました"

func _process_ruin_contract(state, events: Array) -> void:
	if not state.rune_contracts.has("ruin_pact"):
		return
	var minute = int(floor(state.elapsed_seconds / 60.0))
	if minute > 0 and minute % 10 == 0 and state.last_ruin_reaper_minute != minute:
		state.last_ruin_reaper_minute = minute
		_spawn_boss_minions(state, state.player_position + Vector2(360, 0), "reaper", 1, events)

func _spawn_boss_minions(state, pos: Vector2, enemy_type: String, count: int, events: Array) -> void:
	for i in range(count):
		if state.enemies.size() >= state.max_enemies():
			return
		var angle = TAU * float(i) / float(maxi(1, count))
		spawn_enemy(state, enemy_type, events, pos + Vector2(cos(angle), sin(angle)) * 120.0)

func _spawn_temporary_crystal(state, pos: Vector2, events: Array) -> void:
	var wall_script = preload("res://scripts/core/CrystalWall.gd")
	var angle = state.rng.range_float(0.0, TAU)
	var wall_pos = state.resolve_walkable_position(pos + Vector2(cos(angle), sin(angle)) * 180.0, 38.0, pos)
	var wall = wall_script.new("boss_crystal_%d" % int(state.elapsed_seconds * 10.0), wall_pos, Vector2(150, 90), 80, true, "internal", "cursed_crystal", state.current_biome_id)
	wall.rescale_hp(state.crystal_hp_multiplier_for_position(wall.position))
	state.crystal_walls.append(wall)
	events.append({"type": "crystal_summon", "pos": wall.position})

func _expand_danger_zone(state, pos: Vector2) -> void:
	state.danger_zones.append({"id": "boss_danger_%d" % state.danger_zones.size(), "position": pos, "radius": 360.0 + state.elapsed_minutes() * 16.0, "biome": state.current_biome_id})

func _phase_value(phases: Array, seconds: float, key: String, default_value: float) -> float:
	var value = default_value
	for phase in phases:
		if seconds >= float(phase.get("time", 0.0)):
			value = float(phase.get(key, value))
	return value

func _curve_phases_from_file() -> Array:
	if not FileAccess.file_exists("res://data/spawn_curve.json"):
		return [
			{"time": 0, "interval": 1.0, "count": 2},
			{"time": 300, "interval": 0.32, "count": 5},
			{"time": 1800, "interval": 0.12, "count": 14}
		]
	var file = FileAccess.open("res://data/spawn_curve.json", FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed.get("phases", [])
	return []
