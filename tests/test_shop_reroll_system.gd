extends RefCounted

const ShopRerollSystemScript = preload("res://scripts/systems/ShopRerollSystem.gd")

func run(t) -> void:
	test_reroll_consumes_cycle_count(t)
	test_same_seed_cycle_count_reproduces_featured(t)
	test_reroll_persists_to_save(t)

func _save(path: String) -> SaveSystem:
	var save = SaveSystem.new(path)
	save.save_data({})
	var data = save.load_data()
	data["crystal_currency"] = 1000
	data["shop_save_seed"] = 777
	save.save_data(data)
	return save

func test_reroll_consumes_cycle_count(t) -> void:
	var save = _save("user://test_shop_reroll_system.save")
	var system = ShopRerollSystemScript.new()
	var before = system.ensure_featured(save).get("shop_featured_items", [])
	var result = system.reroll(save)
	var after = save.load_data().get("shop_featured_items", [])
	t.assert_true(bool(result.get("ok", false)), "shop reroll should succeed")
	t.assert_eq(int(save.load_data().get("shop_reroll_count", 0)), 1, "shop reroll count should persist")
	t.assert_true(str(before) != str(after), "shop reroll should change featured candidates")

func test_same_seed_cycle_count_reproduces_featured(t) -> void:
	var system = ShopRerollSystemScript.new()
	var a = SaveSystem.new("user://test_shop_reroll_a.save")
	var b = SaveSystem.new("user://test_shop_reroll_b.save")
	var data = a.load_data()
	data["crystal_currency"] = 800
	data["shop_save_seed"] = 999
	data["shop_cycle_id"] = 3
	data["shop_reroll_count"] = 2
	a.save_data(data)
	b.save_data(data.duplicate(true))
	t.assert_eq(str(system.ensure_featured(a).get("shop_featured_items", [])), str(system.ensure_featured(b).get("shop_featured_items", [])), "same shop seed/cycle/reroll should reproduce featured items")

func test_reroll_persists_to_save(t) -> void:
	var save = _save("user://test_shop_reroll_persist.save")
	var system = ShopRerollSystemScript.new()
	system.reroll(save)
	var reloaded = SaveSystem.new("user://test_shop_reroll_persist.save").load_data()
	t.assert_eq(int(reloaded.get("shop_reroll_count", 0)), 1, "reroll count should survive reload")
	t.assert_true(not (reloaded.get("shop_featured_items", []) as Array).is_empty(), "featured items should survive reload")
