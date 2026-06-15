extends RefCounted
class_name SurvivorState

const CrystalWallScript = preload("res://scripts/core/CrystalWall.gd")
const BiomeSystemScript = preload("res://scripts/systems/BiomeSystem.gd")
const DifficultySystemScript = preload("res://scripts/systems/DifficultySystem.gd")
const MapGeneratorScript = preload("res://scripts/systems/MapGenerator.gd")
const TerrainRoomSystemScript = preload("res://scripts/systems/TerrainRoomSystem.gd")
const TerrainAchievementSystemScript = preload("res://scripts/systems/TerrainAchievementSystem.gd")
const TileCollisionSystemScript = preload("res://scripts/systems/TileCollisionSystem.gd")
const PoolManagerScript = preload("res://scripts/systems/PoolManager.gd")
const SurvivorEnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
const ProjectileScript = preload("res://scripts/core/Projectile.gd")
const ExpGemScript = preload("res://scripts/core/ExpGem.gd")
const DEFAULT_FIELD_SIZE = Vector2(6600, 6600)

var field_size: Vector2 = DEFAULT_FIELD_SIZE
var pool_manager = PoolManagerScript.new()
var player_position: Vector2 = DEFAULT_FIELD_SIZE * 0.5
var camera_position: Vector2 = DEFAULT_FIELD_SIZE * 0.5
var player_velocity: Vector2 = Vector2.ZERO
var hp: int = 110
var max_hp: int = 110
var base_move_speed: float = 226.0
var base_magnet_radius: float = 86.0
var level: int = 1
var exp: int = 0
var exp_to_next: int = 16
var score: int = 0
var best_score: int = 0
var kills: int = 0
var elapsed_seconds: float = 0.0
var ios_pathing_update_count: int = 0
var ios_physics_query_count: int = 0
var damage_number_spawn_count: int = 0
var gems_collected: int = 0
var gem_exp_collected: int = 0
var evolved_weapon_count: int = 0
var best_score_updated: bool = false
var game_over: bool = false
var paused: bool = false
var game_over_reason: String = ""
var invincible_timer: float = 0.0
var regen_meter: float = 0.0
var spawn_meter: float = 0.0
var selected_reward_index: int = 0
var level_up_pending: bool = false
var level_up_options: Array = []
var message: String = ""
var chest_message: String = ""
var chest_pending: bool = false
var chest_timer: float = 0.0
var chest_notice_timer: float = 0.0
var boss_warning_timer: float = 0.0
var boss_warning_text: String = ""
var pickup_combo_count: int = 0
var pickup_combo_timer: float = 0.0
var max_combo: int = 0
var combo_magnet_timer: float = 0.0
var combo_thresholds_hit: Dictionary = {}
var gem_fever_timer: float = 0.0
var gem_fever_tier: int = 0
var crystal_overdrive_timer: float = 0.0
var orbit_angle: float = 0.0
var damage_flash_timer: float = 0.0
var boundary_touch_timer: float = 0.0
var revival_used: bool = false
var crystals_destroyed: int = 0
var overdrive_count: int = 0
var chests_opened: int = 0
var max_damage: int = 0
var danger_time: float = 0.0
var low_hp_survival_time: float = 0.0
var auto_infinite_enabled: bool = true
var auto_recall_drone_enabled: bool = false
var auto_infinite_count: int = 0
var title_badges: Array = []
var current_biome_id: String = "star_plain"
var current_biome_name: String = "星屑平原"
var current_terrain_id: String = "safe_room"
var current_terrain_name: String = "安全拠点"
var explored_room_ids: Array = []
var rooms_discovered: int = 0
var terrain_time: Dictionary = {}
var terrain_kills: Dictionary = {}
var terrain_crystals: Dictionary = {}
var shortcut_walls_broken: int = 0
var oasis_healing: int = 0

func _init() -> void:
	pool_manager.register("enemy", func(): return SurvivorEnemyScript.new(), func(value, args): value.reset.callv(args), 720)
	pool_manager.register("projectile", func(): return ProjectileScript.new(), func(value, args): value.reset.callv(args), 360)
	pool_manager.register("gem", func(): return ExpGemScript.new(), func(value, args): value.reset.callv(args), 960)
	pool_manager.register("hit_flash", func(): return {}, Callable(self, "_reset_pool_dictionary"), 220)
	pool_manager.register("effect_line", func(): return {}, Callable(self, "_reset_pool_dictionary"), 220)
	pool_manager.register("damage_text", func(): return {}, Callable(self, "_reset_pool_dictionary"), 100)

func acquire_enemy(args: Array):
	return pool_manager.acquire("enemy", args)

func acquire_projectile(args: Array):
	return pool_manager.acquire("projectile", args)

func acquire_gem(args: Array):
	return pool_manager.acquire("gem", args)

func release_runtime(type_id: String, value) -> void:
	pool_manager.release(type_id, value)

func add_hit_flash(data: Dictionary) -> void:
	hit_flashes.append(pool_manager.acquire("hit_flash", [data]))

func add_effect_line(data: Dictionary) -> void:
	effect_lines.append(pool_manager.acquire("effect_line", [data]))

func _reset_pool_dictionary(value: Dictionary, args: Array) -> void:
	value.clear()
	value.merge(args[0], true)
var terrain_heal_meter: float = 0.0
var rng: RunRng = RunRng.new()
var biome_system = BiomeSystemScript.new()
var difficulty_system = DifficultySystemScript.new()
var map_generator = MapGeneratorScript.new()
var terrain_room_system = TerrainRoomSystemScript.new()
var terrain_achievement_system = TerrainAchievementSystemScript.new()
var tile_collision_system = TileCollisionSystemScript.new()
var map_seed: int = 0
var map_seed_text: String = ""
var map_data: Dictionary = {}
var navigation_targets: Dictionary = {}
var field_drops: Array = []
var field_gimmicks: Array = []

var selected_character_id: String = "noah"
var selected_character_name: String = "探鉱者ノア"
var selected_blessing_id: String = "attack"
var character_modifiers: Dictionary = {}
var blessing_modifiers: Dictionary = {}
var meta_upgrade_levels: Dictionary = {}
var currency_sink_levels: Dictionary = {}
var meta_hp_mult: float = 1.0
var meta_damage_mult: float = 1.0
var meta_magnet_mult: float = 1.0
var meta_currency_mult: float = 1.0
var meta_crystal_damage_mult: float = 1.0
var meta_chest_indicator_mult: float = 1.0

var overclocks: Dictionary = {}
var active_field_event: Dictionary = {}
var field_event_timer: float = 0.0
var field_event_pulse: float = 0.0
var next_field_event_time: float = 0.0
var field_event_count: int = 0
var event_elite_reward_pending: bool = false
var rune_contracts: Array = []
var rune_contract_pending: bool = false
var recall_drone_meter: float = 0.0
var recall_drone_ready: bool = false
var recall_drone_active_timer: float = 0.0
var recall_drone_activations: int = 0
var gem_turret_charge: int = 0
var exp_drop_meter: float = 1.0
var elite_chest_cooldown: float = 0.0
var boss_enrage_count: int = 0
var cursed_power: float = 1.0
var damage_taken_last_minute: int = 0
var levelups_last_minute: int = 0
var damage_minute_bucket: int = 0
var levelup_minute_bucket: int = 0
var last_ruin_reaper_minute: int = -1
var balance_log_enabled: bool = false
var balance_log_path: String = "user://run_balance_log.csv"
var balance_log_timer: float = 0.0
var balance_log_rows: Array = []
var build_synergy_defs: Dictionary = {}
var field_drop_defs: Dictionary = {}
var field_gimmick_defs: Dictionary = {}
var ui_layout_defs: Dictionary = {}
var field_help_defs: Dictionary = {}
var exploration_mastery_defs: Dictionary = {}
var exploration_chain_defs: Dictionary = {}
var terrain_type_defs: Dictionary = {}
var map_generation_defs: Dictionary = {}
var terrain_room_defs: Dictionary = {}
var field_drop_spawn_config: Dictionary = {}
var active_synergies: Dictionary = {}
var active_synergy_history: Array = []
var build_tag_counts: Dictionary = {}
var melee_rush_kills: int = 0
var melee_rush_level: int = 0
var melee_rush_timer: float = 0.0
var melee_rush_flash_timer: float = 0.0
var melee_rush_triggered_levels: Array = []
var melee_speed_timer: float = 0.0
var shock_explosions: int = 0
var field_drops_collected: int = 0
var field_gimmicks_triggered: int = 0
var cursed_relic_count: int = 0
var unlocked_weapon_ids: Array = []
var unlocked_passive_ids: Array = []
var disabled_weapon_ids: Array = []
var disabled_passive_ids: Array = []
var field_help_discovered: Dictionary = {}
var nearby_field_help: Dictionary = {}
var scanned_field_help: Dictionary = {}
var field_scan_timer: float = 0.0
var current_goals: Array = []
var current_goal_id: String = ""
var goal_change_timer: float = 0.0
var next_dynamic_drop_time: float = 0.0
var dynamic_drops_spawned: int = 0
var dynamic_drop_counts: Dictionary = {}
var dynamic_drop_last_spawn: Dictionary = {}
var dynamic_drop_log: Array = []
var dynamic_drop_rate_multiplier: float = 1.0
var dynamic_drop_rate_timer: float = 0.0
var rare_drop_multiplier: float = 1.0
var rare_drop_bonus_timer: float = 0.0
var exploration_score: int = 0
var exploration_rank: String = "D"
var exploration_currency_bonus: float = 0.0
var exploration_far_pickups: int = 0
var exploration_danger_pickups: int = 0
var exploration_chain: int = 0
var exploration_chain_max: int = 0
var exploration_chain_timer: float = 0.0
var exploration_chain_currency_bonus: int = 0
var field_event_successes: int = 0
var field_event_failures: int = 0

var enemies: Array = []
var gems: Array = []
var projectiles: Array = []
var enemy_projectiles: Array = []
var enemy_attack_warnings: Array = []
var bombs: Array = []
var chests: Array = []
var hit_flashes: Array = []
var effect_lines: Array = []
var floating_texts: Array = []
var background_particles: Array = []
var crystal_walls: Array = []
var danger_zones: Array = []
var boss_spawned_minutes: Array = []
var boss_warned_minutes: Array = []
var boss_defeated_ids: Array = []
var enemy_seen: Array = []
var weapon_kill_counts: Dictionary = {}
var weapon_damage_by_id: Dictionary = {}
var weapon_pick_counts: Dictionary = {}
var passive_pick_counts: Dictionary = {}
var boss_damage_by_weapon_id: Dictionary = {}
var enemy_damage_by_weapon_id: Dictionary = {}
var damage_by_category: Dictionary = {}
var healing_by_source: Dictionary = {}
var currency_gain_by_source: Dictionary = {}
var evolution_time_by_weapon_id: Dictionary = {}

var weapons: Dictionary = {"magic_bolt": 1}
var passives: Dictionary = {}
var infinite_upgrades: Dictionary = {}
var weapon_cooldowns: Dictionary = {}
var weapon_defs: Dictionary = {}
var passive_defs: Dictionary = {}
var enemy_defs: Dictionary = {}
var evolution_defs: Dictionary = {}
var boss_defs: Dictionary = {}
var infinite_defs: Dictionary = {}
var spawn_curve: Dictionary = {}
var balance_data: Dictionary = {}
var difficulty_curve: Dictionary = {}
var overclock_defs: Dictionary = {}
var field_event_defs: Dictionary = {}
var rune_contract_defs: Dictionary = {}
var weapon_effect_defs: Dictionary = {}
var effect_density: String = "normal"
var performance_profile_id: String = "desktop_standard"
var evolved_weapons: Dictionary = {}
var evolved_magic_bolt: bool = false
var last_evolution_seconds: float = -999.0

func start_new_run(seed_value: int = 0, seed_text: String = "") -> void:
	seed_value = map_generator.seed_value_from_text(seed_text, seed_value)
	rng.set_seed_value(seed_value)
	_load_definitions()
	map_seed = seed_value
	map_seed_text = seed_text.strip_edges()
	field_size = Vector2(float(balance_data.get("field_width", DEFAULT_FIELD_SIZE.x)), float(balance_data.get("field_height", DEFAULT_FIELD_SIZE.y)))
	player_position = field_size * 0.5
	camera_position = player_position
	player_velocity = Vector2.ZERO
	max_hp = int(balance_data.get("player_hp", 110))
	hp = max_hp
	base_move_speed = float(balance_data.get("player_move_speed", 226.0))
	base_magnet_radius = float(balance_data.get("base_magnet_radius", 86.0))
	level = 1
	exp = 0
	exp_to_next = _exp_needed_for_level(level)
	score = 0
	best_score = SaveSystem.new().load_best_score()
	kills = 0
	elapsed_seconds = 0.0
	ios_pathing_update_count = 0
	ios_physics_query_count = 0
	damage_number_spawn_count = 0
	gems_collected = 0
	gem_exp_collected = 0
	evolved_weapon_count = 0
	best_score_updated = false
	game_over = false
	paused = false
	game_over_reason = ""
	invincible_timer = 0.0
	regen_meter = 0.0
	spawn_meter = 0.0
	selected_reward_index = 0
	level_up_pending = false
	level_up_options = []
	message = ""
	chest_message = ""
	chest_pending = false
	chest_timer = 0.0
	chest_notice_timer = 0.0
	boss_warning_timer = 0.0
	boss_warning_text = ""
	pickup_combo_count = 0
	pickup_combo_timer = 0.0
	max_combo = 0
	combo_magnet_timer = 0.0
	combo_thresholds_hit = {}
	gem_fever_timer = 0.0
	gem_fever_tier = 0
	crystal_overdrive_timer = 0.0
	orbit_angle = 0.0
	damage_flash_timer = 0.0
	boundary_touch_timer = 0.0
	revival_used = false
	crystals_destroyed = 0
	overdrive_count = 0
	chests_opened = 0
	max_damage = 0
	danger_time = 0.0
	low_hp_survival_time = 0.0
	auto_infinite_enabled = true
	auto_recall_drone_enabled = false
	auto_infinite_count = 0
	title_badges = []
	current_biome_id = "star_plain"
	current_biome_name = "星屑平原"
	current_terrain_id = "safe_room"
	current_terrain_name = "安全拠点"
	explored_room_ids = ["room_00"]
	rooms_discovered = 1
	terrain_time = {}
	terrain_kills = {}
	terrain_crystals = {}
	shortcut_walls_broken = 0
	oasis_healing = 0
	terrain_heal_meter = 0.0
	map_data = {}
	navigation_targets = {}
	field_drops = []
	field_gimmicks = []
	selected_character_id = "noah"
	selected_character_name = "探鉱者ノア"
	selected_blessing_id = "attack"
	character_modifiers = {}
	blessing_modifiers = {}
	meta_upgrade_levels = {}
	currency_sink_levels = {}
	meta_hp_mult = 1.0
	meta_damage_mult = 1.0
	meta_magnet_mult = 1.0
	meta_currency_mult = 1.0
	meta_crystal_damage_mult = 1.0
	meta_chest_indicator_mult = 1.0
	overclocks = {}
	active_field_event = {}
	field_event_timer = 0.0
	field_event_pulse = 0.0
	next_field_event_time = 0.0
	field_event_count = 0
	event_elite_reward_pending = false
	rune_contracts = []
	rune_contract_pending = false
	recall_drone_meter = 0.0
	recall_drone_ready = false
	recall_drone_active_timer = 0.0
	recall_drone_activations = 0
	gem_turret_charge = 0
	exp_drop_meter = 1.0
	elite_chest_cooldown = 0.0
	boss_enrage_count = 0
	cursed_power = 1.0
	damage_taken_last_minute = 0
	levelups_last_minute = 0
	damage_minute_bucket = 0
	levelup_minute_bucket = 0
	last_ruin_reaper_minute = -1
	balance_log_timer = 0.0
	balance_log_rows = []
	performance_profile_id = "desktop_standard"
	active_synergies = {}
	active_synergy_history = []
	build_tag_counts = {}
	melee_rush_kills = 0
	melee_rush_level = 0
	melee_rush_timer = 0.0
	melee_rush_flash_timer = 0.0
	melee_rush_triggered_levels = []
	melee_speed_timer = 0.0
	shock_explosions = 0
	field_drops_collected = 0
	field_gimmicks_triggered = 0
	cursed_relic_count = 0
	unlocked_weapon_ids = []
	unlocked_passive_ids = []
	disabled_weapon_ids = []
	disabled_passive_ids = []
	field_help_discovered = {}
	nearby_field_help = {}
	scanned_field_help = {}
	field_scan_timer = 0.0
	current_goals = []
	current_goal_id = ""
	goal_change_timer = 0.0
	next_dynamic_drop_time = 0.0
	dynamic_drops_spawned = 0
	dynamic_drop_counts = {}
	dynamic_drop_last_spawn = {}
	dynamic_drop_log = []
	dynamic_drop_rate_multiplier = 1.0
	dynamic_drop_rate_timer = 0.0
	rare_drop_multiplier = 1.0
	rare_drop_bonus_timer = 0.0
	exploration_score = 0
	exploration_rank = "D"
	exploration_currency_bonus = 0.0
	exploration_far_pickups = 0
	exploration_danger_pickups = 0
	exploration_chain = 0
	exploration_chain_max = 0
	exploration_chain_timer = 0.0
	exploration_chain_currency_bonus = 0
	field_event_successes = 0
	field_event_failures = 0
	enemies = []
	gems = []
	projectiles = []
	enemy_projectiles = []
	enemy_attack_warnings = []
	bombs = []
	chests = []
	hit_flashes = []
	effect_lines = []
	floating_texts = []
	background_particles = []
	crystal_walls = []
	danger_zones = []
	boss_spawned_minutes = []
	boss_warned_minutes = []
	boss_defeated_ids = []
	enemy_seen = []
	weapon_kill_counts = {}
	weapon_damage_by_id = {}
	weapon_pick_counts = {}
	passive_pick_counts = {}
	boss_damage_by_weapon_id = {}
	enemy_damage_by_weapon_id = {}
	damage_by_category = {}
	healing_by_source = {}
	currency_gain_by_source = {}
	evolution_time_by_weapon_id = {}
	weapons = {"magic_bolt": 1}
	passives = {}
	infinite_upgrades = {}
	weapon_cooldowns = {}
	evolved_weapons = {}
	evolved_magic_bolt = false
	last_evolution_seconds = -999.0
	_build_crystal_field()
	update_current_biome()
	_build_background_particles()

func _load_definitions() -> void:
	weapon_defs = _json_dict("res://data/weapons.json", _fallback_weapon_defs())
	passive_defs = _json_dict("res://data/passives.json", _fallback_passive_defs())
	enemy_defs = _json_dict("res://data/enemies.json", _fallback_enemy_defs())
	evolution_defs = _json_dict("res://data/evolutions.json", {})
	boss_defs = _json_dict("res://data/bosses.json", {})
	infinite_defs = _json_dict("res://data/infinite_upgrades.json", _fallback_infinite_defs())
	spawn_curve = _json_dict("res://data/spawn_curve.json", {"duration_seconds": 1800, "phases": []})
	balance_data = _json_dict("res://data/balance.json", _fallback_balance())
	difficulty_curve = _json_dict("res://data/difficulty_curve.json", {"tiers": [], "curve": []})
	overclock_defs = _json_dict("res://data/overclocks.json", {})
	field_event_defs = _json_dict("res://data/field_events.json", {"events": []})
	rune_contract_defs = _json_dict("res://data/rune_contracts.json", {})
	weapon_effect_defs = _json_dict("res://data/weapon_effects.json", {})
	build_synergy_defs = _json_dict("res://data/build_synergies.json", {})
	field_drop_defs = _json_dict("res://data/field_drops.json", {})
	field_drop_spawn_config = field_drop_defs.get("_config", {}).duplicate(true)
	field_drop_defs.erase("_config")
	field_gimmick_defs = _json_dict("res://data/field_gimmicks.json", {})
	ui_layout_defs = _json_dict("res://data/ui_layout.json", {"safe_margin": 24, "indicator_max_count": 3})
	field_help_defs = _json_dict("res://data/field_help.json", {"drops": {}, "gimmicks": {}, "events": {}})
	exploration_mastery_defs = _json_dict("res://data/exploration_mastery.json", {"ranks": [], "points": {}})
	exploration_chain_defs = _json_dict("res://data/exploration_chain.json", {"window_seconds": 60.0, "thresholds": {}})
	terrain_type_defs = _json_dict("res://data/terrain_types.json", {})
	map_generation_defs = _json_dict("res://data/map_generation.json", {})
	terrain_room_defs = _json_dict("res://data/terrain_rooms.json", {})

func _json_dict(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback.duplicate(true)
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return fallback.duplicate(true)

func _build_crystal_field() -> void:
	map_data = map_generator.generate(self, map_seed_text, map_seed)
	map_seed = int(map_data.get("seed", map_seed))
	if map_seed_text == "":
		map_seed_text = String(map_data.get("seed_text", str(map_seed)))
	danger_zones = map_data.get("danger_zones", [])
	navigation_targets = map_data.get("navigation_targets", {})
	field_drops = map_data.get("field_drops", [])
	field_gimmicks = map_data.get("field_gimmicks", [])
	crystal_walls = map_generator.build_walls(self, map_data)
	var rooms: Array = map_data.get("rooms", [])
	if not rooms.is_empty():
		player_position = rooms[0].get("position", field_size * 0.5)
		camera_position = player_position

func is_walkable_position(position: Vector2, radius: float = 0.0) -> bool:
	return tile_collision_system.is_walkable(map_data, position, radius)

func resolve_walkable_position(requested: Vector2, radius: float, fallback: Vector2) -> Vector2:
	return tile_collision_system.resolve_position(map_data, requested, radius, fallback)

func random_walkable_position(origin: Vector2, min_distance: float, max_distance: float) -> Vector2:
	return tile_collision_system.random_walkable_position(map_data, rng, origin, min_distance, max_distance)

func boss_room_position() -> Vector2:
	return navigation_targets.get("boss_arena", player_position)

func max_enemies() -> int:
	return int(balance_data.get("max_enemies", 550))

func max_gems() -> int:
	return int(balance_data.get("max_gems", 900))

func max_projectiles() -> int:
	return int(balance_data.get("max_projectiles", 420))

func max_enemy_projectiles() -> int:
	return int(balance_data.get("max_enemy_projectiles", 260))

func max_effects() -> int:
	return int(balance_data.get("max_effects", 200))

func max_texts() -> int:
	return int(balance_data.get("max_texts", 80))

func max_background_particles() -> int:
	return int(balance_data.get("max_background_particles", 300))

func max_chests() -> int:
	return int(balance_data.get("max_chests", 3))

func max_owned_weapons() -> int:
	return int(balance_data.get("max_owned_weapons", 6))

func max_owned_passives() -> int:
	return int(balance_data.get("max_owned_passives", 6))

func combo_timeout() -> float:
	return float(balance_data.get("combo_timeout", 1.5))

func elapsed_minutes() -> float:
	return elapsed_seconds / 60.0

func difficulty_snapshot() -> Dictionary:
	return difficulty_system.snapshot(self)

func difficulty_tier() -> int:
	return int(difficulty_snapshot().get("difficulty_tier", 1))

func difficulty_factor() -> float:
	return float(difficulty_snapshot().get("difficulty_factor", 1.0)) * cursed_power

func enemy_hp_multiplier() -> float:
	return float(difficulty_snapshot().get("enemy_hp_multiplier", 1.0)) * cursed_power

func enemy_speed_multiplier() -> float:
	return float(difficulty_snapshot().get("enemy_speed_multiplier", 1.0))

func enemy_spawn_multiplier() -> float:
	var value = float(difficulty_snapshot().get("enemy_spawn_multiplier", 1.0)) * rune_contract_spawn_multiplier()
	value *= modifier_mult("spawn_mult", 1.0)
	if active_field_event.get("id", "") == "gem_storm":
		value *= 1.30
	var pressure_per_drop = float(balance_data.get("exploration_enemy_pressure_per_dynamic_drop", 0.015))
	var pressure_cap = float(balance_data.get("exploration_enemy_pressure_cap", 0.18))
	value *= 1.0 + minf(pressure_cap, float(dynamic_drops_spawned) * pressure_per_drop)
	return value

func enemy_damage_multiplier() -> float:
	return float(difficulty_snapshot().get("enemy_damage_multiplier", 1.0)) * cursed_power

func enemy_projectile_multiplier() -> float:
	return 1.0 + float(difficulty_snapshot().get("enemy_projectile_rate", 0.0)) * 2.2

func elite_spawn_multiplier() -> float:
	var value = 1.0 + float(difficulty_snapshot().get("elite_rate", 0.02)) * 3.0
	if is_position_in_danger_zone(player_position):
		value *= float(balance_data.get("danger_elite_multiplier", 1.2))
	if active_field_event.get("id", "") == "elite_hunt":
		value *= 3.0
	return value

func enemy_special_rate() -> float:
	return float(difficulty_snapshot().get("enemy_special_rate", 0.0))

func enemy_projectile_rate() -> float:
	return float(difficulty_snapshot().get("enemy_projectile_rate", 0.0))

func elite_rate() -> float:
	return float(difficulty_snapshot().get("elite_rate", 0.02))

func boss_hp_multiplier_for_minute(minute: int) -> float:
	var boss_index = maxi(1, int(round(float(minute) / 5.0)))
	return pow(1.55, float(boss_index - 1)) * float(difficulty_snapshot().get("boss_hp_multiplier", 1.0)) * (1.0 + float(boss_enrage_count) * 0.35)

func crystal_hp_multiplier_for_position(pos: Vector2) -> float:
	var biome = biome_system.biome_for_position(self, pos)
	var value = float(difficulty_snapshot().get("crystal_hp_multiplier", 1.0)) * rune_contract_crystal_hp_multiplier()
	return value * biome_system.crystal_hp_multiplier(biome)

func update_current_biome() -> void:
	var biome = biome_system.current_biome(self)
	current_biome_id = String(biome.get("id", "star_plain"))
	current_biome_name = String(biome.get("name_ja", "星屑平原"))

func update_current_terrain(events: Array) -> void:
	terrain_room_system.update_state(self, events)

func current_terrain_guide() -> String:
	return terrain_room_system.guide_for_current(self)

func terrain_reward_multiplier() -> float:
	return terrain_room_system.terrain_value(self, "reward_mult", 1.0)

func terrain_spawn_multiplier() -> float:
	return terrain_room_system.terrain_value(self, "spawn_mult", 1.0)

func terrain_enemy_damage_multiplier() -> float:
	return terrain_room_system.terrain_value(self, "enemy_damage_mult", 1.0)

func apply_meta_modifiers() -> void:
	meta_hp_mult = 1.0 + 0.03 * float(meta_upgrade_levels.get("base_hp", 0))
	meta_damage_mult = 1.0 + 0.015 * float(meta_upgrade_levels.get("base_damage", 0))
	meta_magnet_mult = 1.0 + 0.03 * float(meta_upgrade_levels.get("base_magnet", 0))
	meta_currency_mult = 1.0 + 0.025 * float(meta_upgrade_levels.get("currency", 0))
	meta_crystal_damage_mult = 1.0 + 0.05 * float(meta_upgrade_levels.get("crystal_mining", 0))
	meta_chest_indicator_mult = 1.0 + 0.10 * float(meta_upgrade_levels.get("chest_sense", 0))
	max_hp = maxi(1, int(round(float(max_hp) * meta_hp_mult)))
	hp = max_hp

func modifier_mult(key: String, default_value: float = 1.0) -> float:
	return float(character_modifiers.get(key, 1.0)) * float(blessing_modifiers.get(key, 1.0)) * default_value

func modifier_add(key: String, default_value: float = 0.0) -> float:
	return float(character_modifiers.get(key, 0.0)) + float(blessing_modifiers.get(key, 0.0)) + default_value

func weapon_tags(weapon_id: String) -> Array:
	return weapon_defs.get(weapon_id, {}).get("tags", [])

func weapon_has_tag(weapon_id: String, tag: String) -> bool:
	for raw_tag in weapon_tags(weapon_id):
		if String(raw_tag) == tag:
			return true
	return false

func weapon_tag_multiplier(weapon_id: String, modifier_key: String) -> float:
	var value = 1.0
	var tags = weapon_tags(weapon_id)
	var char_table: Dictionary = character_modifiers.get(modifier_key, {})
	var blessing_table: Dictionary = blessing_modifiers.get(modifier_key, {})
	for tag in tags:
		value *= float(char_table.get(String(tag), 1.0))
		value *= float(blessing_table.get(String(tag), 1.0))
	return value

func get_damage_multiplier_for_weapon(weapon_id: String) -> float:
	var value = get_damage_multiplier() * weapon_tag_multiplier(weapon_id, "tag_damage")
	value *= category_damage_multiplier(weapon_id)
	value *= synergy_damage_multiplier(weapon_id)
	if melee_rush_timer > 0.0 and weapon_has_tag(weapon_id, "melee") and melee_rush_level >= 3:
		value *= 1.35
	if is_weapon_evolved(weapon_id):
		value *= float(character_modifiers.get("evolved_damage_mult", 1.0))
		value *= float(blessing_modifiers.get("evolved_damage_mult", 1.0))
	if current_terrain_id == "crystal_corridor":
		value *= 1.0 + 0.09 * float(passives.get("choke_point", 0))
	if current_terrain_id == "event_room":
		value *= float(character_modifiers.get("event_damage_mult", 1.0))
	return value

func get_area_multiplier_for_weapon(weapon_id: String) -> float:
	var value = get_area_multiplier() * weapon_tag_multiplier(weapon_id, "tag_area") * category_area_multiplier(weapon_id)
	if melee_rush_timer > 0.0 and weapon_has_tag(weapon_id, "melee"):
		value *= 1.20 if melee_rush_level == 1 else 1.30
	if active_synergies.has("star_reader") and (weapon_has_tag(weapon_id, "ranged") or weapon_has_tag(weapon_id, "laser") or weapon_has_tag(weapon_id, "area")):
		value *= 1.15
	if active_synergies.has("blast_core") and weapon_has_tag(weapon_id, "explosion"):
		value *= 1.20
	return value

func get_cooldown_multiplier_for_weapon(weapon_id: String) -> float:
	var value = get_cooldown_multiplier() * weapon_tag_multiplier(weapon_id, "tag_cooldown") * category_cooldown_multiplier(weapon_id)
	if active_synergies.has("blast_core") and weapon_has_tag(weapon_id, "explosion"):
		value *= 1.05
	return value

func category_damage_multiplier(weapon_id: String) -> float:
	match String(weapon_defs.get(weapon_id, {}).get("category", "")):
		"ranged":
			return 0.92
		"melee":
			return 1.20
		"lightning":
			return 0.92
		"poison":
			return 0.84
		"explosion":
			return 1.08
		"deploy":
			return 0.92
		"gem":
			return 0.80
		"knockback":
			return 0.84
		"crystal":
			return 0.94
	return 1.0

func category_area_multiplier(weapon_id: String) -> float:
	match String(weapon_defs.get(weapon_id, {}).get("category", "")):
		"melee":
			return 0.86
		"area":
			return 1.10
		"explosion":
			return 1.10
		"poison":
			return 1.12
		"laser":
			return 1.04
		"deploy":
			return 1.12
		"knockback":
			return 1.10
	return 1.0

func category_cooldown_multiplier(weapon_id: String) -> float:
	match String(weapon_defs.get(weapon_id, {}).get("category", "")):
		"ranged":
			return 0.96
		"melee":
			return 0.94
		"explosion":
			return 1.18
		"poison":
			return 1.00
		"deploy":
			return 0.92
		"gem":
			return 1.12
	return 1.0

func synergy_damage_multiplier(weapon_id: String) -> float:
	var value = 1.0
	if active_synergies.has("melee_ashura") and weapon_has_tag(weapon_id, "melee"):
		value *= 1.25
	if active_synergies.has("toxic_curse") and weapon_has_tag(weapon_id, "poison") and is_position_in_danger_zone(player_position):
		value *= 1.50
	return value

func crystal_damage_multiplier() -> float:
	return meta_crystal_damage_mult * modifier_mult("crystal_damage_mult", 1.0) * (1.0 + 0.14 * float(passives.get("wall_breaker", 0)))

func character_crystal_reward_multiplier() -> float:
	var value = modifier_mult("crystal_reward_mult", 1.0)
	value *= 1.0 + 0.09 * float(passives.get("mining_luck", 0))
	if active_synergies.has("mining_king"):
		value *= 1.30
	return value

func chest_indicator_multiplier() -> float:
	return meta_chest_indicator_mult * modifier_mult("chest_indicator_mult", 1.0)

func has_overclock(weapon_id: String, overclock_id: String) -> bool:
	return overclocks.has(weapon_id) and (overclocks[weapon_id] as Array).has(overclock_id)

func overclock_count(weapon_id: String) -> int:
	return (overclocks[weapon_id] as Array).size() if overclocks.has(weapon_id) else 0

func has_available_overclock() -> bool:
	if not overclock_timing_ready():
		return false
	for weapon_id in evolved_weapons.keys():
		if overclock_count(String(weapon_id)) >= int(balance_data.get("overclock_max_per_weapon", 2)):
			continue
		var evolution_id = String(evolved_weapons[weapon_id])
		for entry in overclock_defs.get(evolution_id, []):
			if not has_overclock(String(weapon_id), String(entry.get("id", ""))):
				return true
	return false

func overclock_timing_ready() -> bool:
	if evolved_weapons.is_empty():
		return false
	return elapsed_seconds - last_evolution_seconds >= float(balance_data.get("overclock_delay_seconds", 120.0))

func add_chest(chest) -> bool:
	if chests.size() >= int(balance_data.get("max_chests", 3)):
		return false
	chests.append(chest)
	return true

func chest_count() -> int:
	return chests.size()

func boss_alive() -> bool:
	return active_boss() != null

func active_boss():
	for enemy in enemies:
		if enemy.boss:
			return enemy
	return null

func strengthen_active_boss(events: Array, minute: int) -> bool:
	var boss = active_boss()
	if boss == null:
		return false
	boss_enrage_count += 1
	boss.max_hp = int(round(float(boss.max_hp) * 1.22))
	boss.hp = int(round(float(boss.hp) * 1.22)) + int(round(float(boss.max_hp) * 0.10))
	boss.damage = int(round(float(boss.damage) * 1.14))
	boss.speed *= 1.04
	boss.action_timer = minf(boss.action_timer, 0.8)
	boss.hp = mini(boss.hp, boss.max_hp)
	events.append({"type": "boss_enrage", "minute": minute, "enemy": boss.type, "count": boss_enrage_count})
	return true

func can_drop_elite_chest() -> bool:
	return elite_chest_cooldown <= 0.0 and chests.size() < int(balance_data.get("max_chests", 3))

func reset_elite_chest_cooldown() -> void:
	var luck = float(passives.get("luck", 0))
	elite_chest_cooldown = maxf(60.0, 90.0 - luck * 6.0)

func rune_contract_multiplier(key: String, default_value: float = 1.0) -> float:
	var value = default_value
	for id in rune_contracts:
		var data: Dictionary = rune_contract_defs.get(String(id), {})
		if data.has(key):
			value *= lerpf(1.0, float(data.get(key, 1.0)), modifier_mult("contract_effect_mult", 1.0))
	return value

func rune_contract_spawn_multiplier() -> float:
	return rune_contract_multiplier("spawn_mult", 1.0)

func rune_contract_crystal_hp_multiplier() -> float:
	return rune_contract_multiplier("crystal_hp_mult", 1.0)

func rune_contract_crystal_reward_multiplier() -> float:
	return rune_contract_multiplier("crystal_reward_mult", 1.0)

func rune_contract_damage_taken_multiplier() -> float:
	return rune_contract_multiplier("damage_taken_mult", 1.0)

func rune_contract_score_multiplier() -> float:
	return rune_contract_multiplier("score_mult", 1.0)

func rune_contract_gem_multiplier() -> float:
	return rune_contract_multiplier("gem_mult", 1.0)

func rare_reward_bonus() -> float:
	var bonus = 0.0
	for id in rune_contracts:
		var data: Dictionary = rune_contract_defs.get(String(id), {})
		bonus += float(data.get("rare_reward_bonus", 0.0))
	bonus += modifier_add("rare_reward_bonus", 0.0)
	return bonus

func update_minute_buckets() -> void:
	var minute = int(floor(elapsed_seconds / 60.0))
	if minute != damage_minute_bucket:
		damage_taken_last_minute = 0
		damage_minute_bucket = minute
	if minute != levelup_minute_bucket:
		levelups_last_minute = 0
		levelup_minute_bucket = minute

func can_offer_weapon(id: String) -> bool:
	if is_weapon_evolved(id):
		return false
	if not unlocked_weapon_ids.is_empty() and not unlocked_weapon_ids.has(id) and not weapons.has(id):
		return false
	if int(weapons.get(id, 0)) > 0:
		return int(weapons.get(id, 0)) < int(weapon_defs.get(id, {}).get("max_level", 8))
	if disabled_weapon_ids.has(id):
		return false
	return weapons.keys().size() < max_owned_weapons()

func can_offer_passive(id: String) -> bool:
	if not unlocked_passive_ids.is_empty() and not unlocked_passive_ids.has(id) and not passives.has(id):
		return false
	if int(passives.get(id, 0)) > 0:
		return int(passives.get(id, 0)) < int(passive_defs.get(id, {}).get("max_level", 5))
	if disabled_passive_ids.has(id):
		return false
	return passives.keys().size() < max_owned_passives()

func is_weapon_evolved(id: String) -> bool:
	return evolved_weapons.has(id) or (id == "magic_bolt" and evolved_magic_bolt)

func evolution_for_weapon(id: String) -> Dictionary:
	for evolution_id in evolution_defs.keys():
		var data = evolution_defs[evolution_id]
		if String(data.get("weapon", "")) == id:
			var result = data.duplicate(true)
			result["id"] = evolution_id
			return result
	return {}

func has_available_evolution() -> bool:
	if not evolution_timing_ready():
		return false
	for evolution_id in evolution_defs.keys():
		var data = evolution_defs[evolution_id]
		var weapon_id = String(data.get("weapon", ""))
		var passive_id = String(data.get("passive", ""))
		if weapon_id == "" or passive_id == "":
			continue
		if is_weapon_evolved(weapon_id):
			continue
		if int(weapons.get(weapon_id, 0)) >= int(data.get("weapon_level", 8)) and int(passives.get(passive_id, 0)) >= int(data.get("passive_level", 1)):
			return true
	return false

func evolution_timing_ready() -> bool:
	if elapsed_seconds < float(balance_data.get("first_evolution_seconds", 300.0)):
		return false
	if evolved_weapon_count <= 0:
		return true
	return elapsed_seconds - last_evolution_seconds >= float(balance_data.get("evolution_cooldown_seconds", 180.0))

func get_move_speed() -> float:
	var value = base_move_speed * (1.0 + 0.12 * float(passives.get("move_speed", 0)))
	if current_terrain_id == "crystal_corridor":
		value *= 1.0 + 0.065 * float(passives.get("corridor_sense", 0))
		value *= float(character_modifiers.get("corridor_move_mult", 1.0))
	elif current_terrain_id in ["safe_room", "mine_chamber", "danger_den", "healing_oasis", "relic_vault", "boss_arena", "event_room"]:
		value *= 1.0 + 0.05 * float(passives.get("open_field", 0))
		value *= float(character_modifiers.get("open_move_mult", 1.0))
	if melee_speed_timer > 0.0:
		value *= 1.18
	return value

func get_magnet_radius() -> float:
	var multiplier = 1.0 + 0.25 * float(passives.get("magnet", 0)) + 0.08 * float(infinite_upgrades.get("infinite_magnet", 0))
	multiplier *= meta_magnet_mult * modifier_mult("magnet_mult", 1.0)
	if combo_magnet_timer > 0.0:
		multiplier += 0.45
	if gem_fever_timer > 0.0:
		multiplier += 1.0 if gem_fever_tier >= 1 else 0.0
	return base_magnet_radius * multiplier

func get_damage_multiplier() -> float:
	return (1.0 + 0.13 * float(passives.get("might", 0)) + 0.05 * float(infinite_upgrades.get("infinite_damage", 0))) * rune_contract_multiplier("damage_mult", 1.0) * meta_damage_mult * modifier_mult("damage_mult", 1.0)

func get_cooldown_multiplier() -> float:
	var value = 1.0 - 0.065 * float(passives.get("cooldown", 0)) - 0.03 * float(infinite_upgrades.get("infinite_speed", 0))
	if gem_fever_timer > 0.0 and gem_fever_tier >= 2:
		value *= 0.80
	value *= rune_contract_multiplier("cooldown_mult", 1.0)
	value *= modifier_mult("cooldown_mult", 1.0)
	return maxf(0.32, value)

func get_area_multiplier() -> float:
	var value = (1.0 + 0.11 * float(passives.get("area", 0)) + 0.05 * float(infinite_upgrades.get("infinite_area", 0))) * modifier_mult("area_mult", 1.0)
	if current_terrain_id != "crystal_corridor":
		value *= 1.0 + 0.07 * float(passives.get("room_mastery", 0))
	return value

func get_score_multiplier(pos: Vector2 = Vector2.INF) -> float:
	var multiplier = 1.0 + 0.14 * float(passives.get("greed", 0)) + 0.10 * float(infinite_upgrades.get("infinite_greed", 0)) + 0.08 * float(passives.get("curse", 0))
	multiplier *= rune_contract_score_multiplier()
	multiplier *= modifier_mult("score_mult", 1.0)
	var check_pos = player_position if pos == Vector2.INF else pos
	if is_position_in_danger_zone(check_pos):
		var danger_bonus = rune_contract_multiplier("danger_bonus", 1.0) * modifier_mult("danger_reward_mult", 1.0)
		if hp_ratio() <= 0.30:
			multiplier *= float(balance_data.get("danger_low_hp_score_multiplier", 2.0)) * danger_bonus
		else:
			multiplier *= float(balance_data.get("danger_score_multiplier", 1.5)) * danger_bonus
	return multiplier

func get_gem_value_multiplier(pos: Vector2 = Vector2.INF) -> float:
	var multiplier = float(difficulty_snapshot().get("gem_value_multiplier", 1.0)) + 0.03 * float(infinite_upgrades.get("infinite_greed", 0))
	multiplier *= rune_contract_gem_multiplier()
	multiplier *= modifier_mult("gem_value_mult", 1.0)
	if active_field_event.get("id", "") == "gem_storm":
		multiplier *= 1.65
	if recall_drone_active_timer > 0.0:
		multiplier *= 1.20
	if gem_fever_timer > 0.0:
		multiplier *= 1.60 if gem_fever_tier >= 2 else 1.30
	var check_pos = player_position if pos == Vector2.INF else pos
	if is_position_in_danger_zone(check_pos):
		var danger_bonus = rune_contract_multiplier("danger_bonus", 1.0) * modifier_mult("danger_reward_mult", 1.0)
		if hp_ratio() <= 0.30:
			multiplier *= float(balance_data.get("danger_low_hp_gem_multiplier", 1.5)) * danger_bonus
		else:
			multiplier *= float(balance_data.get("danger_gem_multiplier", 1.3)) * danger_bonus
	return multiplier

func get_combo_exp_multiplier() -> float:
	if pickup_combo_count >= 200:
		return 1.24
	if pickup_combo_count >= 100:
		return 1.18
	if pickup_combo_count >= 50:
		return 1.12
	if pickup_combo_count >= 25:
		return 1.07
	if pickup_combo_count >= 10:
		return 1.03
	return 1.0

func get_exp_drop_multiplier() -> float:
	var minutes = elapsed_minutes()
	var value = 0.09 + minf(minutes, 30.0) * 0.003
	if minutes < 3.0:
		value = lerpf(0.24, value, clampf(minutes / 3.0, 0.0, 1.0))
	if is_position_in_danger_zone(player_position):
		value *= 1.12
	if active_field_event.get("id", "") == "gem_storm":
		value *= 1.10
	return value

func should_drop_normal_exp() -> bool:
	var minutes = elapsed_minutes()
	var chance = 0.28 + minf(minutes, 30.0) * 0.004
	if minutes < 3.0:
		chance = lerpf(0.76, chance, clampf(minutes / 3.0, 0.0, 1.0))
	if active_field_event.get("id", "") == "gem_storm":
		chance += 0.16
	if is_position_in_danger_zone(player_position):
		chance += 0.10
	exp_drop_meter += clampf(chance, 0.20, 0.82)
	if exp_drop_meter < 1.0:
		return false
	exp_drop_meter -= 1.0
	return true

func get_combo_score_multiplier() -> float:
	if pickup_combo_count >= 200:
		return 1.50
	if pickup_combo_count >= 100:
		return 1.34
	if pickup_combo_count >= 50:
		return 1.22
	if pickup_combo_count >= 25:
		return 1.12
	if pickup_combo_count >= 10:
		return 1.06
	return 1.0

func get_danger_spawn_multiplier() -> float:
	if is_position_in_danger_zone(player_position):
		return float(balance_data.get("danger_spawn_multiplier", 1.3))
	return 1.0

func is_position_in_danger_zone(pos: Vector2) -> bool:
	for zone in danger_zones:
		var center: Vector2 = zone.get("position", Vector2.ZERO)
		var radius = float(zone.get("radius", 0.0))
		if pos.distance_to(center) <= radius:
			return true
	return false

func hp_ratio() -> float:
	if max_hp <= 0:
		return 0.0
	return clampf(float(hp) / float(max_hp), 0.0, 1.0)

func get_weapon_label() -> String:
	var labels: Array = []
	for id in weapons.keys():
		labels.append("%s Lv%d" % [weapon_name(String(id)), int(weapons[id])])
	return "武器 %d/%d：" % [weapons.keys().size(), max_owned_weapons()] + " / ".join(labels)

func get_passive_label() -> String:
	var labels: Array = []
	for id in passives.keys():
		labels.append("%s Lv%d" % [passive_name(String(id)), int(passives[id])])
	if labels.is_empty():
		return "パッシブ 0/%d：なし" % max_owned_passives()
	return "パッシブ %d/%d：" % [passives.keys().size(), max_owned_passives()] + " / ".join(labels)

func weapon_name(id: String) -> String:
	if is_weapon_evolved(id):
		var evolution = evolution_for_weapon(id)
		return String(evolution.get("name_ja", weapon_defs.get(id, {}).get("name_ja", id)))
	return String(weapon_defs.get(id, {}).get("name_ja", id))

func passive_name(id: String) -> String:
	return String(passive_defs.get(id, {}).get("name_ja", id))

func weapon_effect(weapon_id: String) -> Dictionary:
	var definition: Dictionary = weapon_defs.get(weapon_id, {})
	var effect_id = String(definition.get("effect_id", weapon_id))
	var data: Dictionary = weapon_effect_defs.get(effect_id, {})
	if data.is_empty():
		return {}
	var effect: Dictionary = data.get("evolved", {}) if is_weapon_evolved(weapon_id) else data.get("normal", {})
	var result = effect.duplicate(true)
	for key in ["effect_type", "primary_color", "secondary_color", "hit_effect", "evolved_effect_type", "screen_priority", "opacity", "lifetime", "max_effect_count", "melee_arc", "lightning_line", "shock_icon"]:
		if data.has(key) and not result.has(key):
			result[key] = data[key]
	return result

func active_synergy_label() -> String:
	if active_synergies.is_empty():
		return "ビルド相性：なし"
	var labels: Array = []
	for id in active_synergies.keys():
		labels.append(String(active_synergies[id].get("name_ja", id)))
	return "ビルド相性：" + " / ".join(labels)

func map_signature() -> String:
	return map_generator.signature(map_data)

func map_start_area_is_safe() -> bool:
	return map_generator.start_area_is_safe(map_data, field_size * 0.5)

func max_weapon_label() -> String:
	var best_id = "magic_bolt"
	var best_level = 0
	for id in weapons.keys():
		var weapon_level = int(weapons[id])
		if is_weapon_evolved(String(id)):
			weapon_level += 100
		if weapon_level > best_level:
			best_level = weapon_level
			best_id = String(id)
	if is_weapon_evolved(best_id):
		return weapon_name(best_id)
	return "%s Lv%d" % [weapon_name(best_id), int(weapons.get(best_id, 1))]

func add_score(base: int, pos: Vector2 = Vector2.INF) -> void:
	score += int(round(float(base) * get_score_multiplier(pos)))

func record_damage(amount: int) -> void:
	if amount > max_damage:
		max_damage = amount

func record_damage_taken(amount: int) -> void:
	damage_taken_last_minute += amount

func add_floating_text(text: String, pos: Vector2, color: Color) -> void:
	damage_number_spawn_count += 1
	floating_texts.append(pool_manager.acquire("damage_text", [{"text": text, "pos": pos, "life": 1.0, "color": color}]))
	while floating_texts.size() > max_texts():
		release_runtime("damage_text", floating_texts.pop_front())

func trim_runtime_arrays() -> void:
	while projectiles.size() > max_projectiles():
		release_runtime("projectile", projectiles.pop_front())
	while enemy_projectiles.size() > max_enemy_projectiles():
		enemy_projectiles.pop_front()
	while enemy_attack_warnings.size() > 80:
		enemy_attack_warnings.pop_front()
	while gems.size() > max_gems():
		release_runtime("gem", gems.pop_front())
	while hit_flashes.size() > max_effects():
		release_runtime("hit_flash", hit_flashes.pop_front())
	while effect_lines.size() > max_effects():
		release_runtime("effect_line", effect_lines.pop_front())
	while floating_texts.size() > max_texts():
		release_runtime("damage_text", floating_texts.pop_front())

func _exp_needed_for_level(value: int) -> int:
	var required = 20.0 + floor(12.0 * pow(float(value), 1.55)) + floor(float(value * value) * 0.28)
	required *= 1.0 + minf(1.00, maxf(0.0, float(value - 8)) * 0.05)
	required *= 1.0 + maxf(0.0, elapsed_minutes() - 20.0) * 0.015
	return maxi(8, int(round(required)))

func refresh_exp_goal() -> void:
	exp_to_next = _exp_needed_for_level(level)

func update_best_score(events: Array) -> void:
	title_badges = build_title_badges()
	var final_score = score + int(elapsed_seconds) * 6 + kills * 9 + level * 120 + gems_collected * 2 + crystals_destroyed * 75 + chests_opened * 160 + rune_contracts.size() * 900 + _total_overclock_count() * 650
	score = final_score
	if score > best_score:
		best_score = score
		best_score_updated = true
		SaveSystem.new().save_best_score(best_score)
		events.append({"type": "best_score", "value": best_score})

func build_title_badges() -> Array:
	var badges: Array = []
	if evolved_weapon_count >= 3:
		badges.append("進化中毒者")
	if max_combo >= 300:
		badges.append("ジェム掃除機")
	if crystals_destroyed >= 50:
		badges.append("採掘王")
	if danger_time >= 180.0:
		badges.append("命知らず")
	if low_hp_survival_time >= 60.0:
		badges.append("不死鳥")
	if kills >= 5000:
		badges.append("殲滅者")
	if boss_spawned_minutes.has(30) and elapsed_seconds >= 1800.0:
		badges.append("30分到達者")
	if rune_contracts.size() >= 3:
		badges.append("契約者")
	if _total_overclock_count() >= 3:
		badges.append("過充電職人")
	if recall_drone_activations >= 3:
		badges.append("回収名人")
	if field_event_count >= 5:
		badges.append("イベント荒らし")
	for terrain_title in terrain_achievement_system.titles_for_state(self):
		if not badges.has(terrain_title):
			badges.append(terrain_title)
	if badges.is_empty():
		badges.append("クリスタル挑戦者")
	return badges

func _total_overclock_count() -> int:
	var total = 0
	for weapon_id in overclocks.keys():
		total += (overclocks[weapon_id] as Array).size()
	return total

func _build_background_particles() -> void:
	background_particles = []
	for decoration in map_data.get("decorations", []):
		background_particles.append({
			"pos": decoration.get("position", Vector2.ZERO),
			"radius": float(decoration.get("radius", 2.0)),
			"phase": float(decoration.get("phase", 0.0)),
			"biome": "generated"
		})
	var count = max_background_particles()
	for i in range(maxi(0, count - background_particles.size())):
		var x = rng.range_float(0.0, field_size.x)
		var y = rng.range_float(0.0, field_size.y)
		var biome = biome_system.biome_for_position(self, Vector2(x, y))
		background_particles.append({
			"pos": Vector2(x, y),
			"radius": rng.range_float(1.0, 3.8),
			"phase": rng.range_float(0.0, TAU),
			"biome": String(biome.get("id", "star_plain"))
		})

func _fallback_weapon_defs() -> Dictionary:
	return {
		"magic_bolt": {"name_ja": "魔弾", "max_level": 8, "description_ja": "近い敵へ自動弾"},
		"ice_orbit": {"name_ja": "氷輪", "max_level": 8, "description_ja": "周囲を回る氷の輪"},
		"thunder_chain": {"name_ja": "雷撃", "max_level": 8, "description_ja": "近い敵へ連鎖雷"},
		"bomb_seed": {"name_ja": "爆種", "max_level": 8, "description_ja": "時間差で爆発する種"},
		"blade_fan": {"name_ja": "刃扇", "max_level": 8, "description_ja": "扇状の刃"},
		"laser_lance": {"name_ja": "光槍", "max_level": 8, "description_ja": "直線貫通"},
		"poison_mist": {"name_ja": "毒霧", "max_level": 8, "description_ja": "継続範囲"},
		"drone_bit": {"name_ja": "浮遊ビット", "max_level": 8, "description_ja": "自動射撃"},
		"crystal_mine": {"name_ja": "結晶地雷", "max_level": 8, "description_ja": "設置爆発"},
		"black_hole": {"name_ja": "小型重力球", "max_level": 8, "description_ja": "引き寄せ"}
	}

func _fallback_passive_defs() -> Dictionary:
	return {
		"move_speed": {"name_ja": "軽量ブーツ", "max_level": 5, "description_ja": "移動速度UP"},
		"magnet": {"name_ja": "磁力コア", "max_level": 5, "description_ja": "ジェム吸収範囲UP"},
		"might": {"name_ja": "力の紋章", "max_level": 5, "description_ja": "全武器ダメージUP"},
		"cooldown": {"name_ja": "速射回路", "max_level": 5, "description_ja": "攻撃間隔短縮"},
		"area": {"name_ja": "拡張リング", "max_level": 5, "description_ja": "攻撃範囲UP"},
		"max_hp": {"name_ja": "生命の器", "max_level": 5, "description_ja": "最大HPUP"},
		"regen": {"name_ja": "再生細胞", "max_level": 5, "description_ja": "少しずつHP回復"},
		"greed": {"name_ja": "欲張り袋", "max_level": 5, "description_ja": "スコア獲得量UP"},
		"armor": {"name_ja": "甲殻装甲", "max_level": 5, "description_ja": "ダメージ軽減"},
		"revival": {"name_ja": "復活の羽", "max_level": 1, "description_ja": "一度復活"},
		"curse": {"name_ja": "呪いの鈴", "max_level": 5, "description_ja": "敵増加と報酬UP"},
		"projectile_count": {"name_ja": "多重射出", "max_level": 3, "description_ja": "弾数UP"},
		"pickup_heal": {"name_ja": "吸収治癒", "max_level": 5, "description_ja": "吸収回復"},
		"elite_hunter": {"name_ja": "狩人の証", "max_level": 5, "description_ja": "強敵特効"},
		"crystal_breaker": {"name_ja": "採掘グローブ", "max_level": 5, "description_ja": "壁破壊UP"},
		"luck": {"name_ja": "幸運のお守り", "max_level": 5, "description_ja": "報酬率UP"}
	}

func _fallback_enemy_defs() -> Dictionary:
	return {
		"slime": {"name_ja": "スライム", "hp": 4, "speed": 68.0, "damage": 7, "score": 20, "exp": 5, "radius": 18.0, "unlock_seconds": 0, "weight": 100},
		"bat": {"name_ja": "コウモリ", "hp": 3, "speed": 118.0, "damage": 6, "score": 28, "exp": 5, "radius": 15.0, "unlock_seconds": 60, "weight": 55},
		"elite": {"name_ja": "エリート", "hp": 42, "speed": 60.0, "damage": 16, "score": 420, "exp": 28, "radius": 32.0, "unlock_seconds": 300, "weight": 5, "elite": true, "guaranteed_chest": true}
	}

func _fallback_infinite_defs() -> Dictionary:
	return {
		"infinite_damage": {"name_ja": "無限強化：攻撃力", "description_ja": "全武器ダメージ +5%"},
		"infinite_speed": {"name_ja": "無限強化：連射", "description_ja": "攻撃間隔 -3%"},
		"infinite_area": {"name_ja": "無限強化：範囲", "description_ja": "攻撃範囲 +5%"},
		"infinite_magnet": {"name_ja": "無限強化：吸収", "description_ja": "ジェム吸収範囲 +8%"},
		"infinite_hp": {"name_ja": "無限強化：生命", "description_ja": "最大HP +10 / HP +10"},
		"infinite_greed": {"name_ja": "無限強化：欲張り", "description_ja": "スコア +10% / ジェム価値 +3%"}
	}

func _fallback_balance() -> Dictionary:
	return {
		"field_width": 6600,
		"field_height": 6600,
		"player_hp": 110,
		"player_move_speed": 226.0,
		"base_magnet_radius": 86.0,
		"max_owned_weapons": 6,
		"max_owned_passives": 6,
		"max_enemies": 600,
		"max_gems": 1000,
		"max_projectiles": 500,
		"max_enemy_projectiles": 260,
		"max_effects": 200,
		"max_texts": 80,
		"max_chests": 3,
		"chest_ttl_seconds": 300.0,
		"recall_drone_charge_seconds": 180.0,
		"combo_timeout": 1.5
	}
