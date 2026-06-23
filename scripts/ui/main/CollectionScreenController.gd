extends RefCounted
class_name CollectionScreenController

var tabs := ["characters", "weapons", "passives", "blessings", "evolutions", "enemies", "bosses", "field_drops", "field_gimmicks", "field_events"]
var tab_names := ["キャラ", "武器", "パッシブ", "祝福", "進化", "敵", "ボス", "ドロップ", "ギミック", "イベント"]
var tab_index := 0
var filter_index := 0
var sort_index := 0

func move_tab(delta: int) -> int:
	tab_index = posmod(tab_index + delta, tabs.size())
	return tab_index

func select_tab(index: int) -> int:
	tab_index = clampi(index, 0, tabs.size() - 1)
	return tab_index

func select_filter(index: int, max_count: int) -> int:
	filter_index = clampi(index, 0, maxi(0, max_count - 1))
	return filter_index

func select_sort(index: int, max_count: int) -> int:
	sort_index = clampi(index, 0, maxi(0, max_count - 1))
	return sort_index

func current_tab() -> String:
	return String(tabs[tab_index])
