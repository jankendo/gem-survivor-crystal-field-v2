extends RefCounted
class_name TooltipSystem

func format_field_help(entry: Dictionary, scanned: bool = false) -> String:
	if entry.is_empty():
		return ""
	var lines: Array = [String(entry.get("name_ja", "不明な対象"))]
	lines.append(String(entry.get("effect_ja", "")))
	if scanned:
		lines.append("対処：%s" % String(entry.get("approach_ja", "状況を見て判断")))
		lines.append("報酬：%s" % String(entry.get("reward_ja", "なし")))
		lines.append("おすすめ：%s" % String(entry.get("build_ja", "全ビルド")))
		lines.append("危険度：%s" % danger_meter(int(entry.get("danger", 1))))
	else:
		lines.append(String(entry.get("approach_ja", "")))
		lines.append("F / 右クリック：詳しくスキャン")
	return "\n".join(lines)

func danger_meter(value: int) -> String:
	var clamped = clampi(value, 1, 5)
	return "●".repeat(clamped) + "○".repeat(5 - clamped)

