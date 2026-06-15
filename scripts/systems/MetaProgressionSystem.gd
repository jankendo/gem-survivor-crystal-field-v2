extends RefCounted
class_name MetaProgressionSystem

const SaveSystemScript = preload("res://scripts/systems/SaveSystem.gd")
const CurrencySystemScript = preload("res://scripts/systems/CurrencySystem.gd")
const UnlockSystemScript = preload("res://scripts/systems/UnlockSystem.gd")
const CurrencySinkSystemScript = preload("res://scripts/systems/CurrencySinkSystem.gd")
const ProgressTrackerSystemScript = preload("res://scripts/systems/ProgressTrackerSystem.gd")

var characters: Dictionary = {}
var unlocks: Dictionary = {}
var upgrades: Dictionary = {}
var quests: Dictionary = {}
var mastery: Dictionary = {}
var blessings: Dictionary = {}
var collection: Dictionary = {}
var field_help: Dictionary = {}
var unlock_system = UnlockSystemScript.new()
var currency_sink_system = CurrencySinkSystemScript.new()
var progress_tracker = ProgressTrackerSystemScript.new()

func _init() -> void:
	reload()

func reload() -> void:
	characters = _json_dict("res://data/characters.json", {})
	unlocks = _json_dict("res://data/character_unlocks.json", {})
	upgrades = _json_dict("res://data/meta_upgrades.json", {})
	quests = _json_dict("res://data/quests.json", {})
	mastery = _json_dict("res://data/mastery.json", {"thresholds": [0, 350, 900, 1800, 3200]})
	blessings = _json_dict("res://data/blessings.json", {})
	collection = _json_dict("res://data/collection.json", {})
	field_help = _json_dict("res://data/field_help.json", {})

func character_ids() -> Array:
	return characters.keys()

func character_data(character_id: String) -> Dictionary:
	return characters.get(character_id, {})

func display_name(character_id: String, save_data: Dictionary) -> String:
	var data = character_data(character_id)
	if bool(data.get("secret", false)) and not is_character_unlocked(save_data, character_id):
		return String(data.get("display_locked_ja", "？？？"))
	return String(data.get("name_ja", character_id))

func unlock_text(character_id: String, save_data: Dictionary) -> String:
	var data = character_data(character_id)
	if bool(data.get("secret", false)) and not is_character_unlocked(save_data, character_id):
		return "解放条件：%s\n%s" % [
			String(data.get("secret_hint_ja", "秘密の条件")),
			progress_tracker.progress_text(save_data, unlocks.get(character_id, {}))
		]
	var condition: Dictionary = unlocks.get(character_id, {"type": "initial"})
	return "%s\n%s" % [
		String(condition.get("text_ja", "条件なし")),
		progress_tracker.progress_text(save_data, condition)
	]

func is_character_unlocked(save_data: Dictionary, character_id: String) -> bool:
	return (save_data.get("unlocked_characters", []) as Array).has(character_id)

func can_purchase_character(save_data: Dictionary, character_id: String) -> bool:
	if is_character_unlocked(save_data, character_id):
		return false
	var cost = int(character_data(character_id).get("unlock_cost", 0))
	return cost > 0 and int(save_data.get("crystal_currency", 0)) >= cost

func purchase_character(save: SaveSystem, character_id: String) -> bool:
	var save_data = save.load_data()
	var cost = int(character_data(character_id).get("unlock_cost", 0))
	if cost <= 0 or is_character_unlocked(save_data, character_id) or int(save_data.get("crystal_currency", 0)) < cost:
		return false
	save_data["crystal_currency"] = int(save_data.get("crystal_currency", 0)) - cost
	var unlocked: Array = save_data.get("unlocked_characters", [])
	unlocked.append(character_id)
	save_data["unlocked_characters"] = unlocked
	_mark_collection(save_data, "characters", character_id)
	save.save_data(save_data)
	return true

func purchase_upgrade(save: SaveSystem, upgrade_id: String) -> bool:
	var save_data = save.load_data()
	var def: Dictionary = upgrades.get(upgrade_id, {})
	if def.is_empty():
		return false
	var levels: Dictionary = save_data.get("meta_upgrades", {})
	var current = int(levels.get(upgrade_id, 0))
	var max_level = int(def.get("max_level", 1))
	if current >= max_level:
		return false
	var cost = upgrade_cost(upgrade_id, current)
	if int(save_data.get("crystal_currency", 0)) < cost:
		return false
	save_data["crystal_currency"] = int(save_data.get("crystal_currency", 0)) - cost
	levels[upgrade_id] = current + 1
	save_data["meta_upgrades"] = levels
	save.save_data(save_data)
	return true

func upgrade_cost(upgrade_id: String, current_level: int) -> int:
	var def: Dictionary = upgrades.get(upgrade_id, {})
	return int(def.get("base_cost", 100)) + int(def.get("cost_step", 75)) * current_level

func check_character_unlocks(save: SaveSystem) -> Array:
	var save_data = save.load_data()
	var newly: Array = []
	for character_id in characters.keys():
		var id = String(character_id)
		if is_character_unlocked(save_data, id):
			continue
		var data: Dictionary = characters[id]
		if int(data.get("unlock_cost", 0)) > 0:
			continue
		if _condition_met(save_data, unlocks.get(id, {})):
			var unlocked: Array = save_data.get("unlocked_characters", [])
			unlocked.append(id)
			save_data["unlocked_characters"] = unlocked
			_mark_collection(save_data, "characters", id)
			newly.append(id)
	save.save_data(save_data)
	return newly

func update_after_run(save: SaveSystem, summary: Dictionary) -> Dictionary:
	var save_data = save.load_data()
	var progress_before := _progress_snapshot(save_data)
	var character_id = String(summary.get("character_id", save_data.get("selected_character", "noah")))
	var character = character_data(character_id)
	var earned = CurrencySystemScript.new().calculate_run_currency(summary, save_data, character)
	save_data["crystal_currency"] = int(save_data.get("crystal_currency", 0)) + earned
	var stats: Dictionary = save_data.get("stats", {})
	stats["total_currency_earned"] = int(stats.get("total_currency_earned", 0)) + earned
	stats["crystal_currency_total_earned"] = int(stats.get("crystal_currency_total_earned", 0)) + earned
	save_data["stats"] = stats
	_update_stats(save_data, summary)
	_update_weapon_records(save_data, summary)
	_update_character_record(save_data, character_id, summary)
	var completed = _update_quests(save_data)
	var unlocked_items = unlock_system.update_after_run(save_data)
	var unlocked = _unlock_condition_characters(save_data)
	var mastery_result = _update_mastery(save_data, character_id, summary)
	_discover_from_summary(save_data, summary)
	var progress_after := _progress_snapshot(save_data)
	var progress_deltas := _progress_deltas(progress_before, progress_after)
	save.save_data(save_data)
	return {
		"currency_earned": earned,
		"currency_total": int(save_data.get("crystal_currency", 0)),
		"quests_completed": completed,
		"characters_unlocked": unlocked,
		"weapons_unlocked": unlocked_items.get("weapons", []),
		"passives_unlocked": unlocked_items.get("passives", []),
		"mastery": mastery_result,
		"progress_deltas": progress_deltas
	}

func apply_to_state(state, character_id: String, blessing_id: String, save_data: Dictionary) -> void:
	var character = character_data(character_id)
	if character.is_empty():
		character_id = "noah"
		character = character_data(character_id)
	state.selected_character_id = character_id
	state.selected_character_name = String(character.get("name_ja", "探鉱者ノア"))
	state.character_modifiers = character.get("modifiers", {}).duplicate(true)
	state.selected_blessing_id = blessing_id
	state.blessing_modifiers = blessings.get(blessing_id, {}).get("modifiers", {}).duplicate(true)
	state.meta_upgrade_levels = save_data.get("meta_upgrades", {}).duplicate(true)
	state.field_help_discovered = save_data.get("field_help_discovered", {}).duplicate(true)
	unlock_system.apply_to_state(state, save_data)
	state.apply_meta_modifiers()
	currency_sink_system.apply_to_state(state, save_data)
	var initial_weapon = String(character.get("initial_weapon", "magic_bolt"))
	state.weapons = {}
	if initial_weapon != "":
		state.weapons[initial_weapon] = 1
	else:
		state.weapons["magic_bolt"] = 1
		state.weapon_cooldowns["magic_bolt"] = 1.25
	_apply_character_starting_stats(state)

func unlocked_blessings(save_data: Dictionary) -> Array:
	var unlocked: Array = save_data.get("unlocked_blessings", ["attack"])
	for id in blessings.keys():
		if unlocked.has(String(id)):
			continue
		var unlock: Dictionary = blessings[id].get("unlock", {})
		if _condition_met(save_data, unlock):
			unlocked.append(String(id))
	return unlocked

func collection_rows(tab: String, save_data: Dictionary) -> Array:
	var discovered: Dictionary = save_data.get("collection_discovered", {}).get(tab, {})
	var rows: Array = []
	var source: Dictionary = {}
	match tab:
		"characters":
			source = characters
		"weapons":
			source = _json_dict("res://data/weapons.json", {})
		"passives":
			source = _json_dict("res://data/passives.json", {})
		"evolutions":
			source = _json_dict("res://data/evolutions.json", {})
		"enemies":
			source = _json_dict("res://data/enemies.json", {})
		"bosses":
			source = _json_dict("res://data/bosses.json", {})
		"field_drops":
			source = field_help.get("drops", {}).duplicate(true)
		"field_gimmicks":
			source = field_help.get("gimmicks", {}).duplicate(true)
		"field_events":
			source = field_help.get("events", {}).duplicate(true)
			for event in _json_dict("res://data/field_events.json", {}).get("events", []):
				var event_id = String(event.get("id", ""))
				var merged: Dictionary = source.get(event_id, {}).duplicate(true)
				merged.merge(event, true)
				source[event_id] = merged
		"blessings":
			source = blessings
	for id in source.keys():
		var key = String(id)
		var source_data: Dictionary = source[key]
		var is_unlocked = true
		var unlock_text = ""
		if tab == "weapons":
			is_unlocked = unlock_system.is_weapon_unlocked(save_data, key)
			unlock_text = unlock_system.unlock_text("weapons", key)
		elif tab == "passives":
			is_unlocked = unlock_system.is_passive_unlocked(save_data, key)
			unlock_text = unlock_system.unlock_text("passives", key)
		elif tab == "blessings":
			is_unlocked = (save_data.get("unlocked_blessings", ["attack"]) as Array).has(key)
			unlock_text = String(source_data.get("unlock_condition_ja", ""))
		var is_known = bool(discovered.get(key, false)) or tab == "characters" and is_character_unlocked(save_data, key)
		if tab in ["weapons", "passives"]:
			is_known = is_known or is_unlocked
		elif tab == "blessings":
			is_known = true
		elif tab in ["field_drops", "field_gimmicks", "field_events"]:
			var singular = tab.trim_suffix("s").trim_prefix("field_")
			is_known = bool(save_data.get("field_help_discovered", {}).get("%s:%s" % [singular, key], false))
		var name = String(source[key].get("name_ja", key)) if is_known else "？？？"
		var status = "解放済み" if is_unlocked else "未解放"
		var detail = String(source[key].get("description_ja", source[key].get("effect_ja", "")))
		if tab == "weapons":
			detail = "最高Lv %d / 取得撃破 %d / %s" % [
				int(save_data.get("weapon_highest_levels", {}).get(key, 0)),
				int(save_data.get("weapon_kills", {}).get(key, 0)),
				"進化済み" if bool(save_data.get("evolved_weapons", {}).get(key, false)) else "未進化"
			]
		elif tab == "passives":
			detail = String(source[key].get("description_ja", ""))
		elif tab == "blessings":
			detail = blessing_detail_text(key, save_data)
		elif tab in ["field_drops", "field_gimmicks", "field_events"]:
			status = "発見済み" if is_known else "未発見"
			detail = "\n".join([
				String(source[key].get("effect_ja", "")),
				"対処：%s" % String(source[key].get("approach_ja", "")),
				"報酬：%s" % String(source[key].get("reward_ja", source[key].get("reward", ""))),
				"おすすめ：%s" % String(source[key].get("build_ja", "")),
				"危険度：%d / 5" % int(source[key].get("danger", 1)),
				"リスク：%s" % String(source[key].get("risk", "低"))
			])
		var row := {
			"id": key,
			"known": is_known,
			"unlocked": is_unlocked,
			"name_ja": name,
			"status_ja": status,
			"unlock_text_ja": unlock_text,
			"detail_ja": detail,
			"secret": bool(source_data.get("secret", false)),
			"tags": source_data.get("tags", []),
			"category": String(source_data.get("category", "")),
			"evolved": bool(save_data.get("evolved_weapons", {}).get(key, false)),
			"evolvable": tab == "weapons" and _evolution_id_for_weapon(key) != key,
			"highest_level": int(save_data.get("weapon_highest_levels", {}).get(key, 0)),
			"acquired_count": int(save_data.get("weapon_kills", {}).get(key, 0))
		}
		if tab == "weapons" and not is_unlocked:
			row["unlock_text_ja"] += "\n" + unlock_system.progress_text("weapons", key, save_data)
		elif tab == "passives" and not is_unlocked:
			row["unlock_text_ja"] += "\n" + unlock_system.progress_text("passives", key, save_data)
		elif tab == "blessings" and not is_unlocked:
			row["unlock_text_ja"] += "\n" + progress_tracker.progress_text(save_data, source_data.get("unlock", {}))
		rows.append(row)
	return rows

func blessing_detail_text(blessing_id: String, save_data: Dictionary = {}) -> String:
	var data: Dictionary = blessings.get(blessing_id, {})
	var lines: Array = [
		String(data.get("effect_description_ja", data.get("description_ja", ""))),
		"数値：%s" % " / ".join(data.get("numeric_effects_ja", [])),
		"推奨：%s" % String(data.get("recommended_for_ja", "すべて")),
		"注意：%s" % String(data.get("tradeoff_description_ja", "なし"))
	]
	if not save_data.is_empty() and not (save_data.get("unlocked_blessings", ["attack"]) as Array).has(blessing_id):
		lines.append(progress_tracker.progress_text(save_data, data.get("unlock", {})))
	return "\n".join(lines)

func _update_stats(save_data: Dictionary, summary: Dictionary) -> void:
	var stats: Dictionary = save_data.get("stats", {})
	stats["total_kills"] = int(stats.get("total_kills", 0)) + int(summary.get("kills", 0))
	stats["total_survival"] = float(stats.get("total_survival", 0.0)) + float(summary.get("survival_time", 0.0))
	stats["survival_time_total"] = float(stats.get("survival_time_total", 0.0)) + float(summary.get("survival_time", 0.0))
	stats["total_crystals"] = int(stats.get("total_crystals", 0)) + int(summary.get("crystals_destroyed", 0))
	stats["walls_broken"] = int(stats.get("walls_broken", 0)) + int(summary.get("crystals_destroyed", 0))
	stats["total_chests"] = int(stats.get("total_chests", 0)) + int(summary.get("chests_opened", 0))
	stats["total_contracts"] = int(stats.get("total_contracts", 0)) + (summary.get("rune_contracts", []) as Array).size()
	stats["best_survival"] = maxf(float(stats.get("best_survival", 0.0)), float(summary.get("survival_time", 0.0)))
	stats["max_combo"] = maxi(int(stats.get("max_combo", 0)), int(summary.get("max_combo", 0)))
	stats["best_danger_time"] = maxf(float(stats.get("best_danger_time", 0.0)), float(summary.get("danger_time", 0.0)))
	stats["run_explosion_weapons"] = maxi(int(stats.get("run_explosion_weapons", 0)), _count_tagged_weapons(summary.get("weapon_levels", {}), "explosion"))
	stats["best_exploration_score"] = maxi(int(stats.get("best_exploration_score", 0)), int(summary.get("exploration_score", 0)))
	stats["max_exploration_chain"] = maxi(int(stats.get("max_exploration_chain", 0)), int(summary.get("exploration_chain_max", 0)))
	stats["field_event_successes"] = int(stats.get("field_event_successes", 0)) + int(summary.get("field_event_successes", 0))
	stats["events_completed"] = int(stats.get("events_completed", 0)) + int(summary.get("field_event_successes", 0))
	stats["field_drops_collected"] = int(stats.get("field_drops_collected", 0)) + int(summary.get("field_drops_collected", 0))
	stats["field_gimmicks_triggered"] = int(stats.get("field_gimmicks_triggered", 0)) + int(summary.get("field_gimmicks_triggered", 0))
	stats["field_gimmicks_used"] = int(stats.get("field_gimmicks_used", 0)) + int(summary.get("field_gimmicks_triggered", 0))
	stats["bosses_killed"] = int(stats.get("bosses_killed", 0)) + int(summary.get("boss_defeats", 0))
	stats["evolution_count"] = int(stats.get("evolution_count", 0)) + int(summary.get("evolved_weapon_count", 0))
	stats["overclock_count"] = int(stats.get("overclock_count", 0)) + int(summary.get("overclock_count", 0))
	stats["rooms_discovered"] = int(stats.get("rooms_discovered", 0)) + int(summary.get("rooms_discovered", 0))
	stats["max_rooms_in_run"] = maxi(int(stats.get("max_rooms_in_run", 0)), int(summary.get("rooms_discovered", 0)))
	stats["shortcut_walls_broken"] = int(stats.get("shortcut_walls_broken", 0)) + int(summary.get("shortcut_walls_broken", 0))
	stats["oasis_healing"] = int(stats.get("oasis_healing", 0)) + int(summary.get("oasis_healing", 0))
	stats["cursed_relics"] = int(stats.get("cursed_relics", 0)) + int(summary.get("cursed_relics", 0))
	stats["low_hp_time"] = float(stats.get("low_hp_time", 0.0)) + float(summary.get("low_hp_survival_time", 0.0))
	_merge_number_dictionary(stats, "terrain_time", summary.get("terrain_time", {}))
	_merge_number_dictionary(stats, "survival_time_by_terrain", summary.get("terrain_time", {}))
	_merge_number_dictionary(stats, "terrain_kills", summary.get("terrain_kills", {}))
	_merge_number_dictionary(stats, "kills_in_terrain_type", summary.get("terrain_kills", {}))
	_merge_number_dictionary(stats, "terrain_crystals", summary.get("terrain_crystals", {}))
	_merge_number_dictionary(stats, "weapon_pick_count", summary.get("weapon_pick_count_by_id", {}))
	_merge_number_dictionary(stats, "passive_pick_count", summary.get("passive_pick_count_by_id", {}))
	_merge_number_dictionary(stats, "kills_by_weapon_id", summary.get("weapon_kill_counts", {}))
	if _rank_value(String(summary.get("exploration_rank", "D"))) > _rank_value(String(stats.get("best_exploration_rank", "D"))):
		stats["best_exploration_rank"] = String(summary.get("exploration_rank", "D"))
	stats["highest_exploration_rank"] = String(stats.get("best_exploration_rank", "D"))
	var rank_counts: Dictionary = stats.get("exploration_rank_count", {})
	var run_rank := String(summary.get("exploration_rank", "D"))
	rank_counts[run_rank] = int(rank_counts.get(run_rank, 0)) + 1
	stats["exploration_rank_count"] = rank_counts
	var blessing_counts: Dictionary = stats.get("blessing_used_count", {})
	var blessing_id := String(summary.get("blessing_id", "attack"))
	blessing_counts[blessing_id] = int(blessing_counts.get(blessing_id, 0)) + 1
	stats["blessing_used_count"] = blessing_counts
	if float(summary.get("survival_time", 0.0)) >= 600.0:
		stats["survive_10_runs"] = int(stats.get("survive_10_runs", 0)) + 1
	save_data["stats"] = stats
	for title in summary.get("title_badges", []):
		save_data["titles"][String(title)] = true

func _update_weapon_records(save_data: Dictionary, summary: Dictionary) -> void:
	var highest: Dictionary = save_data.get("weapon_highest_levels", {})
	for weapon_id in summary.get("weapon_levels", {}).keys():
		highest[String(weapon_id)] = maxi(int(highest.get(String(weapon_id), 0)), int(summary["weapon_levels"][weapon_id]))
	save_data["weapon_highest_levels"] = highest
	var weapon_kills: Dictionary = save_data.get("weapon_kills", {})
	var run_kills: Dictionary = summary.get("weapon_kill_counts", {})
	for weapon_id in run_kills.keys():
		var id := String(weapon_id)
		weapon_kills[id] = int(weapon_kills.get(id, 0)) + int(run_kills[weapon_id])
	save_data["weapon_kills"] = weapon_kills
	for weapon_id in summary.get("evolved_weapon_ids", []):
		save_data["evolved_weapons"][String(weapon_id)] = true
	for boss_id in summary.get("boss_defeated_ids", []):
		save_data["boss_defeats"][String(boss_id)] = true

func _update_character_record(save_data: Dictionary, character_id: String, summary: Dictionary) -> void:
	var records: Dictionary = save_data.get("character_records", {})
	var record: Dictionary = records.get(character_id, {})
	record["best_survival"] = maxf(float(record.get("best_survival", 0.0)), float(summary.get("survival_time", 0.0)))
	record["best_kills"] = maxi(int(record.get("best_kills", 0)), int(summary.get("kills", 0)))
	record["best_score"] = maxi(int(record.get("best_score", 0)), int(summary.get("score", 0)))
	records[character_id] = record
	save_data["character_records"] = records

func _update_quests(save_data: Dictionary) -> Array:
	var completed: Array = []
	var quest_done: Dictionary = save_data.get("quests_completed", {})
	for id in quests.keys():
		var quest_id = String(id)
		if bool(quest_done.get(quest_id, false)):
			continue
		if _quest_condition_met(save_data, quests[quest_id].get("condition", {})):
			quest_done[quest_id] = true
			completed.append(quest_id)
			_apply_quest_reward(save_data, quests[quest_id].get("reward", {}))
	save_data["quests_completed"] = quest_done
	return completed

func _apply_quest_reward(save_data: Dictionary, reward: Dictionary) -> void:
	if reward.has("currency"):
		save_data["crystal_currency"] = int(save_data.get("crystal_currency", 0)) + int(reward.get("currency", 0))
	if reward.has("unlock_character"):
		var id = String(reward.get("unlock_character", ""))
		var unlocked: Array = save_data.get("unlocked_characters", [])
		if id != "" and not unlocked.has(id):
			unlocked.append(id)
			save_data["unlocked_characters"] = unlocked
			_mark_collection(save_data, "characters", id)
	if reward.has("secret_flag"):
		save_data["secret_flags"][String(reward.get("secret_flag", ""))] = true
	if reward.has("discover_weapon"):
		_mark_collection(save_data, "weapons", String(reward.get("discover_weapon", "")))

func _unlock_condition_characters(save_data: Dictionary) -> Array:
	var newly: Array = []
	for id in characters.keys():
		var character_id = String(id)
		if is_character_unlocked(save_data, character_id):
			continue
		if int(characters[character_id].get("unlock_cost", 0)) > 0:
			continue
		if _condition_met(save_data, unlocks.get(character_id, {})):
			var unlocked: Array = save_data.get("unlocked_characters", [])
			unlocked.append(character_id)
			save_data["unlocked_characters"] = unlocked
			_mark_collection(save_data, "characters", character_id)
			newly.append(character_id)
	return newly

func _update_mastery(save_data: Dictionary, character_id: String, summary: Dictionary) -> Dictionary:
	var all_mastery: Dictionary = save_data.get("character_mastery", {})
	var data: Dictionary = all_mastery.get(character_id, {})
	var points = int(data.get("points", 0))
	points += int(floor(float(summary.get("survival_time", 0.0)) / 30.0))
	points += int(floor(float(summary.get("kills", 0)) / 80.0))
	points += int(summary.get("boss_defeats", 0)) * 30
	points += int(summary.get("evolved_weapon_count", 0)) * 20
	points += (summary.get("rune_contracts", []) as Array).size() * 15
	data["points"] = points
	data["level"] = _mastery_level(points)
	all_mastery[character_id] = data
	save_data["character_mastery"] = all_mastery
	return {"character": character_id, "points": points, "level": int(data.get("level", 0))}

func _mastery_level(points: int) -> int:
	var thresholds: Array = mastery.get("thresholds", [0, 350, 900, 1800, 3200])
	var level = 0
	for threshold in thresholds:
		if points >= int(threshold):
			level += 1
	return mini(level, int(mastery.get("max_level", 5)))

func _discover_from_summary(save_data: Dictionary, summary: Dictionary) -> void:
	_mark_collection(save_data, "characters", String(summary.get("character_id", save_data.get("selected_character", "noah"))))
	for weapon_id in summary.get("weapon_levels", {}).keys():
		_mark_collection(save_data, "weapons", String(weapon_id))
	for weapon_id in summary.get("evolved_weapon_ids", []):
		_mark_collection(save_data, "evolutions", _evolution_id_for_weapon(String(weapon_id)))
	for enemy_id in summary.get("enemy_seen", []):
		_mark_collection(save_data, "enemies", String(enemy_id))
	for boss_id in summary.get("boss_defeated_ids", []):
		_mark_collection(save_data, "bosses", String(boss_id))
	for title in summary.get("title_badges", []):
		_mark_collection(save_data, "titles", String(title))

func _condition_met(save_data: Dictionary, condition: Dictionary) -> bool:
	var type = String(condition.get("type", ""))
	var stats: Dictionary = save_data.get("stats", {})
	match type:
		"initial":
			return true
		"currency":
			return int(save_data.get("crystal_currency", 0)) >= int(condition.get("cost", 0))
		"currency_paid":
			return maxi(int(save_data.get("crystal_currency", 0)), int(stats.get("total_currency_earned", 0))) >= int(condition.get("cost", condition.get("value", 0)))
		"weapon_level":
			return int(save_data.get("weapon_highest_levels", {}).get(String(condition.get("weapon", "")), 0)) >= int(condition.get("level", 1))
		"weapon_kills":
			return int(save_data.get("weapon_kills", {}).get(String(condition.get("weapon", "")), 0)) >= int(condition.get("count", condition.get("value", 0)))
		"run_explosion_weapons":
			return int(stats.get("run_explosion_weapons", 0)) >= int(condition.get("count", condition.get("value", 0)))
		"evolved_weapon":
			return bool(save_data.get("evolved_weapons", {}).get(String(condition.get("weapon", "")), false))
		"boss_defeat":
			return bool(save_data.get("boss_defeats", {}).get(String(condition.get("boss", "")), false))
		"survive_seconds":
			return float(stats.get("best_survival", 0.0)) >= float(condition.get("seconds", condition.get("value", 0.0)))
		"survive_runs":
			return int(stats.get("survive_10_runs", 0)) >= int(condition.get("count", 1))
		"total_crystals":
			return int(stats.get("total_crystals", 0)) >= int(condition.get("count", condition.get("value", 0)))
		"total_chests":
			return int(stats.get("total_chests", 0)) >= int(condition.get("count", 0))
		"total_contracts":
			return int(stats.get("total_contracts", 0)) >= int(condition.get("count", condition.get("value", 0)))
		"max_combo":
			return int(stats.get("max_combo", 0)) >= int(condition.get("count", condition.get("value", 0)))
		"danger_time":
			return float(stats.get("best_danger_time", 0.0)) >= float(condition.get("seconds", condition.get("value", 0.0)))
		"specific_title":
			return bool(save_data.get("titles", {}).get(String(condition.get("title", "")), false))
		"secret_ghost":
			return bool(save_data.get("secret_flags", {}).get("ghost", false))
		"secret_collector":
			return bool(save_data.get("secret_flags", {}).get("collector", false))
		"secret_reaper":
			return bool(save_data.get("secret_flags", {}).get("nameless_reaper", false))
		"terrain_time":
			return float(stats.get("terrain_time", {}).get(String(condition.get("terrain", "")), 0.0)) >= float(condition.get("seconds", condition.get("value", 0.0)))
		"exploration_rank":
			return _rank_value(String(stats.get("best_exploration_rank", "D"))) >= _rank_value(String(condition.get("rank", condition.get("value", "D"))))
		"cursed_relics":
			return int(stats.get("cursed_relics", 0)) >= int(condition.get("count", condition.get("value", 0)))
		"field_event_successes":
			return int(stats.get("field_event_successes", 0)) >= int(condition.get("count", condition.get("value", 0)))
		"rooms_in_run":
			return int(stats.get("max_rooms_in_run", 0)) >= int(condition.get("count", condition.get("value", 0)))
		"terrain_kills":
			return int(stats.get("terrain_kills", {}).get(String(condition.get("terrain", "")), 0)) >= int(condition.get("count", condition.get("value", 0)))
		"oasis_healing":
			return int(stats.get("oasis_healing", 0)) >= int(condition.get("amount", condition.get("value", 0)))
		"cursed_walls":
			return int(stats.get("total_crystals", 0)) >= int(condition.get("count", condition.get("value", 0)))
		"field_drop_count":
			return int(stats.get("field_drops_collected", 0)) >= int(condition.get("count", condition.get("value", 0)))
		"gimmick_count":
			return int(stats.get("field_gimmicks_triggered", 0)) >= int(condition.get("count", condition.get("value", 0)))
		"secret_void_mapper":
			return int(stats.get("max_rooms_in_run", 0)) >= 12 and _rank_value(String(stats.get("best_exploration_rank", "D"))) >= _rank_value("S")
		"secret_abyss_merchant":
			return int(stats.get("total_currency_earned", 0)) >= 25000 and int(stats.get("total_contracts", 0)) >= 20
	return false

func _merge_number_dictionary(stats: Dictionary, key: String, additions) -> void:
	var target: Dictionary = stats.get(key, {})
	if additions is Dictionary:
		for raw_id in additions.keys():
			var id = String(raw_id)
			target[id] = float(target.get(id, 0.0)) + float(additions[raw_id])
	stats[key] = target

func _quest_condition_met(save_data: Dictionary, condition: Dictionary) -> bool:
	var type = String(condition.get("type", ""))
	var stats: Dictionary = save_data.get("stats", {})
	match type:
		"survive_seconds":
			return float(stats.get("best_survival", 0.0)) >= float(condition.get("value", 0.0))
		"total_kills":
			return int(stats.get("total_kills", 0)) >= int(condition.get("value", 0))
		"total_crystals":
			return int(stats.get("total_crystals", 0)) >= int(condition.get("value", 0))
		"evolved_weapon":
			return bool(save_data.get("evolved_weapons", {}).get(String(condition.get("weapon", "")), false))
		"max_combo":
			return int(stats.get("max_combo", 0)) >= int(condition.get("value", 0))
		"boss_defeat":
			return bool(save_data.get("boss_defeats", {}).get(String(condition.get("boss", "")), false))
		"total_contracts":
			return int(stats.get("total_contracts", 0)) >= int(condition.get("value", 0))
		"exploration_rank":
			return _rank_value(String(stats.get("best_exploration_rank", "D"))) >= _rank_value(String(condition.get("value", "D")))
		"exploration_chain":
			return int(stats.get("max_exploration_chain", 0)) >= int(condition.get("value", 0))
		"terrain_kills":
			return int(stats.get("terrain_kills", {}).get(String(condition.get("terrain", "")), 0)) >= int(condition.get("value", 0))
		"terrain_crystals":
			return int(stats.get("terrain_crystals", {}).get(String(condition.get("terrain", "")), 0)) >= int(condition.get("value", 0))
		"terrain_time":
			return float(stats.get("terrain_time", {}).get(String(condition.get("terrain", "")), 0.0)) >= float(condition.get("value", 0.0))
		"cursed_relics":
			return int(stats.get("cursed_relics", 0)) >= int(condition.get("value", 0))
		"rooms_in_run":
			return int(stats.get("max_rooms_in_run", 0)) >= int(condition.get("value", 0))
		"rooms_discovered":
			return int(stats.get("rooms_discovered", 0)) >= int(condition.get("value", 0))
		"shortcut_walls":
			return int(stats.get("shortcut_walls_broken", 0)) >= int(condition.get("value", 0))
	return false

func _apply_character_starting_stats(state) -> void:
	var mods: Dictionary = state.character_modifiers
	state.max_hp = maxi(1, int(round(float(state.max_hp) * float(mods.get("hp_mult", 1.0)))) + int(mods.get("hp_flat", 0)))
	state.hp = state.max_hp
	state.base_move_speed *= float(mods.get("move_mult", 1.0))
	state.base_magnet_radius *= float(mods.get("magnet_mult", 1.0))

func _mark_collection(save_data: Dictionary, tab: String, id: String) -> void:
	if id == "":
		return
	var discovered: Dictionary = save_data.get("collection_discovered", {})
	var table: Dictionary = discovered.get(tab, {})
	table[id] = true
	discovered[tab] = table
	save_data["collection_discovered"] = discovered

func _json_dict(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback.duplicate(true)
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return fallback.duplicate(true)

func _count_tagged_weapons(weapon_levels: Dictionary, tag: String) -> int:
	var weapon_defs := _json_dict("res://data/weapons.json", {})
	var count := 0
	for weapon_id in weapon_levels.keys():
		var tags: Array = weapon_defs.get(String(weapon_id), {}).get("tags", [])
		if tags.has(tag):
			count += 1
	return count

func _evolution_id_for_weapon(weapon_id: String) -> String:
	var evolution_defs := _json_dict("res://data/evolutions.json", {})
	for id in evolution_defs.keys():
		if String(evolution_defs[id].get("weapon", "")) == weapon_id:
			return String(id)
	return weapon_id

func _rank_value(rank: String) -> int:
	return ["D", "C", "B", "A", "S", "SS"].find(rank)

func _progress_snapshot(save_data: Dictionary) -> Dictionary:
	var snapshot: Dictionary = {}
	for id in quests.keys():
		snapshot["quest:%s" % id] = progress_tracker.progress_for_condition(save_data, quests[id].get("condition", {}))
	for id in unlocks.keys():
		snapshot["character:%s" % id] = progress_tracker.progress_for_condition(save_data, unlocks[id])
	for id in unlock_system.weapon_unlocks.keys():
		snapshot["weapon:%s" % id] = progress_tracker.progress_for_condition(save_data, unlock_system.condition_for("weapons", String(id)))
	for id in unlock_system.passive_unlocks.keys():
		snapshot["passive:%s" % id] = progress_tracker.progress_for_condition(save_data, unlock_system.condition_for("passives", String(id)))
	for id in blessings.keys():
		snapshot["blessing:%s" % id] = progress_tracker.progress_for_condition(save_data, blessings[id].get("unlock", {}))
	return snapshot

func _progress_deltas(before: Dictionary, after: Dictionary) -> Array:
	var result: Array = []
	for key in after.keys():
		var old: Dictionary = before.get(key, {})
		var now: Dictionary = after[key]
		var delta := float(now.get("current", 0.0)) - float(old.get("current", 0.0))
		if delta <= 0.0:
			continue
		result.append({
			"id": key,
			"label": String(now.get("label", "解放進捗")),
			"delta": delta,
			"current": float(now.get("current", 0.0)),
			"target": float(now.get("target", 1.0)),
			"value_type": String(now.get("value_type", "number")),
			"complete": bool(now.get("complete", false))
		})
	return result
