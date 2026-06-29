extends RefCounted
class_name GoalHintSystem

var availability = preload("res://scripts/systems/FieldObjectAvailabilitySystem.gd").new()

func process(state, events: Array) -> Array:
	var goals = goals_for_state(state)
	var next_id = String(goals[0].get("id", "")) if not goals.is_empty() else ""
	if next_id != state.current_goal_id:
		state.current_goal_id = next_id
		state.goal_change_timer = 3.0
		if not goals.is_empty():
			events.append({"type": "goal_changed", "goal": goals[0]})
	state.current_goals = goals
	return goals

func goals_for_state(state) -> Array:
	var goals: Array = []
	if state.hp_ratio() <= 0.50:
		var heal = _nearest_drop_or_gimmick(state, ["heal_ore"], ["healing_spring"])
		if not heal.is_empty():
			goals.append(_goal("heal", "回復地点へ向かう", "HPが50%以下です", heal, 1, state))
	if state.has_available_evolution():
		var evolution = _nearest_evolution_target(state)
		if not evolution.is_empty():
			goals.append(_goal("evolution", "進化報酬を回収", "進化条件を満たした武器があります", evolution, 2, state))
	if not state.active_field_event.is_empty():
		var event_nav: Dictionary = state.navigation_targets.get("field_event", {})
		var event_pos: Vector2 = event_nav.get("position", state.player_position) if bool(event_nav.get("enabled", false)) else state.player_position
		goals.append(_goal("event", String(state.active_field_event.get("objective_ja", "イベントを達成")), "期間限定イベントが進行中", {"position": event_pos, "name_ja": state.active_field_event.get("name_ja", "イベント")}, 3, state))
	var boss = state.active_boss()
	if boss != null:
		goals.append(_goal("boss", "ボスを撃破", "ボスがフィールドに出現中", {"position": boss.position, "name_ja": boss.name_ja}, 4, state))
	if state.weapons.keys().size() < state.max_owned_weapons():
		var weapon_core = _nearest_drop_or_gimmick(state, ["weapon_core"], [])
		if not weapon_core.is_empty():
			goals.append(_goal("weapon_core", "武器コアを探す", "武器枠に空きがあります", weapon_core, 5, state))
	var field_equipment = _nearest_field_equipment(state)
	if not field_equipment.is_empty():
		goals.append(_goal("field_equipment", String(field_equipment.get("name_ja", "フィールド装備")) + "を回収", "マップ配置の具体報酬。5枠超過でも取得できます", field_equipment, 5, state))
	var synergy = _near_synergy(state)
	if not synergy.is_empty():
		goals.append(_goal("synergy", "ビルド相性を完成", "%sまであと1タグ" % synergy, {"position": state.player_position, "name_ja": synergy}, 6, state))
	if state.elapsed_seconds < 240.0:
		goals.append(_goal("early_gems", "ジェムを回収", "序盤はLvを上げて武器を増やす", {"position": state.player_position, "name_ja": "ジェム"}, 7, state))
	elif state.elapsed_seconds < 900.0:
		var mid = _nearest_midgame_target(state)
		goals.append(_goal("mid_explore", "遠方を探索", "宝箱・結晶・危険地帯でビルドを伸ばす", mid, 8, state))
	else:
		var late = _nearest_lategame_target(state)
		goals.append(_goal("late_power", "進化と過充電を進める", "終盤ボスに備えて主力を完成させる", late, 9, state))
	goals.sort_custom(func(a, b): return int(a.get("priority", 99)) < int(b.get("priority", 99)))
	return goals.slice(0, 3)

func _nearest_evolution_target(state) -> Dictionary:
	var best = _nearest_drop_or_gimmick(state, ["evolution_core"], [])
	for chest in state.chests:
		var candidate = {"position": chest.position, "name_ja": "宝箱"}
		best = _nearer(state, best, candidate)
	return best

func _nearest_midgame_target(state) -> Dictionary:
	var best = _nearest_drop_or_gimmick(state, ["weapon_core", "passive_core", "crystal_cache"], ["sealed_chest_pillar"])
	best = _nearer(state, best, _nearest_field_equipment(state))
	if best.is_empty() and not state.danger_zones.is_empty():
		best = {"position": state.danger_zones[0].get("position", state.player_position), "name_ja": "危険地帯"}
	return best if not best.is_empty() else {"position": state.player_position, "name_ja": "周辺探索"}

func _nearest_lategame_target(state) -> Dictionary:
	var best = _nearest_drop_or_gimmick(state, ["evolution_core", "overclock_core"], ["sealed_chest_pillar", "spawn_rift"])
	return best if not best.is_empty() else _nearest_midgame_target(state)

func _nearest_drop_or_gimmick(state, drop_ids: Array, gimmick_ids: Array) -> Dictionary:
	var best: Dictionary = {}
	for drop in state.field_drops:
		if not availability.is_available_now(state, drop, "collected"):
			continue
		if drop_ids.has(String(drop.get("id", ""))):
			best = _nearer(state, best, {"position": drop.get("position", Vector2.ZERO), "name_ja": drop.get("name_ja", "")})
	for gimmick in state.field_gimmicks:
		if not availability.is_available_now(state, gimmick, "destroyed"):
			continue
		if gimmick_ids.has(String(gimmick.get("id", ""))):
			best = _nearer(state, best, {"position": gimmick.get("position", Vector2.ZERO), "name_ja": gimmick.get("name_ja", "")})
	return best

func _nearest_field_equipment(state) -> Dictionary:
	var best: Dictionary = {}
	for equipment in state.field_equipment:
		if not availability.is_available_now(state, equipment, "collected"):
			continue
		best = _nearer(state, best, {"position": equipment.get("position", Vector2.ZERO), "name_ja": equipment.get("name_ja", "フィールド装備")})
	return best

func _nearer(state, current: Dictionary, candidate: Dictionary) -> Dictionary:
	if current.is_empty():
		return candidate
	var current_distance = (current.get("position", state.player_position) as Vector2).distance_to(state.player_position)
	var candidate_distance = (candidate.get("position", state.player_position) as Vector2).distance_to(state.player_position)
	return candidate if candidate_distance < current_distance else current

func _near_synergy(state) -> String:
	for raw_id in state.build_synergy_defs.keys():
		var id = String(raw_id)
		if state.active_synergies.has(id):
			continue
		var def: Dictionary = state.build_synergy_defs[id]
		var shortage = 0
		for tag in def.get("requirements", {}).keys():
			shortage += maxi(0, int(def["requirements"][tag]) - int(state.build_tag_counts.get(String(tag), 0)))
		if def.has("requirements_any_total"):
			var any_req: Dictionary = def["requirements_any_total"]
			var total = 0
			for raw_tag in any_req.get("tags", []):
				total += int(state.build_tag_counts.get(String(raw_tag), 0))
			shortage += maxi(0, int(any_req.get("count", 1)) - total)
		if shortage == 1:
			return String(def.get("name_ja", id))
	return ""

func _goal(id: String, title: String, reason: String, target: Dictionary, priority: int, state) -> Dictionary:
	var pos: Vector2 = target.get("position", state.player_position)
	return {
		"id": id,
		"title": title,
		"reason": reason,
		"target_name": String(target.get("name_ja", "")),
		"position": pos,
		"distance": pos.distance_to(state.player_position),
		"priority": priority
	}
