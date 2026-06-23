extends RefCounted
class_name ChestSystem

const ChestScript = preload("res://scripts/core/Chest.gd")
const ExpGemScript = preload("res://scripts/core/ExpGem.gd")

var evolution_system = preload("res://scripts/systems/EvolutionSystem.gd").new()
var overclock_system = preload("res://scripts/systems/OverclockSystem.gd").new()

func drop_chest(state, pos: Vector2, events: Array, rarity: String = "normal", source: String = "") -> bool:
	var chosen_rarity = _resolve_rarity(state, rarity, source)
	var resolved: Dictionary = state.resolve_pickup_position({
		"pickup_type": "chest",
		"position": pos,
		"radius": 28.0,
		"origin": state.player_position,
		"rng": state.rng.stream_rng("chest_drop", "%s:%d" % [source, state.chests.size()])
	})
	if not bool(resolved.get("ok", false)):
		events.append({"type": "chest_skip", "pos": pos, "reason": "no_safe_pickup_position", "rarity": chosen_rarity, "source": source})
		return false
	var safe_pos: Vector2 = resolved.get("position", pos)
	var chest = ChestScript.new(safe_pos, chosen_rarity, source)
	chest.ttl = float(state.balance_data.get("chest_ttl_seconds", 300.0))
	if not state.add_chest(chest):
		events.append({"type": "chest_skip", "pos": safe_pos, "reason": "cap", "rarity": chosen_rarity, "source": source})
		return false
	events.append({"type": "chest_drop", "pos": safe_pos, "rarity": chosen_rarity, "source": source})
	return true

func process_pickups(state, events: Array, delta: float = 0.0) -> void:
	for chest in state.chests.duplicate():
		chest.pulse += maxf(delta, 0.05)
		chest.age += delta
		if chest.age >= chest.ttl:
			state.chests.erase(chest)
			_drop_expired_big_gem(state, chest.position, events)
			continue
		if chest.position.distance_to(state.player_position) <= 32.0:
			state.chests.erase(chest)
			open_chest(state, events, chest.rarity)

func open_chest(state, events: Array, rarity: String = "normal") -> void:
	state.chests_opened += 1
	state.chest_pending = false
	state.chest_timer = 0.0
	state.chest_notice_timer = 2.0
	if rarity == "cursed":
		state.cursed_power *= 1.08
		state.add_score(900)
		events.append({"type": "cursed_chest", "power": state.cursed_power})
	if rarity in ["evolution", "golden", "normal", "cursed"] and evolution_system.apply_first_available_evolution(state, events):
		state.chest_pending = true
		state.chest_timer = 0.5
		var last_name = String(events[events.size() - 1].get("name", "進化武器")) if not events.is_empty() else "進化武器"
		state.chest_message = "宝箱！\n%sを獲得" % last_name
		events.append({"type": "chest_open", "message": state.chest_message, "result": "evolution", "rarity": rarity})
		return
	if rarity in ["overclock", "golden", "cursed"] and _apply_random_overclock(state, events):
		state.chest_pending = true
		state.chest_timer = 0.5
		state.chest_message = "過充電宝箱！\n%s" % String(events[events.size() - 1].get("name", "過充電"))
		events.append({"type": "chest_open", "message": state.chest_message, "result": "overclock", "rarity": rarity})
		return
	var candidates: Array = []
	for id in state.weapons.keys():
		var weapon_id = String(id)
		if state.is_weapon_evolved(weapon_id):
			continue
		if int(state.weapons[weapon_id]) < int(state.weapon_defs[weapon_id].get("max_level", 8)):
			candidates.append({"kind": "weapon", "id": weapon_id})
	for id in state.passives.keys():
		var passive_id = String(id)
		if int(state.passives[passive_id]) < int(state.passive_defs[passive_id].get("max_level", 5)):
			candidates.append({"kind": "passive", "id": passive_id})
	if candidates.is_empty():
		state.add_score(500)
		state.chest_message = "宝箱！\nスコア +500"
		events.append({"type": "chest_open", "message": state.chest_message, "result": "score", "rarity": rarity})
		return
	var repeats = 2 if rarity == "golden" else 1
	var last_name = ""
	for i in range(repeats):
		if candidates.is_empty():
			break
		var chosen: Dictionary = state.rng.choice(candidates)
		var kind = String(chosen.get("kind", "weapon"))
		var id = String(chosen.get("id", "magic_bolt"))
		var before = int(state.weapons.get(id, state.passives.get(id, 0)))
		if kind == "weapon":
			state.weapons[id] = before + 1
			last_name = "%s Lv%d → Lv%d" % [state.weapon_name(id), before, before + 1]
		else:
			state.passives[id] = before + 1
			last_name = "%s Lv%d → Lv%d" % [state.passive_name(id), before, before + 1]
			if id == "max_hp":
				state.max_hp += 18
				state.hp = mini(state.max_hp, state.hp + 18)
		_remove_candidate(candidates, kind, id)
	state.chest_message = "宝箱！\n%s" % last_name
	if rarity == "golden":
		state.chest_pending = true
		state.chest_timer = 0.5
	events.append({"type": "chest_open", "message": state.chest_message, "result": "upgrade", "rarity": rarity})

func _resolve_rarity(state, requested: String, source: String) -> String:
	if requested != "" and requested != "normal":
		return requested
	if source == "boss":
		if state.has_available_evolution():
			return "evolution"
		if state.has_available_overclock():
			return "overclock"
		return "golden" if state.rng.chance(0.08 + state.rare_reward_bonus()) else "normal"
	if source == "elite":
		return "overclock" if state.has_available_overclock() and state.rng.chance(0.18 + state.rare_reward_bonus()) else "normal"
	if source == "crystal":
		return "golden" if state.rng.chance(0.02 + state.rare_reward_bonus() * 0.25) else "normal"
	return requested

func _apply_random_overclock(state, events: Array) -> bool:
	var options = overclock_system.make_options(state, 3)
	if options.is_empty():
		return false
	var option: Dictionary = state.rng.choice(options)
	return overclock_system.apply_option(state, String(option.get("weapon", "")), String(option.get("id", "")), events)

func _drop_expired_big_gem(state, pos: Vector2, events: Array) -> void:
	if state.gems.size() >= state.max_gems():
		state.gems.pop_front()
	var resolved: Dictionary = state.resolve_pickup_position({
		"pickup_type": "exp_gem",
		"position": pos,
		"radius": 8.0,
		"origin": state.player_position,
		"rng": state.rng.stream_rng("expired_chest_gem", state.chests_opened)
	})
	if not bool(resolved.get("ok", false)):
		events.append({"type": "chest_expired", "pos": pos, "gem_value": 0, "reason": "no_safe_pickup_position"})
		return
	var gem = ExpGemScript.new(resolved.get("position", pos), 35 + int(state.elapsed_minutes() * 2.0))
	state.gems.append(gem)
	events.append({"type": "chest_expired", "pos": pos, "gem_value": gem.value})

func _remove_candidate(candidates: Array, kind: String, id: String) -> void:
	for i in range(candidates.size() - 1, -1, -1):
		if String(candidates[i].get("kind", "")) == kind and String(candidates[i].get("id", "")) == id:
			candidates.remove_at(i)
