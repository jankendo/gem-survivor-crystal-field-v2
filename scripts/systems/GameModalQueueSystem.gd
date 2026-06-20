extends RefCounted
class_name GameModalQueueSystem

func queue_level_up(state) -> void:
	state.queued_level_up_count += 1

func can_open_modal(state) -> bool:
	if state.game_over or state.paused or state.chest_pending or state.rune_contract_pending:
		return false
	if state.level_up_pending:
		return false
	if not state.pending_core_choice.is_empty() or not state.pending_field_equipment_choice.is_empty():
		return false
	if bool(state.character_evolution_pending):
		return false
	return true

func open_next_level_up(state, events: Array, level_up_system) -> bool:
	if state.queued_level_up_count <= 0 or not can_open_modal(state):
		return false
	state.queued_level_up_count -= 1
	state.level_up_pending = true
	state.selected_reward_index = 0
	state.level_up_options = level_up_system.prepare_options(state, 3)
	events.append({
		"type": "level_up",
		"level": state.level,
		"options": state.level_up_options,
		"queued": true,
		"remaining": state.queued_level_up_count
	})
	if level_up_system.should_auto_pick_infinite(state, state.level_up_options):
		level_up_system.auto_pick_infinite(state, events)
	return true
