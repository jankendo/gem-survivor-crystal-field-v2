extends RefCounted
class_name ObjectiveIndicatorSystem

func targets_for_state(state, max_count: int = 3) -> Array:
	var targets: Array = []
	_add_goals(state, targets)
	_add_drops(state, targets)
	_add_chests(state, targets)
	_add_boss(state, targets)
	_add_gimmicks(state, targets)
	_add_danger_zone(state, targets)
	_add_field_event_candidate(state, targets)
	_add_gem_cluster(state, targets)
	targets.sort_custom(func(a, b):
		var pa = int(a.get("priority", 99))
		var pb = int(b.get("priority", 99))
		if pa == pb:
			return float(a.get("distance", 0.0)) < float(b.get("distance", 0.0))
		return pa < pb
	)
	return targets.slice(0, max_count)

func _add_goals(state, targets: Array) -> void:
	for i in range(mini(3, state.current_goals.size())):
		var goal: Dictionary = state.current_goals[i]
		var pos: Vector2 = goal.get("position", state.player_position)
		if pos.distance_to(state.player_position) < 20.0:
			continue
		targets.append(_target(
			String(goal.get("title", "次の目標")),
			pos,
			Color(1.0, 0.88, 0.34) if i == 0 else Color(0.62, 0.90, 1.0),
			0 + i,
			state
		))

func _add_drops(state, targets: Array) -> void:
	for drop in state.field_drops:
		if bool(drop.get("collected", false)) or state.elapsed_seconds < float(drop.get("unlock_seconds", 0.0)):
			continue
		var id = String(drop.get("id", ""))
		var priority = int(drop.get("priority", 8))
		if id == "heal_ore" and state.hp_ratio() <= 0.50:
			priority = 2
		targets.append(_target(String(drop.get("name_ja", id)), drop.get("position", Vector2.ZERO), _color(drop), priority, state))

func _add_chests(state, targets: Array) -> void:
	for chest in state.chests:
		var priority = 1 if String(chest.rarity) == "evolution" else 5
		targets.append(_target("宝箱", chest.position, Color(1.0, 0.72, 0.24), priority, state))

func _add_boss(state, targets: Array) -> void:
	var boss = state.active_boss()
	if boss != null:
		targets.append(_target("ボス", boss.position, Color(1.0, 0.24, 0.20), 2, state))

func _add_gimmicks(state, targets: Array) -> void:
	for gimmick in state.field_gimmicks:
		if bool(gimmick.get("destroyed", false)) or state.elapsed_seconds < float(gimmick.get("unlock_seconds", 0.0)):
			continue
		var id = String(gimmick.get("id", ""))
		if id in ["healing_spring", "spawn_rift", "sealed_chest_pillar"]:
			var priority = int(gimmick.get("priority", 9))
			if id == "healing_spring" and state.hp_ratio() <= 0.50:
				priority = 2
			targets.append(_target(String(gimmick.get("name_ja", id)), gimmick.get("position", Vector2.ZERO), _color(gimmick), priority, state))

func _add_gem_cluster(state, targets: Array) -> void:
	if state.gems.size() < 24:
		return
	var avg = Vector2.ZERO
	var count = 0
	for gem in state.gems:
		if gem.position.distance_to(state.player_position) > 320.0:
			avg += gem.position
			count += 1
			if count >= 42:
				break
	if count > 0:
		targets.append(_target("大量ジェム", avg / float(count), Color(0.42, 0.95, 1.0), 8, state))

func _add_danger_zone(state, targets: Array) -> void:
	var nearest_danger := {}
	var nearest_distance := INF
	for zone in state.danger_zones:
		var pos: Vector2 = zone.get("position", Vector2.ZERO)
		var distance = pos.distance_to(state.player_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_danger = zone
	if not nearest_danger.is_empty():
		targets.append(_target("危険地帯", nearest_danger.get("position", Vector2.ZERO), Color(1.0, 0.22, 0.48), 7, state))

func _add_field_event_candidate(state, targets: Array) -> void:
	if state.navigation_targets.has("field_event"):
		targets.append(_target("イベント候補", state.navigation_targets["field_event"], Color(0.72, 0.46, 1.0), 6, state))

func _target(label: String, pos: Vector2, color: Color, priority: int, state) -> Dictionary:
	return {"label": label, "pos": pos, "color": color, "priority": priority, "distance": pos.distance_to(state.player_position)}

func _color(data: Dictionary) -> Color:
	var values: Array = data.get("color", [1.0, 1.0, 1.0])
	if values.size() >= 3:
		return Color(float(values[0]), float(values[1]), float(values[2]))
	return Color.WHITE
