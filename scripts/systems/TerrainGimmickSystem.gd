extends RefCounted
class_name TerrainGimmickSystem

func process(state, delta: float, events: Array) -> void:
	state.terrain_time[state.current_terrain_id] = float(state.terrain_time.get(state.current_terrain_id, 0.0)) + delta
	if state.current_terrain_id != "healing_oasis" or state.hp >= state.max_hp:
		state.terrain_heal_meter = 0.0
		return
	state.terrain_heal_meter += delta
	var tick_seconds = float(state.balance_data.get("healing_oasis_tick_seconds", 2.5))
	if state.terrain_heal_meter < tick_seconds:
		return
	state.terrain_heal_meter -= tick_seconds
	var healing_multiplier = minf(1.35, state.modifier_mult("healing_mult", 1.0))
	var heal = mini(6, maxi(1, int(round((2.0 + float(state.passives.get("terrain_core", 0))) * healing_multiplier))))
	state.hp = mini(state.max_hp, state.hp + heal)
	state.oasis_healing += heal
	state.add_floating_text("+%d 泉" % heal, state.player_position + Vector2(0, -38), Color(0.38, 1.0, 0.72))
	events.append({"type": "player_heal", "amount": heal, "source": "healing_oasis", "hp": state.hp})
