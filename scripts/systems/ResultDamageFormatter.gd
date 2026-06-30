extends RefCounted
class_name ResultDamageFormatter

const JaText = preload("res://scripts/ui/JaText.gd")

func weapon_damage_lines(summary: Dictionary, limit: int = 8) -> Array:
	var damage: Dictionary = summary.get("weapon_damage_by_id", {})
	if damage.is_empty():
		return ["武器別ダメージ：記録なし"]
	var defs := _json_dict("res://data/weapons.json", {})
	var rows: Array = []
	var total := 0
	for raw_id in damage.keys():
		total += int(damage[raw_id])
	for raw_id in damage.keys():
		var id := String(raw_id)
		var value := int(damage[raw_id])
		rows.append({
			"id": id,
			"name": String(defs.get(id, {}).get("name_ja", id)),
			"damage": value,
			"percent": 100.0 * float(value) / float(maxi(1, total))
		})
	rows.sort_custom(func(a, b): return int(a.get("damage", 0)) > int(b.get("damage", 0)))
	var lines := ["武器別ダメージ"]
	var count = mini(limit, rows.size())
	for i in range(count):
		var row: Dictionary = rows[i]
		lines.append("%d. %s　%s（%.1f%%）" % [
			i + 1,
			String(row.get("name", "")),
			JaText.format_int(int(row.get("damage", 0))),
			float(row.get("percent", 0.0))
		])
	return lines

func _json_dict(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback.duplicate(true)
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else fallback.duplicate(true)
