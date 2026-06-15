extends RefCounted
class_name FieldDropSystem

const ExpGemScript = preload("res://scripts/core/ExpGem.gd")
const ProjectileScript = preload("res://scripts/core/Projectile.gd")

var evolution_system = preload("res://scripts/systems/EvolutionSystem.gd").new()
var overclock_system = preload("res://scripts/systems/OverclockSystem.gd").new()

func process(state, delta: float, events: Array) -> void:
	for drop in state.field_drops:
		if bool(drop.get("collected", false)):
			continue
		if state.elapsed_seconds < float(drop.get("unlock_seconds", 0.0)):
			continue
		var pos: Vector2 = drop.get("position", Vector2.ZERO)
		if pos.distance_to(state.player_position) <= float(drop.get("radius", 24.0)) + 22.0:
			_collect_drop(state, drop, events)

func _collect_drop(state, drop: Dictionary, events: Array) -> void:
	drop["collected"] = true
	state.field_drops_collected += 1
	var id = String(drop.get("id", ""))
	var message = ""
	match id:
		"weapon_core":
			message = _apply_weapon_core(state)
		"passive_core":
			message = _apply_passive_core(state)
		"evolution_core":
			message = _apply_evolution_core(state, events)
		"overclock_core":
			message = _apply_overclock_core(state, events)
		"cursed_relic":
			message = _apply_cursed_relic(state)
		"heal_ore":
			message = _apply_heal_ore(state)
		"magnet_ore":
			message = _apply_magnet_ore(state)
		"crystal_cache":
			message = _apply_crystal_cache(state, drop.get("position", state.player_position), events)
		_:
			message = String(drop.get("name_ja", "ドロップ")) + "獲得"
	state.add_floating_text(message, drop.get("position", state.player_position), _drop_color(drop))
	events.append({
		"type": "field_drop_pickup",
		"id": id,
		"name": String(drop.get("name_ja", id)),
		"message": message,
		"pos": drop.get("position", state.player_position),
		"dynamic": bool(drop.get("dynamic", false)),
		"spawn_distance": float(drop.get("spawn_distance", (drop.get("position", state.player_position) as Vector2).distance_to(state.field_size * 0.5))),
		"in_danger": bool(drop.get("spawn_in_danger", state.is_position_in_danger_zone(drop.get("position", state.player_position))))
	})

func _apply_weapon_core(state) -> String:
	var candidates: Array = []
	for raw_id in state.weapon_defs.keys():
		var id = String(raw_id)
		if state.can_offer_weapon(id):
			var weight = 6.0 if state.weapons.has(id) else 2.0
			candidates.append({"id": id, "weight": weight})
	if candidates.is_empty():
		state.add_score(900)
		return "武器コア！ スコア+900"
	var chosen = state.rng.weighted_choice(candidates)
	var id = String(chosen.get("id", "magic_bolt"))
	var before = int(state.weapons.get(id, 0))
	state.weapons[id] = before + 1
	state.weapon_pick_counts[id] = int(state.weapon_pick_counts.get(id, 0)) + 1
	return "武器コア！ %s Lv%d → Lv%d" % [state.weapon_name(id), before, before + 1]

func _apply_passive_core(state) -> String:
	var candidates: Array = []
	for raw_id in state.passive_defs.keys():
		var id = String(raw_id)
		if state.can_offer_passive(id):
			candidates.append({"id": id, "weight": 5.0 if state.passives.has(id) else 2.0})
	if candidates.is_empty():
		state.add_score(700)
		return "パッシブ結晶！ スコア+700"
	var chosen = state.rng.weighted_choice(candidates)
	var id = String(chosen.get("id", "might"))
	var before = int(state.passives.get(id, 0))
	state.passives[id] = before + 1
	state.passive_pick_counts[id] = int(state.passive_pick_counts.get(id, 0)) + 1
	if id == "max_hp":
		state.max_hp += 18
		state.hp = mini(state.max_hp, state.hp + 18)
	return "パッシブ結晶！ %s Lv%d → Lv%d" % [state.passive_name(id), before, before + 1]

func _apply_evolution_core(state, events: Array) -> String:
	if evolution_system.apply_first_available_evolution(state, events):
		return "進化核！ %sへ進化" % String(events[events.size() - 1].get("name", "進化武器"))
	state.add_score(1200)
	return "進化核！ 条件未達のためスコア+1200"

func _apply_overclock_core(state, events: Array) -> String:
	var options = overclock_system.make_options(state, 3)
	if not options.is_empty():
		var option: Dictionary = state.rng.choice(options)
		if overclock_system.apply_option(state, String(option.get("weapon", "")), String(option.get("id", "")), events):
			return "過充電核！ %s" % String(option.get("name_ja", "過充電"))
	state.add_score(1400)
	return "過充電核！ 候補なしでスコア+1400"

func _apply_cursed_relic(state) -> String:
	state.cursed_relic_count += 1
	state.cursed_power *= 1.12
	state.add_score(1300)
	return "呪いの遺物！ 報酬UP / 敵も強化"

func _apply_heal_ore(state) -> String:
	var heal = maxi(10, int(round(float(state.max_hp) * 0.18)))
	state.hp = mini(state.max_hp, state.hp + heal)
	return "回復鉱石！ HP +%d" % heal

func _apply_magnet_ore(state) -> String:
	for gem in state.gems:
		if gem.position.distance_to(state.player_position) <= 1150.0:
			gem.attracting = true
	return "磁力鉱石！ 周辺ジェム吸引"

func _apply_crystal_cache(state, pos: Vector2, events: Array) -> String:
	for i in range(8):
		if state.gems.size() >= state.max_gems():
			break
		var angle = TAU * float(i) / 8.0
		var gem_position = state.resolve_walkable_position(pos + Vector2(cos(angle), sin(angle)) * 38.0, 8.0, pos)
		var gem = ExpGemScript.new(gem_position, 16 + int(state.elapsed_minutes()))
		state.gems.append(gem)
		events.append({"type": "gem_drop", "pos": gem.position, "value": gem.value, "enemy": "crystal_cache"})
	state.add_score(650, pos)
	return "結晶貯蔵庫！ ジェム放出"

func _drop_color(drop: Dictionary) -> Color:
	var values: Array = drop.get("color", [1.0, 1.0, 1.0])
	if values.size() >= 3:
		return Color(float(values[0]), float(values[1]), float(values[2]))
	return Color.WHITE
