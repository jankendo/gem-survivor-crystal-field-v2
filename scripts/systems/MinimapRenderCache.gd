extends RefCounted
class_name MinimapRenderCache

var availability = preload("res://scripts/systems/FieldObjectAvailabilitySystem.gd").new()
var commands: Array = []
var cache_key := ""
var rebuild_count := 0

func needs_rebuild(state, rect: Rect2, expanded: bool) -> bool:
	return cache_key != _key(state, rect, expanded)

func rebuild(state, rect: Rect2, expanded: bool) -> Array:
	cache_key = _key(state, rect, expanded)
	commands.clear()
	rebuild_count += 1
	var scale := Vector2(rect.size.x / state.field_size.x, rect.size.y / state.field_size.y)
	commands.append({"kind": "background", "rect": rect})
	for corridor in state.map_data.get("corridors", []):
		var visible: bool = (
			state.explored_room_ids.has(String(corridor.get("from", "")))
			or state.explored_room_ids.has(String(corridor.get("to", "")))
		)
		if not visible:
			continue
		for rect_data in corridor.get("rects", []):
			var pos := rect.position + (rect_data.get("position", Vector2.ZERO) as Vector2) * scale
			var corridor_size: Vector2 = rect_data.get("size", Vector2.ZERO)
			commands.append({
				"kind": "rect",
				"rect": Rect2(pos - corridor_size * scale * 0.5, corridor_size * scale),
				"color": Color(0.38, 0.66, 0.78, 0.50),
			})
	for room in state.map_data.get("rooms", []):
		var room_id := String(room.get("id", ""))
		var explored: bool = state.explored_room_ids.has(room_id)
		var pos := rect.position + (room.get("position", Vector2.ZERO) as Vector2) * scale
		var room_size: Vector2 = room.get("size", Vector2.ZERO)
		var terrain_id := String(room.get("terrain_id", "safe_room"))
		var terrain_data: Dictionary = state.terrain_type_defs.get(terrain_id, {})
		var color := _data_color(terrain_data, Color(0.28, 0.42, 0.50))
		commands.append({
			"kind": "room",
			"rect": Rect2(pos - room_size * scale * 0.5, room_size * scale),
			"color": Color(color.r, color.g, color.b, 0.76) if explored else Color(0.12, 0.14, 0.18, 0.48),
			"border": Color(0.58, 0.82, 0.92, 0.42) if explored else Color(0.32, 0.36, 0.42, 0.35),
			"important": bool(room.get("important", false)),
			"explored": explored,
			"terrain_id": terrain_id,
			"pos": pos,
			"color_text": color.lightened(0.35) if explored else Color(0.54, 0.56, 0.62),
		})
	for wall in state.crystal_walls:
		var pos: Vector2 = rect.position + wall.position * scale
		var wall_size := Vector2(maxf(1.0, wall.size.x * scale.x), maxf(1.0, wall.size.y * scale.y))
		commands.append({
			"kind": "rect",
			"rect": Rect2(pos - wall_size * 0.5, wall_size),
			"color": Color(1.0, 0.78, 0.24, 0.90) if wall.breakable else Color(0.42, 0.48, 0.56, 0.72),
		})
	for zone in state.danger_zones:
		commands.append({
			"kind": "circle",
			"pos": rect.position + (zone.get("position", Vector2.ZERO) as Vector2) * scale,
			"radius": maxf(4.0, float(zone.get("radius", 0.0)) * scale.x),
			"color": Color(1.0, 0.12, 0.42, 0.18),
		})
	for chest in state.chests:
		var pos: Vector2 = rect.position + chest.position * scale
		commands.append({"kind": "chest", "pos": pos, "rarity": String(chest.rarity)})
	for drop in state.field_drops:
		if availability.is_available_now(state, drop, "collected"):
			commands.append({
				"kind": _drop_kind(drop),
				"pos": rect.position + (drop.get("position", Vector2.ZERO) as Vector2) * scale,
				"radius": 0.45,
				"icon_scale": true,
				"color": _data_color(drop, Color.WHITE),
			})
	for equipment in state.field_equipment:
		if availability.is_available_now(state, equipment, "collected"):
			commands.append({
				"kind": "equipment",
				"pos": rect.position + (equipment.get("position", Vector2.ZERO) as Vector2) * scale,
				"color": _data_color(equipment, Color(0.72, 0.92, 1.0)),
			})
	for gimmick in state.field_gimmicks:
		if availability.is_available_now(state, gimmick, "destroyed"):
			commands.append({
				"kind": "gimmick",
				"pos": rect.position + (gimmick.get("position", Vector2.ZERO) as Vector2) * scale,
				"color": _data_color(gimmick, Color.WHITE),
			})
	var boss = state.active_boss()
	if boss != null:
		commands.append({"kind": "boss", "pos": rect.position + boss.position * scale})
	elif state.boss_warning_timer > 0.0:
		commands.append({"kind": "boss", "pos": rect.position + state.boss_room_position() * scale})
	commands.append({"kind": "player", "pos": rect.position + state.player_position * scale})
	return commands

func invalidate() -> void:
	cache_key = ""
	commands.clear()

func _key(state, rect: Rect2, expanded: bool) -> String:
	return "%s|%s|%d|%d|%d|%d|%d|%d|%d|%d" % [
		str(rect),
		str(expanded),
		state.explored_room_ids.hash(),
		state.crystal_walls.size(),
		state.danger_zones.size(),
		state.chests.size(),
		state.field_drops.size(),
		state.field_equipment.size(),
		state.field_gimmicks.size(),
		_availability_signature(state),
	]

func _availability_signature(state) -> int:
	var rows: Array = []
	for drop in state.field_drops:
		rows.append("%s:%s" % [drop.get("runtime_id", drop.get("id", "")), availability.is_available_now(state, drop, "collected")])
	for equipment in state.field_equipment:
		rows.append("%s:%s" % [equipment.get("runtime_id", equipment.get("id", "")), availability.is_available_now(state, equipment, "collected")])
	for gimmick in state.field_gimmicks:
		rows.append("%s:%s" % [gimmick.get("runtime_id", gimmick.get("id", "")), availability.is_available_now(state, gimmick, "destroyed")])
	return rows.hash()

func _drop_kind(drop: Dictionary) -> String:
	match String(drop.get("id", "")):
		"weapon_core":
			return "weapon_core"
		"passive_core":
			return "passive_core"
	return "circle"

func _data_color(data: Dictionary, fallback: Color) -> Color:
	var raw = data.get("color", data.get("fallback_color", []))
	if raw is Array and raw.size() >= 3:
		return Color(float(raw[0]), float(raw[1]), float(raw[2]), float(raw[3]) if raw.size() >= 4 else fallback.a)
	if raw is String and Color.html_is_valid(String(raw)):
		return Color(String(raw))
	return fallback
