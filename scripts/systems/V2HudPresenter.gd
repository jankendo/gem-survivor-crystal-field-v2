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
	return "ラッシュ %s  残り %.1f秒  x%.2f" % [
		_roman_tier(int(state.v2_momentum_tier)),
		float(state.v2_momentum_timer),
		float(state.v2_momentum_score_multiplier)
	]

func momentum_panel_text(state) -> String:
	if float(state.v2_momentum_timer) <= 0.0:
		return ""
	var reason := String(state.v2_momentum_reason)
	if reason == "":
		reason = String(state.v2_momentum_label)
	return "ラッシュ %s\n残り %.1f秒\nx%.2f  %s" % [
		_roman_tier(int(state.v2_momentum_tier)),
		float(state.v2_momentum_timer),
		float(state.v2_momentum_score_multiplier),
		reason
	]

func result_highlights(summary: Dictionary) -> Array:
	var highlights: Array = []
	var peak_tier := int(summary.get("v2_peak_momentum_tier", 0))
	var triggers := int(summary.get("v2_momentum_triggers", 0))
	if peak_tier > 0 or triggers > 0:
		highlights.append("ラッシュ：最高%s / 発動%d回 / 合計%s / +%s" % [
			_roman_tier(peak_tier),
			triggers,
			JaText.format_time(float(summary.get("v2_momentum_active_time_total", 0.0))),
			JaText.format_int(int(summary.get("v2_momentum_score_bonus", 0)))
		])
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

func momentum_result_lines(summary: Dictionary) -> Array:
	var lines: Array = []
	var counts: Dictionary = summary.get("v2_momentum_trigger_counts", {})
	lines.append("ラッシュ最高段階：%s" % _roman_tier(int(summary.get("v2_peak_momentum_tier", 0))))
	lines.append("ラッシュ発動：%d回 / 合計%s" % [
		int(summary.get("v2_momentum_triggers", 0)),
		JaText.format_time(float(summary.get("v2_momentum_active_time_total", 0.0)))
	])
	lines.append("ラッシュスコア：+%s" % JaText.format_int(int(summary.get("v2_momentum_score_bonus", 0))))
	lines.append("最多発動要因：%s" % _trigger_label(String(summary.get("v2_momentum_main_trigger", ""))))
	lines.append("重複通知抑止：%d" % int(summary.get("v2_momentum_suppressed_duplicates", 0)))
	if not counts.is_empty():
		var parts: Array = []
		for key in counts.keys():
			parts.append("%s %d" % [_trigger_label(String(key)), int(counts[key])])
		lines.append("発動内訳：%s" % " / ".join(parts))
	return lines

func _roman_tier(tier: int) -> String:
	match tier:
		1:
			return "I"
		2:
			return "II"
		3:
			return "III"
		_:
			return "0"

func _trigger_label(trigger_type: String) -> String:
	match trigger_type:
		"kill_streak":
			return "連続撃破"
		"no_damage":
			return "無被弾"
		"boss_defeat":
			return "ボス撃破"
		"evolution":
			return "武器進化"
		"global_gem_collection":
			return "全ジェム回収"
		"build_synergy":
			return "ビルド相性"
		"field_event_success":
			return "イベント成功"
		_:
			return "なし" if trigger_type == "" else trigger_type
