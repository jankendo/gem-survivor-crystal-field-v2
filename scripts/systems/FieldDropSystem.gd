extends RefCounted
class_name FieldDropSystem

const ExpGemScript = preload("res://scripts/core/ExpGem.gd")
const ProjectileScript = preload("res://scripts/core/Projectile.gd")

var evolution_system = preload("res://scripts/systems/EvolutionSystem.gd").new()
var overclock_system = preload("res://scripts/systems/OverclockSystem.gd").new()
var core_choice_system = preload("res://scripts/systems/CorePickupChoiceSystem.gd").new()
var global_collection_system = preload("res://scripts/systems/GlobalGemCollectionSystem.gd").new()
var character_evolution_system = preload("res://scripts/systems/CharacterEvolutionSystem.gd").new()

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
			message = _open_core_choice(state, drop, events, "weapon")
		"passive_core":
			message = _open_core_choice(state, drop, events, "passive")
		"evolution_core":
			message = _apply_evolution_core(state, events)
		"overclock_core":
			message = _apply_overclock_core(state, events)
		"cursed_relic":
			message = _apply_cursed_relic(state)
		"heal_ore":
			message = _apply_heal_ore(state)
		"magnet_ore":
			message = _apply_magnet_ore(state, events)
		"crystal_cache":
			message = _apply_crystal_cache(state, drop.get("position", state.player_position), events)
		"skip_charge":
			message = _apply_skip_charge(state)
		"seal_charge":
			message = _apply_seal_charge(state)
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

func _open_core_choice(state, drop: Dictionary, events: Array, kind: String) -> String:
	if core_choice_system.open_choice(state, kind, drop, events):
		return "%sを発見！ 中身を選択" % String(drop.get("name_ja", "コア"))
	return "%s！ 候補なしでスコア化" % String(drop.get("name_ja", "コア"))

func _apply_weapon_core(state) -> String:
	var events: Array = []
	return _open_core_choice(state, {
		"id": "weapon_core",
		"runtime_id": "test_weapon_core",
		"name_ja": "武器コア",
		"position": state.player_position
	}, events, "weapon")

func _apply_passive_core(state) -> String:
	var events: Array = []
	return _open_core_choice(state, {
		"id": "passive_core",
		"runtime_id": "test_passive_core",
		"name_ja": "パッシブコア",
		"position": state.player_position
	}, events, "passive")

func _apply_evolution_core(state, events: Array) -> String:
	if character_evolution_system.apply_evolution(state, events, "evolution_core"):
		return "進化核！ %sへ進化" % state.character_evolution_name
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

func _apply_magnet_ore(state, events: Array) -> String:
	state.magnet_ore_collected_run += 1
	var result = global_collection_system.collect_all(state, events, "magnet")
	return "磁力鉱石！ 全フィールドジェム回収 %d / EXP %d" % [int(result.get("count", 0)), int(result.get("exp", 0))]

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

func _apply_skip_charge(state) -> String:
	if state.selection_skip_remaining < state.selection_skip_max:
		state.selection_skip_remaining += 1
		return "スキップの欠片！ スキップ+1"
	state.add_score(450)
	return "スキップ満タン！ スコア+450"

func _apply_seal_charge(state) -> String:
	if state.selection_seal_remaining < state.selection_seal_max:
		state.selection_seal_remaining += 1
		return "封印の欠片！ 封印+1"
	state.add_score(550)
	return "封印満タン！ スコア+550"

func _drop_color(drop: Dictionary) -> Color:
	var values: Array = drop.get("color", [1.0, 1.0, 1.0])
	if values.size() >= 3:
		return Color(float(values[0]), float(values[1]), float(values[2]))
	return Color.WHITE
