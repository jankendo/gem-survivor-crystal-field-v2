extends RefCounted
class_name CrystalFieldSystem

const ExpGemScript = preload("res://scripts/core/ExpGem.gd")
const ChestScript = preload("res://scripts/core/Chest.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
var terrain_gimmick_system = preload("res://scripts/systems/TerrainGimmickSystem.gd").new()

func process(state, delta: float, events: Array) -> void:
	state.update_minute_buckets()
	state.combo_magnet_timer = maxf(0.0, state.combo_magnet_timer - delta)
	state.gem_fever_timer = maxf(0.0, state.gem_fever_timer - delta)
	if state.gem_fever_timer <= 0.0:
		state.gem_fever_tier = 0
	state.crystal_overdrive_timer = maxf(0.0, state.crystal_overdrive_timer - delta)
	state.damage_flash_timer = maxf(0.0, state.damage_flash_timer - delta)
	state.boundary_touch_timer = maxf(0.0, state.boundary_touch_timer - delta)
	state.chest_notice_timer = maxf(0.0, state.chest_notice_timer - delta)
	state.boss_warning_timer = maxf(0.0, state.boss_warning_timer - delta)
	state.elite_chest_cooldown = maxf(0.0, state.elite_chest_cooldown - delta)
	state.recall_drone_active_timer = maxf(0.0, state.recall_drone_active_timer - delta)
	if not state.recall_drone_ready:
		state.recall_drone_meter += delta
		if state.recall_drone_meter >= float(state.balance_data.get("recall_drone_charge_seconds", 180.0)):
			state.recall_drone_meter = float(state.balance_data.get("recall_drone_charge_seconds", 180.0))
			state.recall_drone_ready = true
			events.append({"type": "recall_drone_ready"})
	state.update_current_biome()
	state.update_current_terrain(events)
	terrain_gimmick_system.process(state, delta, events)
	if state.is_position_in_danger_zone(state.player_position):
		state.danger_time += delta
	if state.hp_ratio() <= 0.10:
		state.low_hp_survival_time += delta
	for wall in state.crystal_walls:
		wall.pulse += delta
		wall.rescale_hp(state.crystal_hp_multiplier_for_position(wall.position))

func resolve_circle_position(state, pos: Vector2, radius: float) -> Vector2:
	var resolved = pos
	var before = resolved
	resolved.x = clampf(resolved.x, radius, state.field_size.x - radius)
	resolved.y = clampf(resolved.y, radius, state.field_size.y - radius)
	if before != resolved:
		state.boundary_touch_timer = 0.25
	for wall in state.crystal_walls:
		if not wall.blocks:
			continue
		if wall.breakable and int(state.passives.get("emergency_route", 0)) > 0 and state.hp_ratio() <= 0.24:
			continue
		resolved = _push_circle_out_of_rect(resolved, radius, wall.rect())
	resolved = state.resolve_walkable_position(resolved, radius, before)
	return resolved

func damage_walls_in_radius(state, pos: Vector2, radius: float, damage: int, events: Array, source: String) -> int:
	var hits = 0
	var overdrive = 2.0 if state.crystal_overdrive_timer > 0.0 else 1.0
	var actual_damage = int(round(float(damage) * overdrive * state.crystal_damage_multiplier() * (1.0 + 0.16 * float(state.passives.get("crystal_breaker", 0)))))
	for wall in state.crystal_walls.duplicate():
		if not wall.breakable:
			continue
		if _circle_intersects_rect(pos, radius, wall.rect()):
			damage_wall(state, wall, actual_damage, events, source)
			hits += 1
	return hits

func damage_wall(state, wall, damage: int, events: Array, source: String) -> bool:
	if wall == null or not state.crystal_walls.has(wall) or not wall.breakable or damage <= 0:
		return false
	wall.hp -= damage
	state.record_damage(damage)
	state.hit_flashes.append({"pos": wall.position, "life": 0.18, "source": source})
	events.append({"type": "crystal_hit", "id": wall.id, "damage": damage, "hp": wall.hp, "source": source, "pos": wall.position})
	if wall.hp > 0:
		return false
	var break_pos = wall.position
	state.crystal_walls.erase(wall)
	state.crystals_destroyed += 1
	state.terrain_crystals[state.current_terrain_id] = int(state.terrain_crystals.get(state.current_terrain_id, 0)) + 1
	if wall.kind == "shortcut" or wall.wall_type == "shortcut_wall":
		state.shortcut_walls_broken += 1
	if state.crystals_destroyed % int(state.balance_data.get("crystal_overdrive_break_interval", 10)) == 0:
		state.crystal_overdrive_timer = float(state.balance_data.get("crystal_overdrive_duration", 10.0))
		state.overdrive_count += 1
		state.message = "クリスタルオーバードライブ！"
		events.append({"type": "crystal_overdrive", "duration": state.crystal_overdrive_timer})
	state.add_score(130, break_pos)
	_drop_crystal_rewards(state, wall, break_pos, events)
	events.append({"type": "crystal_break", "id": wall.id, "pos": break_pos, "count": state.crystals_destroyed})
	return true

func _drop_crystal_rewards(state, wall, pos: Vector2, events: Array) -> void:
	var min_count = int(state.balance_data.get("crystal_drop_gems_min", 2))
	var max_count = int(state.balance_data.get("crystal_drop_gems_max", 5))
	var reward_multiplier = float(wall.reward_multiplier) * state.rune_contract_crystal_reward_multiplier() * state.character_crystal_reward_multiplier() * state.terrain_reward_multiplier()
	if state.crystal_overdrive_timer > 0.0:
		reward_multiplier *= 1.5
	if state.active_field_event.get("id", "") == "crystal_surge":
		reward_multiplier *= 1.45
	var drop_count = int(round(float(state.rng.range_int(min_count, max_count)) * reward_multiplier)) + int(floor(float(state.passives.get("crystal_breaker", 0)) / 2.0))
	for i in range(drop_count):
		if state.gems.size() >= state.max_gems():
			break
		var angle = state.rng.range_float(0.0, TAU)
		var offset = Vector2(cos(angle), sin(angle)) * state.rng.range_float(16.0, 54.0)
		var gem_value = maxi(1, int(round(float(4 + int(state.passives.get("crystal_breaker", 0))) * reward_multiplier * state.get_exp_drop_multiplier())))
		var gem_position = state.resolve_walkable_position(pos + offset, 8.0, pos)
		var gem = ExpGemScript.new(gem_position, gem_value)
		state.gems.append(gem)
		events.append({"type": "gem_drop", "pos": gem.position, "value": gem.value, "enemy": "crystal"})
	var heal_chance = float(state.balance_data.get("crystal_heal_chance", 0.18)) + 0.02 * float(state.passives.get("luck", 0))
	if state.rng.chance(heal_chance) and state.hp < state.max_hp:
		var heal = 6 + int(state.passives.get("pickup_heal", 0))
		state.hp = mini(state.max_hp, state.hp + heal)
		state.add_floating_text("+%d HP" % heal, pos, Color(0.42, 1.0, 0.52))
		events.append({"type": "player_heal", "amount": heal, "source": "crystal", "hp": state.hp, "pos": pos})
	var chest_chance = float(state.balance_data.get("crystal_chest_chance", 0.12)) + 0.035 * float(state.passives.get("luck", 0))
	if state.rng.chance(chest_chance):
		var chest = ChestScript.new(pos, "normal", "crystal")
		if state.add_chest(chest):
			events.append({"type": "chest_drop", "pos": pos, "source": "crystal", "rarity": chest.rarity})
	if wall.wall_type == "cursed_crystal":
		_spawn_cursed_enemies(state, pos, events)

func _spawn_cursed_enemies(state, pos: Vector2, events: Array) -> void:
	var count = 3 + int(floor(state.elapsed_minutes() / 8.0))
	for i in range(count):
		if state.enemies.size() >= state.max_enemies():
			return
		var angle = TAU * float(i) / float(count)
		var enemy_type = "ghost" if state.elapsed_seconds < 900.0 else "reaper"
		var spawn_position = state.resolve_walkable_position(pos + Vector2(cos(angle), sin(angle)) * 72.0, 18.0, pos)
		var enemy = EnemyScript.new(enemy_type, state.enemy_defs.get(enemy_type, {}), spawn_position, int(8.0 * state.enemy_hp_multiplier()), state.enemy_speed_multiplier())
		enemy.damage = int(round(float(enemy.damage) * state.enemy_damage_multiplier()))
		state.enemies.append(enemy)
		events.append({"type": "enemy_spawn", "enemy": enemy.type, "pos": enemy.position, "source": "cursed_crystal"})

func _circle_intersects_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var nearest = Vector2(clampf(center.x, rect.position.x, rect.position.x + rect.size.x), clampf(center.y, rect.position.y, rect.position.y + rect.size.y))
	return nearest.distance_to(center) <= radius

func _push_circle_out_of_rect(center: Vector2, radius: float, rect: Rect2) -> Vector2:
	if not _circle_intersects_rect(center, radius, rect):
		return center
	var nearest = Vector2(clampf(center.x, rect.position.x, rect.position.x + rect.size.x), clampf(center.y, rect.position.y, rect.position.y + rect.size.y))
	var delta = center - nearest
	if delta.length() > 0.001:
		return nearest + delta.normalized() * radius
	var left = abs(center.x - rect.position.x)
	var right = abs(rect.position.x + rect.size.x - center.x)
	var top = abs(center.y - rect.position.y)
	var bottom = abs(rect.position.y + rect.size.y - center.y)
	var min_dist = minf(minf(left, right), minf(top, bottom))
	if min_dist == left:
		center.x = rect.position.x - radius
	elif min_dist == right:
		center.x = rect.position.x + rect.size.x + radius
	elif min_dist == top:
		center.y = rect.position.y - radius
	else:
		center.y = rect.position.y + rect.size.y + radius
	return center
