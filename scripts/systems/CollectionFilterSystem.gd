extends RefCounted
class_name CollectionFilterSystem

const FILTER_IDS := ["all", "unlocked", "locked", "secret", "melee", "ranged", "lightning", "poison", "explosion", "crystal", "explore", "currency", "evolvable", "not_evolved"]
const FILTER_NAMES := ["すべて", "解放済み", "未解放", "シークレット", "近接", "遠距離", "雷", "毒", "爆発", "結晶", "探索", "通貨", "進化可能", "未進化"]
const SORT_IDS := ["unlock", "category", "highest_level", "acquired"]
const SORT_NAMES := ["解放状態", "系統", "最高Lv", "取得回数"]

func filter_rows(rows: Array, filter_id: String) -> Array:
	if filter_id == "all":
		return rows.duplicate()
	var result: Array = []
	for row in rows:
		var tags: Array = row.get("tags", [])
		var include = false
		match filter_id:
			"unlocked":
				include = bool(row.get("unlocked", false))
			"locked":
				include = not bool(row.get("unlocked", false))
			"secret":
				include = bool(row.get("secret", false))
			"evolvable":
				include = bool(row.get("evolvable", false)) and not bool(row.get("evolved", false))
			"not_evolved":
				include = bool(row.get("evolvable", false)) and not bool(row.get("evolved", false))
			_:
				include = tags.has(filter_id) or String(row.get("category", "")) == filter_id
		if include:
			result.append(row)
	return result

func sort_rows(rows: Array, sort_id: String) -> Array:
	var result = rows.duplicate()
	match sort_id:
		"category":
			result.sort_custom(func(a, b): return String(a.get("category", "")) + String(a.get("name_ja", "")) < String(b.get("category", "")) + String(b.get("name_ja", "")))
		"highest_level":
			result.sort_custom(func(a, b): return int(a.get("highest_level", 0)) > int(b.get("highest_level", 0)))
		"acquired":
			result.sort_custom(func(a, b): return int(a.get("acquired_count", 0)) > int(b.get("acquired_count", 0)))
		_:
			result.sort_custom(func(a, b): return int(bool(a.get("unlocked", false))) > int(bool(b.get("unlocked", false))))
	return result
