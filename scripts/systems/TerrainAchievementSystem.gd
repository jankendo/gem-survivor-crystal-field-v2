extends RefCounted
class_name TerrainAchievementSystem

func titles_for_state(state) -> Array:
	var titles: Array = []
	if int(state.terrain_kills.get("crystal_corridor", 0)) >= 1000:
		titles.append("回廊突破者")
	if int(state.terrain_crystals.get("mine_chamber", 0)) >= 500:
		titles.append("真・採掘王")
	if float(state.terrain_time.get("danger_den", 0.0)) >= 300.0:
		titles.append("危険巣の主")
	if state.cursed_relic_count >= 10:
		titles.append("遺物中毒")
	if state.rooms_discovered >= 12:
		titles.append("地図埋め")
	if state.shortcut_walls_broken >= 5:
		titles.append("近道職人")
	return titles
