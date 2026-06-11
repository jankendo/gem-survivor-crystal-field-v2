extends RefCounted
class_name MeleeRushSystem

func process(state, delta: float, events: Array = []) -> void:
	state.melee_rush_timer = maxf(0.0, state.melee_rush_timer - delta)
	state.melee_rush_flash_timer = maxf(0.0, state.melee_rush_flash_timer - delta)
	state.melee_speed_timer = maxf(0.0, state.melee_speed_timer - delta)
	if state.melee_rush_timer <= 0.0:
		state.melee_rush_level = 0

func record_kill(state, source: String, events: Array) -> void:
	if not state.weapon_has_tag(source, "melee"):
		return
	state.melee_rush_kills += 1
	if state.active_synergies.has("melee_ashura"):
		state.melee_speed_timer = maxf(state.melee_speed_timer, 1.2)
	var next_level = 0
	var duration = 0.0
	if state.melee_rush_kills >= 100:
		next_level = 3
		duration = 6.5
	elif state.melee_rush_kills >= 50:
		next_level = 2
		duration = 5.5
	elif state.melee_rush_kills >= 20:
		next_level = 1
		duration = 4.5
	if next_level > 0 and not state.melee_rush_triggered_levels.has(next_level):
		state.melee_rush_triggered_levels.append(next_level)
		state.melee_rush_level = next_level
		state.melee_rush_timer = duration
		state.melee_rush_flash_timer = 0.9
		state.add_floating_text("近接ラッシュ Lv%d!" % next_level, state.player_position + Vector2(0, -58), Color(0.45, 1.0, 0.62))
		events.append({"type": "melee_rush", "level": next_level, "duration": duration})

func effect_boost_active(state) -> bool:
	return state.melee_rush_timer > 0.0 and state.melee_rush_level >= 2
