extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const CoreScript = preload("res://scripts/systems/CorePickupChoiceSystem.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(771604, "core-choice")
	state.weapons = {
		"magic_bolt": 1,
		"ice_orbit": 1,
		"thunder_chain": 1,
		"bomb_seed": 1,
		"poison_mist": 1
	}
	for id in state.weapons.keys():
		state.weapons[id] = int(state.weapon_defs.get(id, {}).get("max_level", 8))
	if not state.unlocked_weapon_ids.has("soul_scythe"):
		state.unlocked_weapon_ids.append("soul_scythe")
	var system = CoreScript.new()
	var events: Array = []
	t.assert_true(system.open_choice(state, "weapon", {"id": "weapon_core", "position": state.player_position}, events), "weapon core should open a visible choice")
	t.assert_true(state.level_up_pending and not state.pending_core_choice.is_empty(), "core choice should pause into a selection UI")
	var option = _first_over_cap_option(state.level_up_options)
	t.assert_true(not option.is_empty(), "core choice should include an unlocked over-cap equipment option")
	t.assert_true(String(option.get("description_ja", "")).find("枠超過") >= 0, "core option should explain over-cap pickup")
	t.assert_true(system.accept_current(state, String(option.get("uid", "")), events), "core option should be acquirable")
	t.assert_true(state.weapons.size() >= 6, "core pickup should allow 6/5 weapon count")
	t.assert_true(state.field_over_cap_pickups >= 1, "over-cap source should be tracked")

func _first_over_cap_option(options: Array) -> Dictionary:
	for option in options:
		if String(option.get("kind", "")) == "decline":
			continue
		if String(option.get("description_ja", "")).find("枠超過") >= 0:
			return option
	return {}
