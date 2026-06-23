extends RefCounted
class_name ShopScreenController

var category_index := 0

func clamp_category(category_ids: Array) -> int:
	category_index = clampi(category_index, 0, maxi(0, category_ids.size() - 1))
	return category_index

func move(delta: int, category_ids: Array) -> int:
	if category_ids.is_empty():
		category_index = 0
	else:
		category_index = posmod(category_index + delta, category_ids.size())
	return category_index

func select(index: int, category_ids: Array) -> int:
	category_index = clampi(index, 0, maxi(0, category_ids.size() - 1))
	return category_index
