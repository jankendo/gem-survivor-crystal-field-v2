extends RefCounted
class_name ProgressionRecommendationSystem

func next_actions(save_data: Dictionary) -> Array:
	var actions: Array = []
	var currency := int(save_data.get("crystal_currency", 0))
	if currency >= 300:
		actions.append("ショップで新しい候補を購入")
	else:
		actions.append("結晶壁と宝箱を探してクリスタル貨を集める")
	var stats: Dictionary = save_data.get("stats", {})
	if float(stats.get("best_danger_time", 0.0)) < 60.0:
		actions.append("危険地帯の報酬を短時間だけ狙う")
	if int(stats.get("total_crystals", 0)) < 30:
		actions.append("結晶壁を壊して採掘系報酬を増やす")
	return actions.slice(0, 3)

func objective_text(target: Dictionary, player_position: Vector2) -> String:
	var name := String(target.get("name_ja", "探索目標"))
	var pos: Vector2 = target.get("position", player_position)
	var distance := int(round(pos.distance_to(player_position)))
	var danger := int(target.get("danger", 1))
	var reward := String(target.get("reward_ja", "報酬"))
	return "%s　距離%d　危険度：%s　報酬：%s" % [name, distance, "★".repeat(clampi(danger, 1, 5)) + "☆".repeat(5 - clampi(danger, 1, 5)), reward]
