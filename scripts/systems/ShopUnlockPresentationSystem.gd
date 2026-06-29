extends RefCounted
class_name ShopUnlockPresentationSystem

const EntitlementScript = preload("res://scripts/systems/ShopEntitlementSystem.gd")
const ProgressScript = preload("res://scripts/systems/ProgressTrackerSystem.gd")

var entitlement = EntitlementScript.new()
var progress = ProgressScript.new()
var evolutions: Dictionary = {}

func _init() -> void:
	evolutions = _json("res://data/evolutions.json")

func card(save_data: Dictionary, kind: String, id: String, item: Dictionary, cost: int) -> Dictionary:
	var condition := entitlement.condition_for(kind, id)
	var purchased := entitlement.is_usable(save_data, kind, id)
	var available := entitlement.is_available_for_purchase(save_data, kind, id)
	var currency := int(save_data.get("crystal_currency", 0))
	var disabled_key := "disabled_weapons" if kind == "weapon" else "disabled_passives"
	var enabled := not (save_data.get(disabled_key, []) as Array).has(id)
	var lines: Array = [
		"【%s】%s" % ["購入済み" if purchased else "未解放", String(item.get("name_ja", id))],
		"",
		"種別：%s" % ("武器" if kind == "weapon" else "パッシブ"),
		"効果：%s" % String(item.get("description_ja", "ラン内候補を永久解放します。")),
		"永久解放：購入すると、以後のランでレベルアップ・%sコア候補に出現します。" % ("武器" if kind == "weapon" else "パッシブ"),
		"",
		"解放条件：",
	]
	var condition_rows := progress.progress_list(save_data, condition)
	for index in range(condition_rows.size()):
		var row: Dictionary = condition_rows[index]
		var current := float(row.get("current", 0.0))
		var target := float(row.get("target", 1.0))
		var unit := "秒" if String(row.get("value_type", "")) == "time" else ""
		lines.append("条件%s：%s　現在 %s / %s%s　あと %s%s" % [
			_roman(index),
			String(row.get("label", "条件")),
			_display_value(current, row),
			_display_value(target, row),
			unit,
			_display_value(maxf(0.0, target - current), row),
			unit,
		])
	if condition.has("conditions"):
		lines.append("判定：%s条件" % ("OR" if String(condition.get("mode", "and")).to_lower() == "or" else "AND"))
	lines.append("")
	lines.append("購入費用：%dクリスタル貨" % cost)
	lines.append("所持：%dクリスタル貨" % currency)
	lines.append("通貨不足：%dクリスタル貨" % maxi(0, cost - currency))
	var evolution := _evolution_for(kind, id)
	if evolution != "":
		lines.append("進化：%s" % evolution)
	var status := "購入済み・現在%s" % ("ON" if enabled else "OFF") if purchased else ("条件達成済み・購入可能" if available and currency >= cost else "購入不可")
	lines.append("状態：%s" % status)
	var reason := ""
	if not purchased and not available:
		reason = "解放条件が未達成です。"
	elif not purchased and currency < cost:
		reason = "クリスタル貨が%d不足しています。" % (cost - currency)
	elif purchased:
		reason = "購入済みです。"
	lines.append("購入ボタン：%s" % ("押せます" if reason == "" else reason))
	return {
		"text": "\n".join(lines),
		"purchased": purchased,
		"available": available,
		"currency_ok": currency >= cost,
		"button_reason": reason,
	}

func _evolution_for(kind: String, id: String) -> String:
	if kind != "weapon":
		for evolution in evolutions.values():
			if String(evolution.get("passive", "")) == id:
				return "関連素材：%s" % String(evolution.get("name_ja", "進化武器"))
		return ""
	for evolution in evolutions.values():
		if String(evolution.get("weapon", "")) == id:
			return "%s / 必要パッシブ：%s" % [
				String(evolution.get("name_ja", "進化武器")),
				String(evolution.get("passive", "なし")),
			]
	return ""

func _display_value(value: float, row: Dictionary) -> String:
	if String(row.get("value_type", "")) == "time":
		var total := maxi(0, int(round(value)))
		return "%d:%02d" % [total / 60, total % 60]
	return str(int(round(value)))

func _roman(index: int) -> String:
	return ["A", "B", "C", "D"][clampi(index, 0, 3)]

func _json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
