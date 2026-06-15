extends RefCounted
class_name LevelUpSystem

var overclock_system = preload("res://scripts/systems/OverclockSystem.gd").new()
var rune_contract_system = preload("res://scripts/systems/RuneContractSystem.gd").new()
var build_synergy_system = preload("res://scripts/systems/BuildSynergySystem.gd").new()

func prepare_options(state, count: int = 3) -> Array:
	var weighted: Array = []
	for id in state.weapon_defs.keys():
		var weapon_id = String(id)
		if not state.can_offer_weapon(weapon_id):
			continue
		var current = int(state.weapons.get(weapon_id, 0))
		var weight = 42.0 if current > 0 else 9.0
		if _is_evolution_ready(state, weapon_id):
			weight *= 3.0
		elif _is_evolution_near(state, weapon_id, current + 1):
			weight *= 2.3
		weighted.append({"id": weapon_id, "kind": "weapon", "weight": weight})
	for id in state.passive_defs.keys():
		var passive_id = String(id)
		if not state.can_offer_passive(passive_id):
			continue
		var current = int(state.passives.get(passive_id, 0))
		var weight = 30.0 if current > 0 else 18.0
		if _is_passive_evolution_material(state, passive_id):
			weight *= 1.8
		weighted.append({"id": passive_id, "kind": "passive", "weight": weight})
	var options: Array = []
	var used: Array = []
	while options.size() < count and not weighted.is_empty():
		var chosen = state.rng.weighted_choice(weighted)
		var id = String(chosen.get("id", ""))
		var kind = String(chosen.get("kind", ""))
		if id == "":
			break
		var key = "%s:%s" % [kind, id]
		if used.has(key):
			_remove_weighted(weighted, kind, id)
			continue
		used.append(key)
		options.append(_make_option(state, kind, id))
		_remove_weighted(weighted, kind, id)
	if state.elapsed_seconds >= 1200.0 and state.has_available_overclock() and options.size() < count:
		for option in overclock_system.make_options(state, count - options.size()):
			options.append(option)
	if not has_regular_candidates(state) or options.size() < count:
		_fill_infinite_options(state, options, used, count)
	return options

func has_regular_candidates(state) -> bool:
	for id in state.weapon_defs.keys():
		if state.can_offer_weapon(String(id)):
			return true
	for id in state.passive_defs.keys():
		if state.can_offer_passive(String(id)):
			return true
	return false

func options_are_infinite_only(options: Array) -> bool:
	if options.is_empty():
		return false
	for option in options:
		if String(option.get("kind", "")) != "infinite":
			return false
	return true

func should_auto_pick_infinite(state, options: Array) -> bool:
	if not state.auto_infinite_enabled:
		return false
	if has_regular_candidates(state):
		return false
	if state.has_available_evolution():
		return false
	return options_are_infinite_only(options)

func auto_pick_infinite(state, events: Array) -> bool:
	if state.level_up_options.is_empty():
		return false
	var option = _best_infinite_option(state, state.level_up_options)
	if option.is_empty():
		return false
	var ok = apply_option(state, String(option.get("uid", "")), events)
	if ok:
		state.auto_infinite_count += 1
		events.append({"type": "auto_infinite", "id": option.get("id", ""), "name": option.get("name_ja", ""), "description": option.get("description_ja", "")})
	return ok

func apply_option(state, option_uid: String, events: Array) -> bool:
	var option = _find_option(state.level_up_options, option_uid)
	if option.is_empty():
		return false
	var kind = String(option.get("kind", ""))
	var id = String(option.get("id", ""))
	var next_level = int(option.get("next_level", 1))
	if kind == "weapon":
		if int(state.weapons.get(id, 0)) <= 0 and state.weapons.keys().size() >= state.max_owned_weapons():
			return false
		state.weapons[id] = next_level
		state.weapon_pick_counts[id] = int(state.weapon_pick_counts.get(id, 0)) + 1
	elif kind == "passive":
		if int(state.passives.get(id, 0)) <= 0 and state.passives.keys().size() >= state.max_owned_passives():
			return false
		state.passives[id] = next_level
		state.passive_pick_counts[id] = int(state.passive_pick_counts.get(id, 0)) + 1
		if id == "max_hp":
			state.max_hp += 18
			state.hp = mini(state.max_hp, state.hp + 18)
	elif kind == "infinite":
		state.infinite_upgrades[id] = int(state.infinite_upgrades.get(id, 0)) + 1
		if id == "infinite_hp":
			state.max_hp += 10
			state.hp = mini(state.max_hp, state.hp + 10)
	elif kind == "overclock":
		if not overclock_system.apply_option(state, String(option.get("weapon", "")), id, events):
			return false
	elif kind == "contract":
		return rune_contract_system.apply_contract(state, id, events)
	elif kind == "contract_skip":
		return rune_contract_system.apply_contract(state, "skip", events)
	else:
		return false
	state.level_up_pending = false
	state.level_up_options = []
	if kind == "infinite":
		state.message = "%s Lv%d" % [String(option.get("name_ja", "")), int(state.infinite_upgrades.get(id, next_level))]
	elif kind == "overclock":
		state.message = "%s" % String(option.get("name_ja", "過充電"))
	else:
		state.message = "%s Lv%d" % [String(option.get("name_ja", "")), next_level]
	events.append({"type": "reward_select", "kind": kind, "id": id, "level": next_level, "name": option.get("name_ja", "")})
	return true

func _best_infinite_option(state, options: Array) -> Dictionary:
	var priority = ["infinite_damage", "infinite_speed", "infinite_area", "infinite_magnet", "infinite_hp", "infinite_greed"]
	if state.hp_ratio() <= 0.30:
		priority = ["infinite_hp", "infinite_damage", "infinite_speed", "infinite_magnet", "infinite_area", "infinite_greed"]
	elif state.gems_collected < maxi(8, int(float(state.kills) * 0.45)):
		priority = ["infinite_magnet", "infinite_damage", "infinite_speed", "infinite_area", "infinite_hp", "infinite_greed"]
	elif state.enemies.size() > 90:
		priority = ["infinite_damage", "infinite_speed", "infinite_area", "infinite_hp", "infinite_magnet", "infinite_greed"]
	for id in priority:
		for option in options:
			if String(option.get("id", "")) == id:
				return option
	return options[0] if not options.is_empty() else {}

func _fill_infinite_options(state, options: Array, used: Array, count: int) -> void:
	var infinite_ids: Array = state.infinite_defs.keys()
	infinite_ids = state.rng.shuffled(infinite_ids)
	for raw_id in infinite_ids:
		if options.size() >= count:
			return
		var id = String(raw_id)
		var key = "infinite:%s" % id
		if used.has(key):
			continue
		used.append(key)
		options.append(_make_option(state, "infinite", id))
	while options.size() < count and not infinite_ids.is_empty():
		for raw_id in infinite_ids:
			if options.size() >= count:
				return
			var id = String(raw_id)
			var duplicate_in_screen = false
			for option in options:
				if String(option.get("kind", "")) == "infinite" and String(option.get("id", "")) == id:
					duplicate_in_screen = true
					break
			if not duplicate_in_screen:
				options.append(_make_option(state, "infinite", id))

func _make_option(state, kind: String, id: String) -> Dictionary:
	var current = 0
	var name = ""
	var description = ""
	var type_label = ""
	var type_color = ""
	var hint = ""
	if kind == "weapon":
		current = int(state.weapons.get(id, 0))
		name = state.weapon_name(id)
		description = _weapon_description(state, id, current + 1)
		type_label = "武器"
		type_color = "weapon"
		hint = _weapon_evolution_hint(state, id, current + 1)
		if _is_evolution_ready(state, id):
			hint = "宝箱で進化可能"
		elif _is_evolution_near(state, id, current + 1):
			hint = "進化まであと少し / %s" % hint
	elif kind == "passive":
		current = int(state.passives.get(id, 0))
		name = state.passive_name(id)
		description = String(state.passive_defs[id].get("description_ja", "強化"))
		type_label = "パッシブ"
		type_color = "passive"
		if _is_passive_evolution_material(state, id):
			hint = _passive_evolution_hint(state, id, current + 1)
	else:
		current = int(state.infinite_upgrades.get(id, 0))
		name = String(state.infinite_defs[id].get("name_ja", id))
		description = String(state.infinite_defs[id].get("description_ja", "限界を超えて強化"))
		type_label = "無限"
		type_color = "infinite"
	var synergy_name = build_synergy_system.would_complete_synergy(state, kind, id)
	if synergy_name != "":
		hint = "ビルド完成：%s%s%s" % [synergy_name, " / " if hint != "" else "", hint]
	return {
		"uid": "%s:%s" % [kind, id],
		"kind": kind,
		"id": id,
		"name_ja": name,
		"next_level": current + 1,
		"description_ja": description,
		"type_label": type_label,
		"type_color": type_color,
		"evolution_hint": hint,
		"evolution_state": _evolution_state_for_option(state, kind, id, current + 1)
	}

func _find_option(options: Array, uid: String) -> Dictionary:
	for option in options:
		if String(option.get("uid", "")) == uid:
			return option
	return {}

func _remove_weighted(weighted: Array, kind: String, id: String) -> void:
	for i in range(weighted.size() - 1, -1, -1):
		if String(weighted[i].get("id", "")) == id and String(weighted[i].get("kind", "")) == kind:
			weighted.remove_at(i)

func _weapon_description(state, id: String, next_level: int) -> String:
	var base = String(state.weapon_defs.get(id, {}).get("description_ja", "武器強化"))
	if next_level <= 1:
		return base
	if next_level == 3 or next_level == 6:
		return "%s / 弾数・判定が強化" % base
	if next_level == 5:
		return "%s / 貫通・範囲が強化" % base
	if next_level >= 8:
		return "%s / 最大Lv。宝箱進化の準備完了" % base
	return "%s / 威力と回転率UP" % base

func _weapon_evolution_hint(state, id: String, next_level: int = 0) -> String:
	var evolution = state.evolution_for_weapon(id)
	if evolution.is_empty():
		return ""
	var passive_id = String(evolution.get("passive", ""))
	var passive_name = state.passive_name(passive_id)
	var passive_level = int(evolution.get("passive_level", 1))
	var current_passive = int(state.passives.get(passive_id, 0))
	var weapon_level = int(evolution.get("weapon_level", 8))
	var current_weapon = maxi(int(state.weapons.get(id, 0)), next_level)
	var shortage: Array = []
	if current_weapon < weapon_level:
		shortage.append("%s あと%dLv" % [state.weapon_name(id), weapon_level - current_weapon])
	if current_passive < passive_level:
		shortage.append("%s Lv%d / あと%dLv" % [passive_name, current_passive, passive_level - current_passive])
	var status = "宝箱で進化可能" if shortage.is_empty() else " / ".join(shortage)
	return "進化先：%s / 必要：%s Lv%d + 宝箱 / 状態：%s" % [
		String(evolution.get("name_ja", "")),
		passive_name,
		passive_level,
		status
	]

func _passive_evolution_hint(state, id: String, next_level: int = 0) -> String:
	var lines: Array = ["進化素材："]
	for evolution_id in state.evolution_defs.keys():
		var evolution: Dictionary = state.evolution_defs[evolution_id]
		if String(evolution.get("passive", "")) != id:
			continue
		var weapon_id = String(evolution.get("weapon", ""))
		var required_passive = int(evolution.get("passive_level", 1))
		var required_weapon = int(evolution.get("weapon_level", 8))
		var passive_level = maxi(int(state.passives.get(id, 0)), next_level)
		var weapon_level = int(state.weapons.get(weapon_id, 0))
		var status = "宝箱で進化可能" if passive_level >= required_passive and weapon_level >= required_weapon else "%s Lv%d / %s Lv%d" % [
			state.weapon_name(weapon_id),
			weapon_level,
			state.passive_name(id),
			passive_level
		]
		lines.append("%s → %s / %s" % [state.weapon_name(weapon_id), String(evolution.get("name_ja", evolution_id)), status])
	return "\n".join(lines)

func _evolution_state_for_option(state, kind: String, id: String, next_level: int) -> String:
	if kind == "weapon":
		if state.is_weapon_evolved(id):
			return "evolved"
		if _is_evolution_ready(state, id):
			return "ready"
		if _is_evolution_near(state, id, next_level):
			return "near"
		if not state.evolution_for_weapon(id).is_empty():
			return "material"
	elif kind == "passive" and _is_passive_evolution_material(state, id):
		var hint = _passive_evolution_hint(state, id, next_level)
		return "ready" if hint.find("宝箱で進化可能") >= 0 else "material"
	return "none"

func _is_evolution_ready(state, id: String) -> bool:
	var evolution = state.evolution_for_weapon(id)
	if evolution.is_empty():
		return false
	var passive_id = String(evolution.get("passive", ""))
	return int(state.weapons.get(id, 0)) >= int(evolution.get("weapon_level", 8)) and int(state.passives.get(passive_id, 0)) >= int(evolution.get("passive_level", 1))

func _is_evolution_near(state, id: String, next_level: int) -> bool:
	var evolution = state.evolution_for_weapon(id)
	if evolution.is_empty():
		return false
	return int(evolution.get("weapon_level", 8)) - next_level <= 1

func _is_passive_evolution_material(state, id: String) -> bool:
	for evolution_id in state.evolution_defs.keys():
		if String(state.evolution_defs[evolution_id].get("passive", "")) == id:
			return true
	return false
