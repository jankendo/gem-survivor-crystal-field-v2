extends RefCounted
class_name BalanceLogSystem

func process(state, delta: float) -> void:
	if not state.balance_log_enabled:
		return
	state.balance_log_timer += delta
	if state.balance_log_timer < 1.0:
		return
	state.balance_log_timer = 0.0
	if state.balance_log_rows.is_empty():
		state.balance_log_rows.append("time,level,exp_percent,hp_percent,enemy_count,gem_count,projectile_count,kill_count,chest_count,boss_alive,evolved_weapon_count,difficulty_factor,damage_taken_last_minute,levelups_last_minute,total_weapon_damage,currency_gain,crystal_gain,map_room_count,exploration_score,debug_exp_multiplier,global_gem_collections,gems_collected_by_magnet,gems_collected_by_drone,gems_collected_by_passive,character_evolved,character_evolution_time,persistent_drop_count,field_weapon_ids,field_passive_ids")
	state.balance_log_rows.append("%s,%d,%.3f,%.3f,%d,%d,%d,%d,%d,%s,%d,%.3f,%d,%d,%d,%d,%d,%d,%d,%.2f,%d,%d,%d,%d,%s,%.2f,%d,%s,%s" % [
		_time_text(state.elapsed_seconds),
		state.level,
		clampf(float(state.exp) / float(maxi(1, state.exp_to_next)), 0.0, 1.0),
		state.hp_ratio(),
		state.enemies.size(),
		state.gems.size(),
		state.projectiles.size() + state.enemy_projectiles.size(),
		state.kills,
		state.chests.size(),
		"1" if state.boss_alive() else "0",
		state.evolved_weapon_count,
		state.difficulty_factor(),
		state.damage_taken_last_minute,
		state.levelups_last_minute,
		_total_weapon_damage(state),
		0,
		state.crystals_destroyed,
		state.rooms_discovered,
		state.exploration_score,
		state.debug_exp_multiplier,
		state.global_gem_collections,
		state.gems_collected_by_magnet,
		state.gems_collected_by_drone,
		state.gems_collected_by_passive,
		"1" if state.character_evolved else "0",
		state.character_evolution_time,
		_persistent_drop_count(state),
		_id_list(state.field_equipment, "weapon"),
		_id_list(state.field_equipment, "passive")
	])

func flush(state) -> void:
	if not state.balance_log_enabled or state.balance_log_rows.is_empty():
		return
	var file = FileAccess.open(state.balance_log_path, FileAccess.WRITE)
	if file == null:
		return
	for row in state.balance_log_rows:
		file.store_line(String(row))
	var summary_file := FileAccess.open("user://run_balance_summary.json", FileAccess.WRITE)
	if summary_file != null:
		summary_file.store_string(JSON.stringify({
			"survival_time": state.elapsed_seconds,
			"weapon_damage_by_id": state.weapon_damage_by_id,
			"weapon_pick_count_by_id": state.weapon_pick_counts,
			"weapon_level_by_id": state.weapons,
			"weapon_evolved_by_id": state.evolved_weapons,
			"passive_pick_count_by_id": state.passive_pick_counts,
			"passive_level_by_id": state.passives,
			"damage_by_category": state.damage_by_category,
			"kills_by_weapon_id": state.weapon_kill_counts,
			"boss_damage_by_weapon_id": state.boss_damage_by_weapon_id,
			"enemy_damage_by_weapon_id": state.enemy_damage_by_weapon_id,
			"damage_taken_by_time": {"last_minute": state.damage_taken_last_minute},
			"healing_by_source": state.healing_by_source,
			"currency_gain_by_source": state.currency_gain_by_source,
			"evolution_time_by_weapon_id": state.evolution_time_by_weapon_id,
			"debug_exp_multiplier": state.debug_exp_multiplier,
			"global_gem_collections": state.global_gem_collections,
			"gems_collected_by_magnet": state.gems_collected_by_magnet,
			"gems_collected_by_drone": state.gems_collected_by_drone,
			"gems_collected_by_passive": state.gems_collected_by_passive,
			"character_evolved": state.character_evolved,
			"character_evolution_time": state.character_evolution_time,
			"field_weapon_ids": _id_list(state.field_equipment, "weapon"),
			"field_passive_ids": _id_list(state.field_equipment, "passive"),
			"persistent_drop_count": _persistent_drop_count(state),
			"death_cause": state.game_over_reason,
			"disabled_weapons": state.disabled_weapon_ids,
			"disabled_passives": state.disabled_passive_ids
		}, "\t"))

func _time_text(seconds: float) -> String:
	var total = int(floor(seconds))
	return "%02d:%02d" % [int(floor(float(total) / 60.0)), total % 60]

func _total_weapon_damage(state) -> int:
	var total = 0
	for value in state.weapon_damage_by_id.values():
		total += int(value)
	return total

func _id_list(items: Array, kind: String) -> String:
	var ids: Array = []
	for item in items:
		if String(item.get("kind", "")) == kind:
			ids.append(String(item.get("id", "")))
	return "|".join(ids)

func _persistent_drop_count(state) -> int:
	var count = 0
	for drop in state.field_drops:
		if not bool(drop.get("collected", false)):
			count += 1
	return count
