extends RefCounted
class_name ProgressTrackerSystem

const FormatterScript = preload("res://scripts/systems/ProgressDisplayFormatter.gd")

var formatter = FormatterScript.new()

func progress_for_condition(save_data: Dictionary, condition: Dictionary) -> Dictionary:
	var stats: Dictionary = save_data.get("stats", {})
	var type := String(condition.get("type", ""))
	var current := 0.0
	var target := float(condition.get("value", condition.get("count", condition.get("seconds", condition.get("cost", condition.get("amount", 1))))))
	var label := _label_for(type, condition)
	var value_type := "number"
	match type:
		"initial":
			current = 1.0
			target = 1.0
		"currency":
			current = float(save_data.get("crystal_currency", 0))
		"currency_paid", "total_currency_earned":
			current = float(stats.get("total_currency_earned", 0))
		"total_kills":
			current = float(stats.get("total_kills", 0))
		"total_gems_collected":
			current = float(stats.get("total_gems_collected", 0))
		"total_crystals", "cursed_walls":
			current = float(stats.get("total_crystals", 0))
		"total_chests":
			current = float(stats.get("total_chests", 0))
		"total_contracts":
			current = float(stats.get("total_contracts", 0))
		"survive_seconds":
			current = float(stats.get("best_survival", 0.0))
			value_type = "time"
		"survive_runs":
			current = float(stats.get("survive_10_runs", 0))
		"danger_time":
			current = float(stats.get("best_danger_time", 0.0))
			value_type = "time"
		"max_combo":
			current = float(stats.get("max_combo", 0))
		"weapon_level":
			current = float(save_data.get("weapon_highest_levels", {}).get(String(condition.get("weapon", "")), 0))
			target = float(condition.get("level", 1))
		"weapon_kills":
			current = float(save_data.get("weapon_kills", {}).get(String(condition.get("weapon", "")), 0))
		"boss_defeat":
			current = 1.0 if bool(save_data.get("boss_defeats", {}).get(String(condition.get("boss", "")), false)) else 0.0
			target = 1.0
		"evolved_weapon":
			current = 1.0 if bool(save_data.get("evolved_weapons", {}).get(String(condition.get("weapon", "")), false)) else 0.0
			target = 1.0
		"character_unlocked":
			current = 1.0 if (save_data.get("unlocked_characters", []) as Array).has(String(condition.get("character", ""))) else 0.0
			target = 1.0
		"shortcut_walls":
			current = float(stats.get("shortcut_walls_broken", 0))
		"rooms_discovered":
			current = float(stats.get("rooms_discovered", 0))
		"rooms_in_run":
			current = float(stats.get("max_rooms_in_run", 0))
		"cursed_relics":
			current = float(stats.get("cursed_relics", 0))
		"field_event_successes":
			current = float(stats.get("field_event_successes", 0))
		"field_drop_count":
			current = float(stats.get("field_drops_collected", 0))
		"gimmick_count", "gimmicks_triggered":
			current = float(stats.get("field_gimmicks_triggered", 0))
		"low_hp_time":
			current = float(stats.get("low_hp_time", 0.0))
			value_type = "time"
		"terrain_time":
			current = float(stats.get("terrain_time", {}).get(String(condition.get("terrain", "")), 0.0))
			value_type = "time"
		"terrain_kills":
			current = float(stats.get("terrain_kills", {}).get(String(condition.get("terrain", "")), 0))
		"terrain_crystals":
			current = float(stats.get("terrain_crystals", {}).get(String(condition.get("terrain", "")), 0))
		"terrain_boss_defeat":
			current = float(stats.get("terrain_boss_defeats", {}).get(String(condition.get("terrain", "")), 0))
			target = 1.0
		"exploration_chain":
			current = float(stats.get("max_exploration_chain", 0))
		"exploration_rank":
			current = float(_rank_value(String(stats.get("best_exploration_rank", "D"))))
			target = float(_rank_value(String(condition.get("rank", condition.get("value", "D")))))
			value_type = "rank"
		"oasis_healing":
			current = float(stats.get("oasis_healing", 0))
		"run_explosion_weapons":
			current = float(stats.get("run_explosion_weapons", 0))
		"specific_title":
			current = 1.0 if bool(save_data.get("titles", {}).get(String(condition.get("title", "")), false)) else 0.0
			target = 1.0
		"secret_ghost", "secret_reaper":
			current = 1.0 if bool(save_data.get("secret_flags", {}).get(type.trim_prefix("secret_"), false)) else 0.0
			target = 1.0
		"secret_void_mapper":
			current = minf(2.0, float(int(stats.get("max_rooms_in_run", 0)) >= 12) + float(_rank_value(String(stats.get("best_exploration_rank", "D"))) >= _rank_value("S")))
			target = 2.0
		"secret_abyss_merchant":
			current = minf(2.0, float(int(stats.get("total_currency_earned", 0)) >= 25000) + float(int(stats.get("total_contracts", 0)) >= 20))
			target = 2.0
		_:
			if stats.has(type):
				current = float(stats.get(type, 0.0))
			elif condition.is_empty():
				target = 1.0
	var ratio := clampf(current / maxf(1.0, target), 0.0, 1.0)
	return {
		"label": label,
		"current": current,
		"target": target,
		"ratio": ratio,
		"complete": current >= target,
		"value_type": value_type,
		"type": type
	}

func progress_list(save_data: Dictionary, condition: Dictionary) -> Array:
	var result: Array = []
	if condition.has("conditions"):
		for nested in condition.get("conditions", []):
			result.append(progress_for_condition(save_data, nested))
	else:
		result.append(progress_for_condition(save_data, condition))
	return result

func progress_text(save_data: Dictionary, condition: Dictionary) -> String:
	var lines: Array = []
	for progress in progress_list(save_data, condition):
		lines.append(formatter.format_progress(progress, true))
	return "\n".join(lines)

func _label_for(type: String, condition: Dictionary) -> String:
	match type:
		"total_kills": return "敵撃破"
		"total_gems_collected": return "ジェム取得"
		"total_crystals", "cursed_walls": return "結晶壁破壊"
		"total_chests": return "宝箱開封"
		"total_contracts": return "ルーン契約"
		"currency": return "所持クリスタル貨"
		"currency_paid", "total_currency_earned": return "累計クリスタル貨"
		"survive_seconds": return "生存時間"
		"survive_runs": return "10分以上生存"
		"danger_time": return "危険地帯生存"
		"max_combo": return "最大コンボ"
		"weapon_level": return "武器Lv"
		"weapon_kills": return "武器撃破"
		"boss_defeat": return "ボス撃破"
		"evolved_weapon": return "武器進化"
		"character_unlocked": return "キャラ解放"
		"shortcut_walls": return "近道壁破壊"
		"rooms_discovered", "rooms_in_run": return "部屋発見"
		"cursed_relics": return "呪いの遺物"
		"field_event_successes": return "イベント成功"
		"field_drop_count": return "フィールド報酬取得"
		"gimmick_count", "gimmicks_triggered": return "地形ギミック起動"
		"low_hp_time": return "低HP生存"
		"terrain_time": return "地形内生存"
		"terrain_kills": return "地形内撃破"
		"terrain_crystals": return "地形内結晶破壊"
		"terrain_boss_defeat": return "指定地形でボス撃破"
		"exploration_rank": return "探索ランク"
		"exploration_chain": return "探索チェーン"
		"oasis_healing": return "回復泉の回復量"
		"run_explosion_weapons": return "爆発系武器所持"
		"initial": return "初期解放"
	return String(condition.get("label_ja", "条件進捗"))

func _rank_value(rank: String) -> int:
	return maxi(0, ["D", "C", "B", "A", "S", "SS"].find(rank))
