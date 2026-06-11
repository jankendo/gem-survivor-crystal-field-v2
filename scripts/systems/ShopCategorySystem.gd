extends RefCounted
class_name ShopCategorySystem

var currency_sinks = preload("res://scripts/systems/CurrencySinkSystem.gd").new()

func category_ids() -> Array:
	return currency_sinks.category_ids()

func category_name(category_id: String) -> String:
	return String(currency_sinks.categories.get(category_id, {}).get("name_ja", category_id))

func recommendation(category_id: String) -> String:
	return String(currency_sinks.categories.get(category_id, {}).get("recommend_ja", ""))
