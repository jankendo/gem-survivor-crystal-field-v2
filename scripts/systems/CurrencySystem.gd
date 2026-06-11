extends RefCounted
class_name CurrencySystem

func calculate_run_currency(summary: Dictionary, save_data: Dictionary = {}, character_data: Dictionary = {}) -> int:
	var survival_minutes = floor(float(summary.get("survival_time", 0.0)) / 60.0)
	var amount = int(survival_minutes * 10.0)
	amount += int(floor(float(summary.get("kills", 0)) / 20.0))
	amount += int(summary.get("boss_defeats", 0)) * 50
	amount += int(summary.get("chests_opened", 0)) * 25
	amount += int(summary.get("evolved_weapon_count", 0)) * 100
	amount += (summary.get("rune_contracts", []) as Array).size() * 40
	amount += (summary.get("title_badges", []) as Array).size() * 20
	amount += int(summary.get("field_event_successes", 0)) * 45
	amount += int(summary.get("rooms_discovered", 0)) * 3
	var upgrade_levels: Dictionary = save_data.get("meta_upgrades", {})
	var currency_level = int(upgrade_levels.get("currency", 0))
	var multiplier = 1.0 + float(currency_level) * 0.03
	multiplier *= float(character_data.get("modifiers", {}).get("currency_mult", 1.0))
	multiplier *= 1.0 + float(summary.get("exploration_currency_bonus", 0.0))
	var sink_levels: Dictionary = save_data.get("currency_sink_levels", {})
	if int(sink_levels.get("difficulty_mark_1", 0)) > 0:
		multiplier *= 1.12
	if int(sink_levels.get("difficulty_mark_2", 0)) > 0:
		multiplier *= 1.28
	if int(sink_levels.get("difficulty_curse_run", 0)) > 0:
		multiplier *= 1.18
	var chain_bonus = int(summary.get("exploration_chain_currency_bonus", 0))
	return maxi(0, int(round(float(amount) * multiplier)) + chain_bonus)
