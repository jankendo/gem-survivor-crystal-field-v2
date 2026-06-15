extends RefCounted
class_name SaveSystem

const SAVE_PATH := "user://chrono_merge_tactics.save"

static var write_count := 0

var path := SAVE_PATH
var last_serialized := ""

func _init(custom_path: String = "") -> void:
	if custom_path != "":
		path = custom_path

func load_best_score() -> int:
	return int(load_data().get("best_score", 0))

func save_best_score(best_score: int) -> void:
	var data := load_data()
	data["best_score"] = best_score
	save_data(data)

func load_help_seen() -> bool:
	return bool(load_data().get("help_seen", false))

func save_help_seen(seen: bool) -> void:
	var data := load_data()
	data["help_seen"] = seen
	save_data(data)

func load_data() -> Dictionary:
	var data = _load_raw()
	return _with_defaults(data)

func save_data(data: Dictionary) -> void:
	_save_data(_with_defaults(data))

static func get_write_count() -> int:
	return write_count

func get_currency() -> int:
	return int(load_data().get("crystal_currency", 0))

func add_currency(amount: int) -> int:
	var data := load_data()
	data["crystal_currency"] = maxi(0, int(data.get("crystal_currency", 0)) + amount)
	save_data(data)
	return int(data["crystal_currency"])

func spend_currency(amount: int) -> bool:
	var data := load_data()
	if int(data.get("crystal_currency", 0)) < amount:
		return false
	data["crystal_currency"] = int(data.get("crystal_currency", 0)) - amount
	save_data(data)
	return true

func is_character_unlocked(character_id: String) -> bool:
	return (load_data().get("unlocked_characters", []) as Array).has(character_id)

func unlock_character(character_id: String) -> void:
	var data := load_data()
	var unlocked: Array = data.get("unlocked_characters", [])
	if not unlocked.has(character_id):
		unlocked.append(character_id)
	data["unlocked_characters"] = unlocked
	save_data(data)

func select_character(character_id: String) -> bool:
	if not is_character_unlocked(character_id):
		return false
	var data := load_data()
	data["selected_character"] = character_id
	save_data(data)
	return true

func selected_character() -> String:
	return String(load_data().get("selected_character", "noah"))

func selected_blessing() -> String:
	return String(load_data().get("selected_blessing", "attack"))

func select_blessing(blessing_id: String) -> void:
	var data := load_data()
	data["selected_blessing"] = blessing_id
	save_data(data)

func mark_field_discovered(kind: String, id: String) -> void:
	if kind == "" or id == "":
		return
	var data := load_data()
	var discovered: Dictionary = data.get("field_help_discovered", {})
	discovered["%s:%s" % [kind, id]] = true
	data["field_help_discovered"] = discovered
	var collection_discovered: Dictionary = data.get("collection_discovered", {})
	var tab = "field_%ss" % kind if kind in ["drop", "gimmick", "event"] else ""
	if tab != "":
		var table: Dictionary = collection_discovered.get(tab, {})
		table[id] = true
		collection_discovered[tab] = table
		data["collection_discovered"] = collection_discovered
	save_data(data)

func update_settings(settings_patch: Dictionary) -> void:
	var data := load_data()
	var settings: Dictionary = data.get("settings", {})
	for key in settings_patch.keys():
		settings[String(key)] = settings_patch[key]
	data["settings"] = settings
	save_data(data)

func get_setting(key: String, fallback = null):
	return load_data().get("settings", {}).get(key, fallback)

func reset_play_data(confirm_text: String) -> bool:
	if confirm_text != "RESET" and confirm_text != "初期化":
		return false
	var old := load_data()
	var kept_settings: Dictionary = old.get("settings", {}).duplicate(true)
	var kept_help = bool(old.get("help_seen", false))
	var fresh = _with_defaults({})
	fresh["settings"] = kept_settings
	fresh["help_seen"] = kept_help
	save_data(fresh)
	return true

func record_character_result(character_id: String, summary: Dictionary) -> void:
	var data := load_data()
	var records: Dictionary = data.get("character_records", {})
	var current: Dictionary = records.get(character_id, {})
	current["best_survival"] = maxf(float(current.get("best_survival", 0.0)), float(summary.get("survival_time", 0.0)))
	current["best_kills"] = maxi(int(current.get("best_kills", 0)), int(summary.get("kills", 0)))
	current["best_score"] = maxi(int(current.get("best_score", 0)), int(summary.get("score", 0)))
	records[character_id] = current
	data["character_records"] = records
	save_data(data)

func _load_raw() -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

func _save_data(data: Dictionary) -> void:
	var serialized := JSON.stringify(data, "\t")
	if serialized == last_serialized:
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save file.")
		return
	file.store_string(serialized)
	last_serialized = serialized
	write_count += 1

func _with_defaults(raw: Dictionary) -> Dictionary:
	var data = raw.duplicate(true)
	if not data.has("best_score"):
		data["best_score"] = 0
	if not data.has("help_seen"):
		data["help_seen"] = false
	if not data.has("crystal_currency"):
		data["crystal_currency"] = 0
	if not data.has("unlocked_characters"):
		data["unlocked_characters"] = ["noah"]
	if not (data.get("unlocked_characters", []) as Array).has("noah"):
		var unlocked: Array = data.get("unlocked_characters", [])
		unlocked.append("noah")
		data["unlocked_characters"] = unlocked
	if not data.has("selected_character"):
		data["selected_character"] = "noah"
	if not data.has("selected_blessing"):
		data["selected_blessing"] = "attack"
	if not data.has("unlocked_blessings"):
		data["unlocked_blessings"] = ["attack"]
	if not data.has("unlocked_weapons"):
		data["unlocked_weapons"] = _initial_unlock_ids("res://data/weapon_unlocks.json")
	if not data.has("unlocked_passives"):
		data["unlocked_passives"] = _initial_unlock_ids("res://data/passive_unlocks.json")
	if not data.has("disabled_weapons"):
		data["disabled_weapons"] = []
	if not data.has("disabled_passives"):
		data["disabled_passives"] = []
	if not data.has("weapon_disable_slots"):
		data["weapon_disable_slots"] = 2
	if not data.has("passive_disable_slots"):
		data["passive_disable_slots"] = 2
	if not data.has("meta_upgrades"):
		data["meta_upgrades"] = {}
	if not data.has("currency_sink_levels"):
		data["currency_sink_levels"] = {}
	if not data.has("stats"):
		data["stats"] = {
			"total_kills": 0,
			"total_survival": 0.0,
			"total_crystals": 0,
			"total_chests": 0,
			"total_contracts": 0,
			"best_survival": 0.0,
			"max_combo": 0,
			"survive_10_runs": 0
		}
	if not data.has("weapon_highest_levels"):
		data["weapon_highest_levels"] = {}
	if not data.has("weapon_kills"):
		data["weapon_kills"] = {}
	if not data.has("evolved_weapons"):
		data["evolved_weapons"] = {}
	if not data.has("boss_defeats"):
		data["boss_defeats"] = {}
	if not data.has("titles"):
		data["titles"] = {}
	if not data.has("secret_flags"):
		data["secret_flags"] = {}
	if not data.has("character_records"):
		data["character_records"] = {}
	if not data.has("character_mastery"):
		data["character_mastery"] = {}
	if not data.has("quests_completed"):
		data["quests_completed"] = {}
	if not data.has("quests_claimed"):
		data["quests_claimed"] = {}
	if not data.has("collection_discovered"):
		data["collection_discovered"] = {
			"weapons": {},
			"passives": {},
			"evolutions": {},
			"enemies": {},
			"bosses": {},
			"characters": {"noah": true},
			"blessings": {"attack": true},
			"field_drops": {},
			"field_gimmicks": {},
			"field_events": {},
			"titles": {}
		}
	if not data.has("field_help_discovered"):
		data["field_help_discovered"] = {}
	if not data.has("settings"):
		data["settings"] = {
			"bgm_volume": 0.85,
			"se_volume": 0.90,
			"screen_shake": true,
			"damage_numbers": true,
			"gem_sound": true,
			"auto_infinite": true,
			"auto_recall_drone": false,
			"fullscreen": false,
			"window_size": "1280x720",
			"show_controls": true,
			"seed_text": "",
			"ui_scale": 1.0,
			"touch_ui_mode": "auto",
			"virtual_joystick_enabled": true,
			"touch_button_size": "standard",
			"touch_button_opacity": 0.78,
			"touch_handedness": "right",
			"move_control_mode": "dynamic",
			"joystick_visual_mode": "active",
			"joystick_deadzone": 0.12,
			"joystick_sensitivity": 1.0,
			"touch_haptics": true,
			"touch_tutorial_seen": false,
			"hud_scale": 1.0,
			"safe_area_margin": 16.0,
			"notification_log_amount": "standard",
			"render_quality": "standard",
			"joystick_offset_x": 0.0,
			"joystick_offset_y": 0.0,
			"minimap_size": "standard",
			"minimap_opacity": "standard",
			"map_tap_expand": true,
			"camera_view_size": "standard",
			"equipment_hud_mode": "simple",
			"developer_overlay": false,
			"developer_mode": false,
			"touch_hit_test_debug": false,
			"touch_action_audit": false,
			"ui_animation_amount": "standard",
			"minimap_update_hz": 8,
			"background_particles": true,
			"low_power_mode": false
		}
	var stat_defaults := {
		"total_kills": 0,
		"total_survival": 0.0,
		"total_crystals": 0,
		"total_chests": 0,
		"total_contracts": 0,
		"total_currency_earned": 0,
		"best_survival": 0.0,
		"best_danger_time": 0.0,
		"max_combo": 0,
		"survive_10_runs": 0,
		"run_explosion_weapons": 0,
		"best_exploration_rank": "D",
		"best_exploration_score": 0,
		"max_exploration_chain": 0,
		"field_event_successes": 0
		,"rooms_discovered": 0,
		"max_rooms_in_run": 0,
		"shortcut_walls_broken": 0,
		"oasis_healing": 0,
		"cursed_relics": 0,
		"low_hp_time": 0.0,
		"terrain_time": {},
		"terrain_kills": {},
		"terrain_crystals": {}
		,"field_drops_collected": 0,
		"field_gimmicks_triggered": 0
		,"kills_by_weapon_tag": {}
		,"kills_by_weapon_id": {}
		,"kills_by_biome": {}
		,"kills_in_terrain_type": {}
		,"walls_broken": 0
		,"events_completed": 0
		,"field_gimmicks_used": 0
		,"bosses_killed": 0
		,"elites_killed": 0
		,"survival_time_total": 0.0
		,"survival_time_by_terrain": {}
		,"highest_exploration_rank": "D"
		,"exploration_rank_count": {}
		,"crystal_currency_total_earned": 0
		,"blessing_used_count": {}
		,"weapon_pick_count": {}
		,"passive_pick_count": {}
		,"evolution_count": 0
		,"overclock_count": 0
	}
	var stats: Dictionary = data.get("stats", {})
	for key in stat_defaults.keys():
		if not stats.has(key):
			stats[key] = stat_defaults[key]
	data["stats"] = stats
	var setting_defaults := {
		"bgm_volume": 0.85,
		"se_volume": 0.90,
		"screen_shake": true,
		"damage_numbers": true,
		"gem_sound": true,
		"auto_infinite": true,
		"auto_recall_drone": false,
		"fullscreen": false,
		"window_size": "1280x720",
		"show_controls": true,
		"seed_text": "",
		"ui_scale": 1.0,
		"speed_hold_enabled": true,
		"speed_hold_key": "left_shift",
		"speed_multiplier": 2.0,
		"notification_log_enabled": true,
		"weapon_hud_enabled": true,
		"passive_hud_enabled": true,
		"boss_alert_intensity": "strong",
		"effect_density": "normal",
		"touch_ui_mode": "auto",
		"virtual_joystick_enabled": true,
		"touch_button_size": "standard",
		"touch_button_opacity": 0.78,
		"touch_handedness": "right",
		"move_control_mode": "dynamic",
		"joystick_visual_mode": "active",
		"joystick_deadzone": 0.12,
		"joystick_sensitivity": 1.0,
		"touch_haptics": true,
		"touch_tutorial_seen": false,
		"hud_scale": 1.0,
		"safe_area_margin": 16.0,
		"notification_log_amount": "standard",
		"render_quality": "standard",
		"joystick_offset_x": 0.0,
		"joystick_offset_y": 0.0,
		"minimap_size": "standard",
		"minimap_opacity": "standard",
		"map_tap_expand": true,
		"camera_view_size": "standard",
		"equipment_hud_mode": "simple",
		"developer_overlay": false,
		"developer_mode": false,
		"touch_hit_test_debug": false,
		"touch_action_audit": false,
		"ui_animation_amount": "standard",
		"minimap_update_hz": 8,
		"background_particles": true,
		"low_power_mode": false,
		"battery_saver": false
	}
	var settings: Dictionary = data.get("settings", {})
	for key in setting_defaults.keys():
		if not settings.has(key):
			settings[key] = setting_defaults[key]
	data["settings"] = settings
	return data

func _initial_unlock_ids(path_value: String) -> Array:
	if not FileAccess.file_exists(path_value):
		return []
	var file = FileAccess.open(path_value, FileAccess.READ)
	if file == null:
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return []
	var result: Array = []
	for raw_id in parsed.keys():
		if bool(parsed[raw_id].get("initial", false)):
			result.append(String(raw_id))
	return result
