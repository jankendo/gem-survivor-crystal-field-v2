extends RefCounted
class_name FieldEventSystem

const CrystalWallScript = preload("res://scripts/core/CrystalWall.gd")
const ChestScript = preload("res://scripts/core/Chest.gd")

func process(state, delta: float, events: Array) -> void:
	if state.game_over or state.level_up_pending or state.chest_pending:
		return
	if not state.active_field_event.is_empty():
		state.field_event_timer = maxf(0.0, state.field_event_timer - delta)
		_tick_active_event(state, delta, events)
		if state.field_event_timer <= 0.0:
			_finish_event(state, events)
		return
	if state.elapsed_seconds < float(state.field_event_defs.get("start_seconds", 240.0)):
		return
	if state.next_field_event_time <= 0.0:
		_schedule_next_event(state)
	if state.elapsed_seconds >= state.next_field_event_time:
		_start_event(state, events)

func force_start(state, event_id: String, events: Array) -> void:
	state.next_field_event_time = state.elapsed_seconds
	_start_event(state, events, event_id)

func _schedule_next_event(state) -> void:
	state.next_field_event_time = state.elapsed_seconds + state.rng.range_float(
		float(state.field_event_defs.get("interval_min", 120.0)),
		float(state.field_event_defs.get("interval_max", 180.0))
	)

func _start_event(state, events: Array, forced_id: String = "") -> void:
	var event_defs: Array = state.field_event_defs.get("events", [])
	if event_defs.is_empty():
		return
	var event = event_defs[0]
	if forced_id != "":
		for candidate in event_defs:
			if String(candidate.get("id", "")) == forced_id:
				event = candidate
				break
	else:
		event = state.rng.choice(event_defs)
	state.active_field_event = event.duplicate(true)
	state.active_field_event["start_crystals"] = state.crystals_destroyed
	state.active_field_event["start_chests"] = state.chests_opened
	state.active_field_event["start_danger_time"] = state.danger_time
	state.field_event_timer = float(event.get("duration", 45.0))
	state.field_event_count += 1
	state.message = "%s 発生！" % String(event.get("name_ja", "フィールドイベント"))
	events.append({"type": "field_event_start", "id": event.get("id", ""), "name": event.get("name_ja", ""), "duration": state.field_event_timer, "risk": event.get("risk", ""), "reward": event.get("reward", "")})
	match String(event.get("id", "")):
		"crystal_surge":
			_spawn_event_crystals(state, events)
		"elite_hunt":
			state.event_elite_reward_pending = true
			events.append({"type": "field_event_reward_pending", "id": "elite_hunt"})
		"danger_bloom":
			state.danger_zones.append({"id": "event_danger_%d" % state.field_event_count, "position": state.random_walkable_position(state.player_position, 120.0, 360.0), "radius": 420.0, "biome": state.current_biome_id})
		"cursed_treasure":
			var chest = ChestScript.new(state.random_walkable_position(state.player_position, 120.0, 320.0), "cursed", "field_event")
			state.add_chest(chest)
			events.append({"type": "chest_drop", "pos": chest.position, "rarity": chest.rarity, "source": "field_event"})
	state.next_field_event_time = 0.0

func _tick_active_event(state, delta: float, events: Array) -> void:
	var id = String(state.active_field_event.get("id", ""))
	if id == "meteor_rain":
		state.field_event_pulse += delta
		if state.field_event_pulse >= 2.2:
			state.field_event_pulse = 0.0
			var pos = state.random_walkable_position(state.player_position, 80.0, 360.0)
			state.bombs.append(preload("res://scripts/core/Projectile.gd").new("meteor_rain", pos, Vector2.ZERO, 22 + int(state.elapsed_minutes()), 0, 0.55, 18.0, 110.0, false))
			events.append({"type": "meteor_warning", "pos": pos})

func _finish_event(state, events: Array) -> void:
	var id = String(state.active_field_event.get("id", ""))
	var name = String(state.active_field_event.get("name_ja", "イベント"))
	var success = _event_succeeded(state)
	state.active_field_event = {}
	state.field_event_timer = 0.0
	state.field_event_pulse = 0.0
	_schedule_next_event(state)
	events.append({"type": "field_event_success" if success else "field_event_failed", "id": id, "name": name})
	events.append({"type": "field_event_end", "id": id, "name": name, "success": success})

func _event_succeeded(state) -> bool:
	var success_type = String(state.active_field_event.get("success_type", "survive"))
	match success_type:
		"crystal_break":
			return state.crystals_destroyed - int(state.active_field_event.get("start_crystals", state.crystals_destroyed)) >= int(state.active_field_event.get("success_count", 1))
		"elite_reward":
			return not state.event_elite_reward_pending
		"danger_time":
			return state.danger_time - float(state.active_field_event.get("start_danger_time", state.danger_time)) >= float(state.active_field_event.get("success_count", 10))
		"chest_open":
			return state.chests_opened > int(state.active_field_event.get("start_chests", state.chests_opened))
	return not state.game_over

func _spawn_event_crystals(state, events: Array) -> void:
	for i in range(3):
		var pos = state.random_walkable_position(state.player_position, 180.0, 520.0)
		var wall = CrystalWallScript.new("event_crystal_%d_%d" % [state.field_event_count, i], pos, Vector2(115, 70), 72, true, "event", "rich_crystal", state.current_biome_id)
		wall.rescale_hp(state.crystal_hp_multiplier_for_position(pos) * 0.8)
		state.crystal_walls.append(wall)
		events.append({"type": "crystal_summon", "pos": pos, "source": "field_event"})
