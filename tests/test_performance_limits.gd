extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const ProjectileScript = preload("res://scripts/core/Projectile.gd")
const ExpGemScript = preload("res://scripts/core/ExpGem.gd")
const EnemySpawnerScript = preload("res://scripts/systems/EnemySpawner.gd")

func run(t) -> void:
	test_balance_caps_exist(t)
	test_runtime_arrays_trim_to_caps(t)
	test_spawner_respects_enemy_cap(t)

func test_balance_caps_exist(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(611)
	t.assert_true(state.max_enemies() > 0, "enemy cap should be defined")
	t.assert_true(state.max_gems() > 0, "gem cap should be defined")
	t.assert_true(state.max_projectiles() > 0, "projectile cap should be defined")

func test_runtime_arrays_trim_to_caps(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(612)
	state.balance_data["max_projectiles"] = 5
	state.balance_data["max_gems"] = 6
	state.balance_data["max_texts"] = 4
	state.balance_data["max_effects"] = 4
	for i in range(10):
		state.projectiles.append(ProjectileScript.new())
		state.gems.append(ExpGemScript.new())
		state.hit_flashes.append({"pos": Vector2.ZERO, "life": 1.0})
	state.trim_runtime_arrays()
	t.assert_true(state.projectiles.size() <= 5, "projectiles should trim to cap")
	t.assert_true(state.gems.size() <= 6, "gems should trim to cap")
	t.assert_true(state.hit_flashes.size() <= 4, "hit flashes should trim to cap")

func test_spawner_respects_enemy_cap(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(613)
	state.balance_data["max_enemies"] = 12
	state.elapsed_seconds = 1800.0
	state.spawn_meter = 20.0
	var events: Array = []
	EnemySpawnerScript.new().process(state, 0.1, events)
	t.assert_true(state.enemies.size() <= 12, "spawner should respect enemy cap")
