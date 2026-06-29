extends RefCounted
class_name FieldGimmickSystem

const ChestScript = preload("res://scripts/core/Chest.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
var availability = preload("res://scripts/systems/FieldObjectAvailabilitySystem.gd").new()

func process(state, delta: float, events: Array) -> void:
	for gimmick in state.field_gimmicks:
		if not availability.is_available_now(state, gimmick, "destroyed"):
			continue
		gimmick["cooldown"] = maxf(0.0, float(gimmick.get("cooldown", 0.0)) - delta)
		match String(gimmick.get("id", "")):
			"healing_spring":
				_process_healing_spring(state, gimmick, events)
			"spawn_rift":
				_process_spawn_rift(state, gimmick, events)
			"sealed_chest_pillar":
				_process_sealed_chest_pillar(state, gimmick, events)

func damage_gimmicks_in_radius(state, pos: Vector2, radius: float, damage: int, events: Array, source: String) -> int:
	var hits = 0
	for gimmick in state.field_gimmicks:
		if not availability.is_available_now(state, gimmick, "destroyed"):
			continue
		var gpos: Vector2 = gimmick.get("position", Vector2.ZERO)
		if gpos.distance_to(pos) > radius + float(gimmick.get("radius", 36.0)):
			continue
		hits += 1
		_damage_gimmick(state, gimmick, damage, events, source)
	return hits

func reflect_projectile_if_needed(state, projectile, events: Array) -> bool:
	if projectile.velocity.length() <= 0.1:
		return false
	for gimmick in state.field_gimmicks:
		if String(gimmick.get("id", "")) != "reflect_crystal" or not availability.is_available_now(state, gimmick, "destroyed"):
			continue
		var gpos: Vector2 = gimmick.get("position", Vector2.ZERO)
		if projectile.position.distance_to(gpos) <= float(gimmick.get("radius", 36.0)) + projectile.radius:
			var normal = (projectile.position - gpos).normalized()
			if normal == Vector2.ZERO:
				normal = Vector2.RIGHT
			projectile.velocity = projectile.velocity.bounce(normal)
			projectile.position = gpos + normal * (float(gimmick.get("radius", 36.0)) + projectile.radius + 3.0)
			state.add_hit_flash({"pos": projectile.position, "life": 0.18, "source": "mirror_shard"})
			events.append({"type": "gimmick_reflect", "id": "reflect_crystal", "pos": gpos})
			_mark_activated(state, gimmick, events)
			return true
	return false

func _damage_gimmick(state, gimmick: Dictionary, damage: int, events: Array, source: String) -> void:
	var id = String(gimmick.get("id", ""))
	if id == "healing_spring":
		return
	gimmick["hp"] = int(gimmick.get("hp", 1)) - damage
	state.add_hit_flash({"pos": gimmick.get("position", Vector2.ZERO), "life": 0.18, "source": source})
	events.append({"type": "gimmick_hit", "id": id, "hp": gimmick["hp"], "pos": gimmick.get("position", Vector2.ZERO)})
	if int(gimmick.get("hp", 0)) > 0:
		return
	gimmick["destroyed"] = true
	state.field_gimmicks_triggered += 1
	var pos: Vector2 = gimmick.get("position", Vector2.ZERO)
	match id:
		"explosive_vein":
			_explode_vein(state, pos, events)
		"spawn_rift":
			state.add_score(750, pos)
			events.append({"type": "gimmick_destroyed", "id": id, "pos": pos})
		"sealed_chest_pillar":
			_open_pillar_reward(state, gimmick, events)
		_:
			state.add_score(250, pos)
			events.append({"type": "gimmick_destroyed", "id": id, "pos": pos})

func _process_healing_spring(state, gimmick: Dictionary, events: Array) -> void:
	if float(gimmick.get("cooldown", 0.0)) > 0.0:
		return
	var pos: Vector2 = gimmick.get("position", Vector2.ZERO)
	if pos.distance_to(state.player_position) <= 105.0 and state.hp < state.max_hp:
		var heal = maxi(3, int(round(float(state.max_hp) * 0.035)))
		state.hp = mini(state.max_hp, state.hp + heal)
		gimmick["cooldown"] = 3.0
		state.add_floating_text("+%d HP" % heal, pos, Color(0.42, 1.0, 0.62))
		events.append({"type": "gimmick_heal", "id": "healing_spring", "amount": heal, "pos": pos})
		_mark_activated(state, gimmick, events)

func _process_spawn_rift(state, gimmick: Dictionary, events: Array) -> void:
	if float(gimmick.get("cooldown", 0.0)) > 0.0:
		return
	var pos: Vector2 = gimmick.get("position", Vector2.ZERO)
	if pos.distance_to(state.player_position) > 900.0:
		return
	gimmick["cooldown"] = 8.0
	for i in range(2):
		if state.enemies.size() >= state.max_enemies():
			return
		var angle = TAU * float(i) / 2.0 + state.rng.range_float(-0.3, 0.3)
		var enemy_type = "ghost" if state.elapsed_seconds < 900.0 else "reaper"
		var spawn_position = state.resolve_walkable_position(pos + Vector2(cos(angle), sin(angle)) * 60.0, 18.0, pos)
		var enemy = EnemyScript.new(enemy_type, state.enemy_defs.get(enemy_type, {}), spawn_position, int(6.0 * state.enemy_hp_multiplier()), state.enemy_speed_multiplier())
		enemy.damage = int(round(float(enemy.damage) * state.enemy_damage_multiplier()))
		state.enemies.append(enemy)
	events.append({"type": "gimmick_spawn", "id": "spawn_rift", "pos": pos})
	_mark_activated(state, gimmick, events)

func _process_sealed_chest_pillar(state, gimmick: Dictionary, events: Array) -> void:
	if bool(gimmick.get("opened", false)):
		return
	var pos: Vector2 = gimmick.get("position", Vector2.ZERO)
	if pos.distance_to(state.player_position) > 260.0:
		return
	var nearby = 0
	for enemy in state.enemies:
		if enemy.position.distance_to(pos) <= 260.0:
			nearby += 1
	if nearby <= 0:
		_open_pillar_reward(state, gimmick, events)

func _open_pillar_reward(state, gimmick: Dictionary, events: Array) -> void:
	if bool(gimmick.get("opened", false)):
		return
	gimmick["opened"] = true
	var pos: Vector2 = gimmick.get("position", Vector2.ZERO)
	var rarity = "evolution" if state.has_available_evolution() else "normal"
	var resolved: Dictionary = state.resolve_pickup_position({
		"pickup_type": "chest",
		"position": pos,
		"radius": 28.0,
		"origin": state.player_position,
		"rng": state.rng.stream_rng("sealed_pillar_chest", state.field_gimmicks_triggered)
	})
	if bool(resolved.get("ok", false)) and state.add_chest(ChestScript.new(resolved.get("position", pos), rarity, "sealed_pillar")):
		events.append({"type": "chest_drop", "pos": resolved.get("position", pos), "source": "sealed_pillar", "rarity": rarity})
	state.field_gimmicks_triggered += 1
	state.add_floating_text("封印解除！", pos, Color(1.0, 0.86, 0.28))
	events.append({"type": "gimmick_open", "id": "sealed_chest_pillar", "pos": pos})

func _explode_vein(state, pos: Vector2, events: Array) -> void:
	var radius = 170.0
	var damage = 42 + int(state.elapsed_minutes() * 4.0)
	for enemy in state.enemies.duplicate():
		if enemy.position.distance_to(pos) <= radius + enemy.radius:
			enemy.hp -= damage
			state.record_damage(damage)
			if enemy.hp <= 0:
				state.enemies.erase(enemy)
				state.kills += 1
				state.add_score(enemy.score, enemy.position)
	state.add_hit_flash({"pos": pos, "life": 0.42, "source": "explosive_vein", "radius": radius})
	events.append({"type": "gimmick_explosion", "id": "explosive_vein", "pos": pos, "radius": radius})

func _mark_activated(state, gimmick: Dictionary, events: Array) -> void:
	if bool(gimmick.get("triggered", false)):
		return
	gimmick["triggered"] = true
	state.field_gimmicks_triggered += 1
	events.append({"type": "gimmick_activated", "id": gimmick.get("id", ""), "pos": gimmick.get("position", Vector2.ZERO)})
