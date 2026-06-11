extends RefCounted
class_name PickupSystem

const ProjectileScript = preload("res://scripts/core/Projectile.gd")

var exp_system = preload("res://scripts/systems/ExpSystem.gd").new()

func process_gems(state, delta: float, events: Array) -> void:
	state.pickup_combo_timer = maxf(0.0, state.pickup_combo_timer - delta)
	if state.pickup_combo_timer <= 0.0 and state.pickup_combo_count > 0:
		state.pickup_combo_count = 0
		state.combo_thresholds_hit = {}
	var magnet_radius = state.get_magnet_radius()
	for gem in state.gems.duplicate():
		var distance = gem.position.distance_to(state.player_position)
		if distance <= magnet_radius:
			gem.attracting = true
		if gem.attracting:
			var direction = (state.player_position - gem.position).normalized()
			var pull = 540.0 + maxf(0.0, magnet_radius - distance) * 7.5
			gem.velocity = gem.velocity.lerp(direction * pull, minf(1.0, delta * 9.5))
			gem.position += gem.velocity * delta
		if gem.position.distance_to(state.player_position) <= 19.0:
			_collect_gem(state, gem, events)

func _collect_gem(state, gem, events: Array) -> void:
	if not state.gems.has(gem):
		return
	state.gems.erase(gem)
	state.gems_collected += 1
	state.gem_turret_charge = mini(999, state.gem_turret_charge + 1)
	state.pickup_combo_count += 1
	state.max_combo = maxi(state.max_combo, state.pickup_combo_count)
	state.pickup_combo_timer = state.combo_timeout()
	_handle_combo_thresholds(state, events)
	var value = int(round(float(gem.value) * state.get_gem_value_multiplier(gem.position) * state.get_combo_exp_multiplier()))
	value = maxi(1, value)
	exp_system.add_exp(state, value, events)
	var pickup_score = int(round(float(value) * 2.0 * state.get_combo_score_multiplier()))
	state.add_score(pickup_score, gem.position)
	_apply_pickup_heal(state, events)
	_apply_gem_engine(state, events)
	events.append({"type": "gem_collect", "value": value, "combo": state.pickup_combo_count, "exp": state.exp})

func _handle_combo_thresholds(state, events: Array) -> void:
	var thresholds = [10, 25, 50, 100, 200, 250]
	for threshold in thresholds:
		var key = str(threshold)
		if state.pickup_combo_count >= threshold and not state.combo_thresholds_hit.has(key):
			state.combo_thresholds_hit[key] = true
			if threshold >= 25:
				state.combo_magnet_timer = maxf(state.combo_magnet_timer, 1.4 + float(threshold) / 100.0)
			if threshold >= 100:
				_pull_nearby_gems(state, 360.0 if threshold == 100 else 620.0)
			if threshold == int(state.balance_data.get("gem_fever_small_combo", 100)):
				_start_gem_fever(state, 1, float(state.balance_data.get("gem_fever_small_duration", 5.0)), events)
			elif threshold == int(state.balance_data.get("gem_fever_big_combo", 250)):
				_start_gem_fever(state, 2, float(state.balance_data.get("gem_fever_big_duration", 8.0)), events)
			state.message = "%d吸収コンボ！" % threshold
			events.append({"type": "combo_milestone", "combo": threshold, "message": state.message})

func _start_gem_fever(state, tier: int, duration: float, events: Array) -> void:
	state.gem_fever_tier = tier
	state.gem_fever_timer = duration
	state.message = "ジェムフィーバー！"
	if tier >= 2:
		_pull_nearby_gems(state, 1400.0)
	events.append({"type": "gem_fever", "tier": tier, "duration": duration})

func _pull_nearby_gems(state, radius: float) -> void:
	for gem in state.gems:
		if gem.position.distance_to(state.player_position) <= radius:
			gem.attracting = true

func _apply_pickup_heal(state, events: Array) -> void:
	var heal_level = int(state.passives.get("pickup_heal", 0))
	if heal_level <= 0:
		return
	var interval = maxi(6, 12 - heal_level)
	if state.gems_collected % interval != 0:
		return
	if state.hp >= state.max_hp:
		return
	var heal = mini(4, 1 + heal_level)
	state.hp = mini(state.max_hp, state.hp + heal)
	state.add_floating_text("+%d HP" % heal, state.player_position + Vector2(0, -34), Color(0.42, 1.0, 0.52))
	events.append({"type": "player_heal", "amount": heal, "source": "pickup", "hp": state.hp})

func _apply_gem_engine(state, events: Array) -> void:
	if not state.active_synergies.has("gem_engine"):
		return
	var chance = float(state.active_synergies["gem_engine"].get("effects", {}).get("gem_shot_chance", 0.12))
	if not state.rng.chance(chance):
		return
	var target = null
	var best_dist = 620.0
	for enemy in state.enemies:
		var distance = enemy.position.distance_to(state.player_position)
		if distance < best_dist:
			target = enemy
			best_dist = distance
	if target == null:
		return
	var dir = (target.position - state.player_position).normalized()
	var damage = maxi(2, int(round(6.0 * state.get_damage_multiplier_for_weapon("gem_turret"))))
	state.projectiles.append(ProjectileScript.new("gem_turret", state.player_position + dir * 18.0, dir * 680.0, damage, 0, 1.0, 8.0, 0.0, false))
	events.append({"type": "gem_engine_shot", "pos": state.player_position})
