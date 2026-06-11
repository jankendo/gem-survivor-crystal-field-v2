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
		state.balance_log_rows.append("time,level,exp_percent,hp_percent,enemy_count,gem_count,projectile_count,kill_count,chest_count,boss_alive,evolved_weapon_count,difficulty_factor,damage_taken_last_minute,levelups_last_minute,total_weapon_damage,currency_gain,crystal_gain,map_room_count,exploration_score")
	state.balance_log_rows.append("%s,%d,%.3f,%.3f,%d,%d,%d,%d,%d,%s,%d,%.3f,%d,%d,%d,%d,%d,%d,%d" % [
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
		state.exploration_score
	])

func flush(state) -> void:
	if not state.balance_log_enabled or state.balance_log_rows.is_empty():
		return
	var file = FileAccess.open(state.balance_log_path, FileAccess.WRITE)
	if file == null:
		return
	for row in state.balance_log_rows:
		file.store_line(String(row))

func _time_text(seconds: float) -> String:
	var total = int(floor(seconds))
	return "%02d:%02d" % [int(floor(float(total) / 60.0)), total % 60]

func _total_weapon_damage(state) -> int:
	var total = 0
	for value in state.weapon_damage_by_id.values():
		total += int(value)
	return total
