extends RefCounted
class_name ExpSystem

const ExpGemScript = preload("res://scripts/core/ExpGem.gd")

var level_up_system = preload("res://scripts/systems/LevelUpSystem.gd").new()

func drop_for_enemy(state, enemy, events: Array) -> void:
	if state.gems.size() >= state.max_gems():
		state.gems.pop_front()
	if not enemy.boss and not enemy.elite and not state.should_drop_normal_exp():
		events.append({"type": "gem_skip", "enemy": enemy.type})
		return
	var scale = state.get_exp_drop_multiplier()
	var value = maxi(1, int(round(float(enemy.exp_value) * scale)))
	if state.elapsed_seconds < 90.0 and state.level <= 1 and not enemy.elite and not enemy.boss:
		value = maxi(12, value)
	elif state.elapsed_seconds < 90.0 and not enemy.elite and not enemy.boss:
		value = maxi(4, value)
	elif state.elapsed_seconds < 180.0 and not enemy.elite and not enemy.boss:
		value = maxi(2, value)
	if enemy.boss:
		value += maxi(8, int(round(28.0 * scale)))
	elif enemy.type == "golem":
		value += maxi(1, int(round(4.0 * scale)))
	elif enemy.type == "elite" or enemy.elite:
		value += maxi(2, int(round(12.0 * scale)))
	var gem = ExpGemScript.new(enemy.position, value)
	state.gems.append(gem)
	events.append({"type": "gem_drop", "pos": gem.position, "value": gem.value, "enemy": enemy.type})

func add_exp(state, amount: int, events: Array) -> void:
	if amount <= 0:
		return
	state.exp += amount
	state.gem_exp_collected += amount
	while state.exp >= state.exp_to_next and not state.level_up_pending:
		state.exp -= state.exp_to_next
		state.level += 1
		state.levelups_last_minute += 1
		state.refresh_exp_goal()
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
