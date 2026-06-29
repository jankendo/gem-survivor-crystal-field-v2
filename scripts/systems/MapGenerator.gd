extends RefCounted
class_name MapGenerator

const CrystalWallScript = preload("res://scripts/core/CrystalWall.gd")
const RunRngScript = preload("res://scripts/core/RunRng.gd")
const ProceduralMapSystemScript = preload("res://scripts/systems/ProceduralMapSystem.gd")
const FieldEquipmentRewardSystemScript = preload("res://scripts/systems/FieldEquipmentRewardSystem.gd")
const ItemPlacementSystemScript = preload("res://scripts/systems/ItemPlacementSystem.gd")

var procedural_map_system = ProceduralMapSystemScript.new()
var field_equipment_reward_system = FieldEquipmentRewardSystemScript.new()
var item_placement_system = ItemPlacementSystemScript.new()
var tile_collision = preload("res://scripts/systems/TileCollisionSystem.gd").new()

func seed_value_from_text(seed_text: String, fallback: int = 0) -> int:
	var text = seed_text.strip_edges()
	if text == "":
		return fallback if fallback != 0 else int(Time.get_unix_time_from_system())
	var value = int(text.hash())
	if value == 0:
		value = 1
	return abs(value)

func generate(state, seed_text: String = "", fallback_seed: int = 0) -> Dictionary:
	var seed_value = seed_value_from_text(seed_text, fallback_seed)
	var rng = RunRngScript.new()
	rng.set_seed_value(seed_value)
	var center = state.field_size * 0.5
	var generation_config = _json_dict("res://data/map_generation.json", {})
	var room_config = _json_dict("res://data/terrain_rooms.json", {})
	var layout = procedural_map_system.generate_layout(state, rng, generation_config, room_config)
	state.field_size = Vector2(
		float(layout.get("grid_width", 120)) * float(layout.get("tile_size", 64)),
		float(layout.get("grid_height", 120)) * float(layout.get("tile_size", 64))
	)
	center = state.field_size * 0.5
	var map = {
		"seed": seed_value,
		"seed_text": seed_text if seed_text.strip_edges() != "" else str(seed_value),
		"biomes": _generate_biomes(state.field_size, rng),
		"danger_zones": _danger_zones_from_rooms(layout.get("rooms", []), rng),
		"wall_specs": layout.get("wall_specs", []),
		"rooms": layout.get("rooms", []),
		"connections": layout.get("connections", []),
		"corridors": layout.get("corridors", []),
		"shortcut_walls": layout.get("shortcut_walls", []),
		"important_room_ids": layout.get("important_room_ids", []),
		"connected": bool(layout.get("connected", false)),
		"important_reachable": bool(layout.get("important_reachable", false)),
		"decorations": [],
		"field_drops": [],
		"field_gimmicks": [],
		"field_equipment": [],
		"navigation_targets": {},
		"safe_radius": float(generation_config.get("safe_radius", 600.0)),
		"open_corridors": int(layout.get("open_corridors", 4)),
		"grid_width": int(layout.get("grid_width", 120)),
		"grid_height": int(layout.get("grid_height", 120)),
		"tile_size": int(layout.get("tile_size", 64)),
		"walkable_lookup": layout.get("walkable_lookup", {}),
		"walkable_cells": layout.get("walkable_cells", []),
		"boundary_cells": layout.get("boundary_cells", []),
		"room_shape_count": int(layout.get("room_shape_count", 0)),
		"corridor_shape_count": int(layout.get("corridor_shape_count", 0)),
		"walkable_ratio": float(layout.get("walkable_ratio", 0.0)),
		"branch_count": int(layout.get("branch_count", 0)),
		"loop_count": int(layout.get("loop_count", 0)),
		"cross_like": bool(layout.get("cross_like", false))
	}
	map["decorations"] = _generate_decorations(map, center, rng)
	map["field_drops"] = _generate_field_drops(state, map, rng)
	map["field_gimmicks"] = _generate_field_gimmicks(state, map, rng)
	map["field_equipment"] = field_equipment_reward_system.generate_for_map(state, map, rng)
	map["navigation_targets"] = _navigation_targets(map)
	return map

func build_walls(state, map_data: Dictionary) -> Array:
	var walls: Array = []
	var specs: Array = map_data.get("wall_specs", []).duplicate()
	specs.sort_custom(func(a, b): return bool(a.get("breakable", true)) and not bool(b.get("breakable", true)))
	for spec in specs:
		var pos: Vector2 = spec.get("position", state.field_size * 0.5)
		var wall = CrystalWallScript.new(
			String(spec.get("id", "wall")),
			pos,
			spec.get("size", Vector2(140, 80)),
			int(spec.get("hp", 60)),
			bool(spec.get("breakable", true)),
			String(spec.get("kind", "generated")),
			String(spec.get("type", "small_crystal")),
			String(spec.get("biome", "star_plain"))
		)
		wall.rescale_hp(float(spec.get("hp_mult", 1.0)))
		walls.append(wall)
	return walls

func signature(map_data: Dictionary) -> String:
	var parts: Array = [str(int(map_data.get("seed", 0)))]
	for zone in map_data.get("danger_zones", []):
		var p: Vector2 = zone.get("position", Vector2.ZERO)
		parts.append("%d:%d:%d" % [int(p.x), int(p.y), int(zone.get("radius", 0))])
	for room in map_data.get("rooms", []):
		var p: Vector2 = room.get("position", Vector2.ZERO)
		var s: Vector2 = room.get("size", Vector2.ZERO)
		parts.append("r:%s:%s:%d:%d:%d:%d" % [String(room.get("id", "")), String(room.get("terrain_id", "")), int(p.x), int(p.y), int(s.x), int(s.y)])
	for corridor in map_data.get("corridors", []):
		parts.append("c:%s:%s" % [String(corridor.get("from", "")), String(corridor.get("to", ""))])
	for wall in map_data.get("wall_specs", []):
		var p: Vector2 = wall.get("position", Vector2.ZERO)
		var s: Vector2 = wall.get("size", Vector2.ZERO)
		parts.append("%d:%d:%d:%d:%s" % [int(p.x), int(p.y), int(s.x), int(s.y), String(wall.get("type", ""))])
	for drop in map_data.get("field_drops", []):
		var p: Vector2 = drop.get("position", Vector2.ZERO)
		parts.append("d:%s:%d:%d" % [String(drop.get("id", "")), int(p.x), int(p.y)])
	for gimmick in map_data.get("field_gimmicks", []):
		var p: Vector2 = gimmick.get("position", Vector2.ZERO)
		parts.append("g:%s:%d:%d" % [String(gimmick.get("id", "")), int(p.x), int(p.y)])
	for equipment in map_data.get("field_equipment", []):
		var p: Vector2 = equipment.get("position", Vector2.ZERO)
		parts.append("e:%s:%s:%d:%d" % [String(equipment.get("kind", "")), String(equipment.get("id", "")), int(p.x), int(p.y)])
	return "|".join(parts)

func start_area_is_safe(map_data: Dictionary, center: Vector2) -> bool:
	var safe_radius = float(map_data.get("safe_radius", 560.0))
	for zone in map_data.get("danger_zones", []):
		if (zone.get("position", Vector2.ZERO) as Vector2).distance_to(center) < safe_radius + float(zone.get("radius", 0.0)) * 0.45:
			return false
	for wall in map_data.get("wall_specs", []):
		if String(wall.get("kind", "")) != "structural" and (wall.get("position", Vector2.ZERO) as Vector2).distance_to(center) < safe_radius:
			return false
	return true

func _danger_zones_from_rooms(rooms: Array, rng) -> Array:
	var zones: Array = []
	for room in rooms:
		if String(room.get("terrain_id", "")) != "danger_den":
			continue
		var size: Vector2 = room.get("size", Vector2(700, 600))
		zones.append({
			"id": "danger_%s" % String(room.get("id", "")),
			"position": room.get("position", Vector2.ZERO),
			"radius": minf(size.x, size.y) * rng.range_float(0.34, 0.43),
			"biome": _biome_for_quadrant(room.get("position", Vector2.ZERO), rooms[0].get("position", Vector2.ONE) * 2.0)
		})
	while zones.size() < 4:
		var fallback: Dictionary = rooms[mini(rooms.size() - 1, 3 + zones.size() * 2)]
		var fallback_size: Vector2 = fallback.get("size", Vector2(700, 600))
		zones.append({
			"id": "danger_aux_%d" % zones.size(),
			"position": fallback.get("position", Vector2.ZERO),
			"radius": minf(fallback_size.x, fallback_size.y) * 0.30,
			"biome": "star_plain"
		})
	return zones

func _generate_biomes(field_size: Vector2, rng) -> Dictionary:
	var jitter_x = rng.range_float(-0.08, 0.08)
	var jitter_y = rng.range_float(-0.08, 0.08)
	return {
		"star_plain": {"rect": [0.0, 0.0, 0.56 + jitter_x, 0.56 + jitter_y]},
		"amethyst_forest": {"rect": [0.48 + jitter_x * 0.4, 0.0, 0.52 - jitter_x * 0.4, 0.58 + jitter_y * 0.3]},
		"red_mine": {"rect": [0.0, 0.50 + jitter_y * 0.4, 0.58 + jitter_x * 0.2, 0.50 - jitter_y * 0.4]},
		"void_zone": {"rect": [0.52 + jitter_x * 0.2, 0.52 + jitter_y * 0.2, 0.48, 0.48]}
	}

func _generate_danger_zones(field_size: Vector2, center: Vector2, rng) -> Array:
	var zones: Array = []
	var base_angles = [0.70, 2.28, 3.85, 5.42]
	var names = ["danger_amethyst", "danger_west", "danger_mine", "danger_void"]
	for i in range(base_angles.size()):
		var angle = float(base_angles[i]) + rng.range_float(-0.28, 0.28)
		var distance = rng.range_float(1850.0, 2550.0)
		var pos = center + Vector2(cos(angle), sin(angle)) * distance
		pos.x = clampf(pos.x, 720.0, field_size.x - 720.0)
		pos.y = clampf(pos.y, 720.0, field_size.y - 720.0)
		zones.append({
			"id": names[i],
			"position": pos,
			"radius": rng.range_float(420.0, 700.0),
			"biome": _biome_for_quadrant(pos, field_size)
		})
	return zones

func _generate_walls(field_size: Vector2, center: Vector2, rng) -> Array:
	var walls: Array = []
	var id = 0
	var corridor_angles = [0.0, PI * 0.5, PI, PI * 1.5]
	for ring in range(4):
		var distance = 760.0 + float(ring) * 640.0
		var count = 6 + ring * 2
		for i in range(count):
			var angle = TAU * (float(i) / float(count)) + rng.range_float(-0.18, 0.18)
			if _near_corridor(angle, corridor_angles):
				continue
			var pos = center + Vector2(cos(angle), sin(angle)) * (distance + rng.range_float(-180.0, 190.0))
			pos.x = clampf(pos.x, 220.0, field_size.x - 220.0)
			pos.y = clampf(pos.y, 220.0, field_size.y - 220.0)
			if pos.distance_to(center) < 620.0:
				continue
			id += 1
			var t = _wall_type_for_distance(pos.distance_to(center), rng)
			walls.append({
				"id": "map_cw_%02d" % id,
				"position": pos,
				"size": Vector2(rng.range_float(90.0, 380.0), rng.range_float(64.0, 130.0)),
				"hp": int(rng.range_int(42 + ring * 12, 82 + ring * 28)),
				"type": t,
				"biome": _biome_for_quadrant(pos, field_size),
				"hp_mult": 1.0 + float(ring) * 0.22
			})
	return walls

func _generate_decorations(map_data: Dictionary, center: Vector2, rng) -> Array:
	var decorations: Array = []
	for i in range(64):
		var p = tile_collision.random_walkable_position(map_data, rng, center, 420.0, 99999.0)
		if p.distance_to(center) < 420.0:
			continue
		decorations.append({"position": p, "kind": "crystal_spark", "radius": rng.range_float(1.4, 4.5), "phase": rng.range_float(0.0, TAU)})
	return decorations

func _navigation_targets(map_data: Dictionary) -> Dictionary:
	var danger = map_data.get("danger_zones", [])
	var walls = map_data.get("wall_specs", [])
	var result = {}
	for room in map_data.get("rooms", []):
		var terrain_id = String(room.get("terrain_id", ""))
		if terrain_id == "healing_oasis":
			result["healing_oasis"] = room.get("position", Vector2.ZERO)
		elif terrain_id == "boss_arena":
			result["boss_arena"] = room.get("position", Vector2.ZERO)
		elif terrain_id == "event_room":
			result["event_room"] = room.get("position", Vector2.ZERO)
		elif terrain_id in ["relic_vault", "sealed_room"]:
			result[terrain_id] = room.get("position", Vector2.ZERO)
	if not danger.is_empty():
		result["danger"] = danger[0].get("position", Vector2.ZERO)
	if not walls.is_empty():
		result["crystal_cluster"] = walls[0].get("position", Vector2.ZERO)
	if danger.size() > 1:
		result["field_event"] = danger[1].get("position", Vector2.ZERO)
	for drop in map_data.get("field_drops", []):
		var id = String(drop.get("id", ""))
		if id in ["evolution_core", "overclock_core", "weapon_core"] and not result.has(id):
			result[id] = drop.get("position", Vector2.ZERO)
	for equipment in map_data.get("field_equipment", []):
		var key = "field_weapon" if String(equipment.get("kind", "")) == "weapon" else "field_passive"
		if not result.has(key):
			result[key] = equipment.get("position", Vector2.ZERO)
	for gimmick in map_data.get("field_gimmicks", []):
		var id = String(gimmick.get("id", ""))
		if id in ["healing_spring", "spawn_rift", "sealed_chest_pillar"] and not result.has(id):
			result[id] = gimmick.get("position", Vector2.ZERO)
	return result

func _generate_field_drops(state, map_data: Dictionary, rng) -> Array:
	var drops: Array = []
	var center = state.field_size * 0.5
	for raw_id in state.field_drop_defs.keys():
		var id = String(raw_id)
		var def: Dictionary = state.field_drop_defs[id]
		var max_count = int(def.get("max_per_run", 1))
		for i in range(max_count):
			if _drop_skip_for_rarity(id, i, rng):
				continue
			var pos = _reward_position(state, map_data, rng, "field_drop", float(def.get("min_distance", 900.0)), 24.0)
			if pos == Vector2.INF:
				continue
			drops.append({
				"runtime_id": "map_drop_%s_%d" % [id, i],
				"id": id,
				"name_ja": String(def.get("name_ja", id)),
				"position": pos,
				"unlock_seconds": float(def.get("unlock_seconds", 0.0)),
				"radius": 24.0,
				"collected": false,
				"value": int(def.get("value", 1)),
				"priority": int(def.get("priority", 9)),
				"color": def.get("color", [1.0, 1.0, 1.0]),
				"generated_icon": String(def.get("generated_icon", "")),
			})
	return drops

func _generate_field_gimmicks(state, map_data: Dictionary, rng) -> Array:
	var gimmicks: Array = []
	var center = state.field_size * 0.5
	for raw_id in state.field_gimmick_defs.keys():
		var id = String(raw_id)
		var def: Dictionary = state.field_gimmick_defs[id]
		var max_count = int(def.get("max_per_run", 1))
		for i in range(max_count):
			var pos = _reward_position(state, map_data, rng, "field_gimmick", float(def.get("min_distance", 900.0)), 38.0)
			if pos == Vector2.INF:
				continue
			gimmicks.append({
				"runtime_id": "map_gimmick_%s_%d" % [id, i],
				"id": id,
				"name_ja": String(def.get("name_ja", id)),
				"position": pos,
				"unlock_seconds": float(def.get("unlock_seconds", 0.0)),
				"radius": 38.0,
				"hp": int(def.get("hp", 80)),
				"max_hp": int(def.get("hp", 80)),
				"cooldown": 0.0,
				"triggered": false,
				"opened": false,
				"priority": int(def.get("priority", 9)),
				"biome": _biome_for_quadrant(pos, state.field_size),
				"color": def.get("color", [1.0, 1.0, 1.0]),
				"generated_icon": String(def.get("generated_icon", "")),
			})
	return gimmicks

func _drop_skip_for_rarity(id: String, index: int, rng) -> bool:
	if id == "evolution_core" and index > 0:
		return rng.chance(0.40)
	if id == "overclock_core" and index > 0:
		return rng.chance(0.35)
	if id == "cursed_relic":
		return rng.chance(0.20)
	return false

func _reward_position(state, map_data: Dictionary, rng, pickup_type: String, min_distance: float, radius: float) -> Vector2:
	var field_size: Vector2 = state.field_size
	var center := field_size * 0.5
	var walkable = tile_collision.random_walkable_position(map_data, rng, center, min_distance, field_size.length())
	var resolved = item_placement_system.resolve_valid_pickup_position(state, map_data, {
		"pickup_type": pickup_type,
		"position": walkable,
		"radius": radius,
		"origin": center,
		"min_distance": min_distance,
		"max_distance": field_size.length(),
		"rng": rng
	})
	if bool(resolved.get("ok", false)):
		return resolved.get("position", walkable)
	var anchors: Array = []
	for room in map_data.get("rooms", []):
		if String(room.get("terrain_id", "")) in ["mine_chamber", "danger_den", "healing_oasis", "relic_vault", "event_room", "sealed_room", "boss_arena"]:
			anchors.append(room.get("position", center))
	for zone in map_data.get("danger_zones", []):
		anchors.append(zone.get("position", center))
	for wall in map_data.get("wall_specs", []):
		if String(wall.get("type", "")) in ["rich_crystal", "cursed_crystal"]:
			anchors.append(wall.get("position", center))
	var pos = center
	for attempt in range(24):
		if not anchors.is_empty() and rng.chance(0.62):
			var anchor: Vector2 = rng.choice(anchors)
			pos = anchor + Vector2.RIGHT.rotated(rng.range_float(0.0, TAU)) * rng.range_float(120.0, 420.0)
		else:
			var distance = rng.range_float(min_distance, min(field_size.x, field_size.y) * 0.46)
			pos = center + Vector2.RIGHT.rotated(rng.range_float(0.0, TAU)) * distance
		pos.x = clampf(pos.x, 160.0, field_size.x - 160.0)
		pos.y = clampf(pos.y, 160.0, field_size.y - 160.0)
		resolved = item_placement_system.resolve_valid_pickup_position(state, map_data, {
			"pickup_type": pickup_type,
			"position": pos,
			"radius": radius,
			"origin": center,
			"min_distance": min_distance,
			"max_distance": min(field_size.x, field_size.y) * 0.55,
			"rng": rng
		})
		if bool(resolved.get("ok", false)):
			return resolved.get("position", pos)
	resolved = item_placement_system.resolve_valid_pickup_position(state, map_data, {
		"pickup_type": pickup_type,
		"radius": radius,
		"origin": center,
		"min_distance": min_distance,
		"max_distance": field_size.length(),
		"rng": rng
	})
	return resolved.get("position", Vector2.INF) if bool(resolved.get("ok", false)) else Vector2.INF

func _near_corridor(angle: float, corridors: Array) -> bool:
	for corridor in corridors:
		var diff = abs(wrapf(angle - float(corridor), -PI, PI))
		if diff < 0.18:
			return true
	return false

func _wall_type_for_distance(distance: float, rng) -> String:
	if distance > 2200.0 and rng.chance(0.26):
		return "cursed_crystal"
	if distance > 1500.0 and rng.chance(0.36):
		return "rich_crystal"
	return "small_crystal" if rng.chance(0.42) else "wall_crystal"

func _biome_for_quadrant(pos: Vector2, field_size: Vector2) -> String:
	if pos.x > field_size.x * 0.52 and pos.y > field_size.y * 0.52:
		return "void_zone"
	if pos.y > field_size.y * 0.52:
		return "red_mine"
	if pos.x > field_size.x * 0.52:
		return "amethyst_forest"
	return "star_plain"

func _json_dict(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback.duplicate(true)
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else fallback.duplicate(true)
