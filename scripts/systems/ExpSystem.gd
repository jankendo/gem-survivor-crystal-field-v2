extends RefCounted
class_name ExpSystem

const ExpGemScript = preload("res://scripts/core/ExpGem.gd")

var level_up_system = preload("res://scripts/systems/LevelUpSystem.gd").new()

func drop_for_enemy(state, enemy, events: Array) -> void:
	if state.gems.size() >= state.max_gems():
		state.release_runtime("gem", state.gems.pop_front())
	if not enemy.boss and not enemy.elite and not state.should_drop_normal_exp():
		events.append({"type": "gem_skip", "enemy": enemy.type})
		return
	var scale = state.get_exp_drop_multiplier()
	var value = maxi(1, int(round(float(enemy.exp_value) * scale)))
	if enemy.boss:
		value += maxi(8, int(round(28.0 * scale)))
	elif enemy.type == "golem":
		value += maxi(1, int(round(4.0 * scale)))
	elif enemy.type == "elite" or enemy.elite:
		value += maxi(2, int(round(12.0 * scale)))
	var resolved: Dictionary = state.resolve_pickup_position({
		"pickup_type": "exp_gem",
		"position": enemy.position,
		"radius": 8.0,
		"origin": state.player_position,
		"rng": state.rng.stream_rng("enemy_exp_drop", "%s:%d:%d" % [enemy.type, state.kills, state.gems.size()])
	})
	if not bool(resolved.get("ok", false)):
		events.append({"type": "gem_skip", "enemy": enemy.type, "reason": "no_safe_pickup_position"})
		return
	var gem = state.acquire_gem([resolved.get("position", enemy.position), value])
	state.gems.append(gem)
	events.append({"type": "gem_drop", "pos": gem.position, "value": gem.value, "enemy": enemy.type})

func add_exp(state, amount: int, events: Array) -> void:
	if amount <= 0:
		return
	state.exp += amount
	state.gem_exp_collected += amount
	while state.exp >= state.exp_to_next:
		state.exp -= state.exp_to_next
		state.level += 1
		state.levelups_last_minute += 1
		state.refresh_exp_goal()
		if state.level_up_pending:
			state.queued_level_up_count += 1
			events.append({"type": "level_up_queued", "level": state.level, "remaining": state.queued_level_up_count})
			continue
		_open_level_up(state, events)

func _open_level_up(state, events: Array) -> void:
	state.level_up_pending = true
	state.selected_reward_index = 0
	state.level_up_options = level_up_system.prepare_options(state, 3)
	events.append({"type": "level_up", "level": state.level, "options": state.level_up_options})
	if level_up_system.should_auto_pick_infinite(state, state.level_up_options):
		level_up_system.auto_pick_infinite(state, events)

func exp_ratio(state) -> float:
	if state.exp_to_next <= 0:
		return 0.0
	return clampf(float(state.exp) / float(state.exp_to_next), 0.0, 1.0)
