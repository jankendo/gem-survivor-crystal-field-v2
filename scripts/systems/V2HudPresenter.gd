extends RefCounted
class_name V2HudPresenter

const JaText = preload("res://scripts/ui/JaText.gd")

func top_hud_suffix(state) -> String:
	return "　スコア %s　結晶 %s" % [
		JaText.format_int(int(state.score)),
		JaText.format_int(int(state.crystals_destroyed))
	]

func build_focus_text(state) -> String:
	var parts: Array = []
	parts.append("主力 %s" % state.max_weapon_label())
	if state.has_available_evolution():
		parts.append("進化候補あり")
	if not state.active_synergies.is_empty():
		parts.append("相性 %s" % state.active_synergy_label())
	if int(state.evolved_weapon_count) > 0:
		parts.append("進化%d" % int(state.evolved_weapon_count))
	return "　".join(parts)

func momentum_text(state) -> String:
	if float(state.v2_momentum_timer) <= 0.0:
		if int(state.v2_kill_streak) >= 10:
			return "連続撃破 %d" % int(state.v2_kill_streak)
		return ""
	return "%s %.0fs x%.2f" % [
		String(state.v2_momentum_label),
		float(state.v2_momentum_timer),
		float(state.v2_momentum_score_multiplier)
	]

func result_highlights(summary: Dictionary) -> Array:
	var highlights: Array = []
	var peak_tier := int(summary.get("v2_peak_momentum_tier", 0))
	var triggers := int(summary.get("v2_momentum_triggers", 0))
	if peak_tier > 0 or triggers > 0:
		highlights.append("v2 Momentum：最高Tier%d / 発動%d回" % [peak_tier, triggers])
	var best_streak := int(summary.get("v2_best_kill_streak", 0))
	if best_streak > 0:
		highlights.append("最大連続撃破：%d" % best_streak)
	var no_damage := float(summary.get("v2_no_damage_best", 0.0))
	if no_damage >= 30.0:
		highlights.append("最長無被弾：%s" % JaText.format_time(no_damage))
	var synergy_value = summary.get("synergy_history", [])
	var synergy_count: int = synergy_value.size() if synergy_value is Array else 0
	var build_line := "今回のビルド：%s / 進化%d / 相性%d" % [
		String(summary.get("max_weapon", "魔弾 Lv1")),
		int(summary.get("evolved_weapon_count", 0)),
		synergy_count
	]
	highlights.append(build_line)
	return highlights
