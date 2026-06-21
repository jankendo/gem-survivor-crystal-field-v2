extends RefCounted
class_name ShopRerollSystem

var config: Dictionary = {
	"deprecated": true,
	"replacement": "res://data/selection_actions.json",
	"shop_inventory_reroll_enabled": false
}

func ensure_featured(save: SaveSystem) -> Dictionary:
	return save.load_data()

func can_reroll(save_data: Dictionary) -> bool:
	return false

func cost_for_count(current_reroll_count: int) -> int:
	return 0

func free_rerolls_remaining(save_data: Dictionary) -> int:
	return 0

func reroll(save: SaveSystem) -> Dictionary:
	return {
		"ok": false,
		"deprecated": true,
		"reason": "ショップ商品の再抽選は廃止済みです。レベルアップ3択の再抽選回数は永続強化で増やします。",
		"data": save.load_data()
	}

func generate_featured(save_data: Dictionary) -> Array:
	return []

func featured_text(save_data: Dictionary) -> String:
	return "ショップ商品再抽選は廃止済み"

func advance_cycle(save: SaveSystem) -> void:
	pass
