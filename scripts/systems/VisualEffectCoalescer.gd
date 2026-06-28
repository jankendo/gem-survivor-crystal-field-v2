extends RefCounted
class_name VisualEffectCoalescer

const DEFAULT_WINDOW_SECONDS := 0.06
const DEFAULT_CELL_SIZE := 48.0

func find_match(
		items: Array,
		data: Dictionary,
		now_seconds: float,
		window_seconds: float = DEFAULT_WINDOW_SECONDS,
		cell_size: float = DEFAULT_CELL_SIZE
	) -> int:
	var source := String(data.get("source", data.get("weapon_id", "")))
	var effect_kind := String(data.get("effect_kind", data.get("kind", "effect")))
	var pos := _position(data)
	var cell := _cell(pos, cell_size)
	for index in range(items.size() - 1, -1, -1):
		var candidate: Dictionary = items[index]
		if now_seconds - float(candidate.get("created_at", now_seconds)) > window_seconds:
			break
		if String(candidate.get("source", candidate.get("weapon_id", ""))) != source:
			continue
		if String(candidate.get("effect_kind", candidate.get("kind", "effect"))) != effect_kind:
			continue
		if _cell(_position(candidate), cell_size) == cell:
			return index
	return -1

func merge(target: Dictionary, incoming: Dictionary) -> void:
	target["life"] = maxf(float(target.get("life", 0.0)), float(incoming.get("life", 0.0)))
	target["radius"] = maxf(float(target.get("radius", 0.0)), float(incoming.get("radius", 0.0)))
	target["line_width"] = maxf(float(target.get("line_width", 0.0)), float(incoming.get("line_width", 0.0)))
	target["brightness"] = minf(1.35, maxf(float(target.get("brightness", 1.0)), float(incoming.get("brightness", 1.0))) + 0.08)
	target["coalesced_count"] = int(target.get("coalesced_count", 1)) + int(incoming.get("coalesced_count", 1))
	if incoming.has("text") and String(incoming.get("text", "")).is_valid_int():
		var existing := String(target.get("text", ""))
		if existing.is_valid_int():
			target["text"] = str(int(existing) + int(String(incoming["text"])))

func key_for(data: Dictionary, cell_size: float = DEFAULT_CELL_SIZE) -> String:
	var cell := _cell(_position(data), cell_size)
	return "%s|%s|%d|%d" % [
		String(data.get("source", data.get("weapon_id", ""))),
		String(data.get("effect_kind", data.get("kind", "effect"))),
		cell.x,
		cell.y
	]

func _position(data: Dictionary) -> Vector2:
	return data.get("pos", data.get("position", data.get("start", Vector2.ZERO)))

func _cell(pos: Vector2, cell_size: float) -> Vector2i:
	var safe_cell := maxf(1.0, cell_size)
	return Vector2i(floori(pos.x / safe_cell), floori(pos.y / safe_cell))

