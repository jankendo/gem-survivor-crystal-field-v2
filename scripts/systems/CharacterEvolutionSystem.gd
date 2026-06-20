extends RefCounted
class_name CharacterEvolutionSystem

func data_for(state, character_id: String = "") -> Dictionary:
	var id = character_id if character_id != "" else state.selected_character_id
	return state.character_evolution_defs.get(id, {})

func is_unlocked(save_data: Dictionary, character_id: String) -> bool:
	var unlocked: Dictionary = save_data.get("character_evolutions_unlocked", {})
	return bool(unlocked.get(character_id, character_id == "noah"))

func run_condition_progress(state) -> Dictionary:
	var data = data_for(state)
	if data.is_empty():
		return {"complete": false, "text": "進化データなし"}
	var level_ok = state.level >= int(data.get("required_level", 20))
	var time_ok = state.elapsed_seconds >= float(data.get("required_seconds", 600.0))
	var unique = data.get("unique_condition", {})
	var unique_ok = _unique_condition_met(state, unique)
	return {
		"complete": level_ok and time_ok and unique_ok,
		"level_ok": level_ok,
		"time_ok": time_ok,
		"unique_ok": unique_ok,
		"text": "Lv%d/%d・%s/%s・%s" % [
			state.level,
			int(data.get("required_level", 20)),
			_time_text(state.elapsed_seconds),
			_time_text(float(data.get("required_seconds", 600.0))),
			String(unique.get("text_ja", "固有条件"))
		]
	}

func can_evolve(state) -> bool:
	if bool(state.character_evolved):
		return false
	if data_for(state).is_empty():
		return false
	if not state.character_evolution_unlocked_ids.has(state.selected_character_id):
		return false
	return bool(run_condition_progress(state).get("complete", false))

func process(state, events: Array) -> void:
	if bool(state.character_evolved):
		return
	var progress = run_condition_progress(state)
	state.character_evolution_progress_text = String(progress.get("text", ""))
	state.character_evolution_available = can_evolve(state)
	if state.character_evolution_available and not bool(state.character_evolution_notified):
		state.character_evolution_notified = true
		events.append({"type": "character_evolution_ready", "character": state.selected_character_id, "name": String(data_for(state).get("evolved_name_ja", ""))})

func apply_evolution(state, events: Array, source: String = "evolution_core") -> bool:
	if not can_evolve(state):
		return false
	var data = data_for(state)
	var id = state.selected_character_id
	state.character_evolved = true
	state.character_evolution_available = false
	state.character_evolution_id = id
	state.character_evolution_name = String(data.get("evolved_name_ja", data.get("name_ja", id)))
	state.character_evolution_time = state.elapsed_seconds
	state.selected_character_name = state.character_evolution_name
	_apply_modifiers(state, data.get("modifiers", {}))
	_apply_subtraits(state, data.get("subtraits", {}))
	state.add_floating_text("キャラ進化：%s" % state.character_evolution_name, state.player_position + Vector2(0, -88), Color(1.0, 0.88, 0.36))
	events.append({
		"type": "character_evolution",
		"character": id,
		"name": state.character_evolution_name,
		"source": source,
		"time": state.character_evolution_time
	})
	return true

func update_after_run(save_data: Dictionary, summary: Dictionary) -> void:
	var character_id = String(summary.get("character_id", save_data.get("selected_character", "noah")))
	var unlocked: Dictionary = save_data.get("character_evolutions_unlocked", {})
	var progress: Dictionary = save_data.get("character_evolution_progress", {})
	var mastery: Dictionary = save_data.get("character_mastery", {}).get(character_id, {})
	progress[character_id] = {
		"mastery_points": int(mastery.get("points", 0)),
		"best_survival": float(summary.get("survival_time", 0.0)),
		"gems_collected": int(summary.get("gems_collected", 0))
	}
	if character_id == "noah" or int(mastery.get("points", 0)) >= 350 or float(summary.get("survival_time", 0.0)) >= 900.0:
		unlocked[character_id] = true
	if bool(summary.get("character_evolved", false)):
		var counts: Dictionary = save_data.get("character_evolution_count_by_character", {})
		counts[character_id] = int(counts.get(character_id, 0)) + 1
		save_data["character_evolution_count_by_character"] = counts
		var fastest: Dictionary = save_data.get("fastest_evolution_time_by_character", {})
		var time = float(summary.get("character_evolution_time", 999999.0))
		if time > 0.0 and (not fastest.has(character_id) or time < float(fastest.get(character_id, 999999.0))):
			fastest[character_id] = time
		save_data["fastest_evolution_time_by_character"] = fastest
	save_data["character_evolutions_unlocked"] = unlocked
	save_data["character_evolution_progress"] = progress

func _apply_modifiers(state, modifiers: Dictionary) -> void:
	for key in modifiers.keys():
		var id = String(key)
		var value = modifiers[key]
		if value is Dictionary:
			var target: Dictionary = state.character_modifiers.get(id, {})
			for sub_key in value.keys():
				target[String(sub_key)] = float(target.get(String(sub_key), 1.0)) * float(value[sub_key])
			state.character_modifiers[id] = target
		elif value is bool:
			state.character_modifiers[id] = value
		elif id.ends_with("_mult"):
			state.character_modifiers[id] = float(state.character_modifiers.get(id, 1.0)) * float(value)
		else:
			state.character_modifiers[id] = float(state.character_modifiers.get(id, 0.0)) + float(value)

func _apply_subtraits(state, subtraits: Dictionary) -> void:
	if subtraits.has("max_hp_flat"):
		var hp_add = int(subtraits.get("max_hp_flat", 0))
		state.max_hp += hp_add
		state.hp = mini(state.max_hp, state.hp + hp_add)
	if subtraits.has("magnet_mult"):
		state.base_magnet_radius *= float(subtraits.get("magnet_mult", 1.0))

func _unique_condition_met(state, condition: Dictionary) -> bool:
	var type = String(condition.get("type", "gems_collected"))
	match type:
		"gems_collected":
			return state.gems_collected >= int(condition.get("value", 300))
		"kills":
			return state.kills >= int(condition.get("value", 500))
		"crystals_destroyed":
			return state.crystals_destroyed >= int(condition.get("value", 25))
		"rooms_discovered":
			return state.rooms_discovered >= int(condition.get("value", 6))
		"boss_defeats":
			return state.boss_defeated_ids.size() >= int(condition.get("value", 1))
	return true

func _time_text(seconds: float) -> String:
	var total = int(floor(seconds))
	return "%02d:%02d" % [int(floor(float(total) / 60.0)), total % 60]
