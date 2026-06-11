extends Control
class_name GameScreen

const JaText = preload("res://scripts/ui/JaText.gd")
const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const PlayerScript = preload("res://scripts/systems/Player.gd")
const WeaponSystemScript = preload("res://scripts/systems/WeaponSystem.gd")
const EnemySpawnerScript = preload("res://scripts/systems/EnemySpawner.gd")
const PickupSystemScript = preload("res://scripts/systems/PickupSystem.gd")
const LevelUpSystemScript = preload("res://scripts/systems/LevelUpSystem.gd")
const ChestSystemScript = preload("res://scripts/systems/ChestSystem.gd")
const CrystalFieldSystemScript = preload("res://scripts/systems/CrystalFieldSystem.gd")
const FieldEventSystemScript = preload("res://scripts/systems/FieldEventSystem.gd")
const BalanceLogSystemScript = preload("res://scripts/systems/BalanceLogSystem.gd")
const RecallDroneSystemScript = preload("res://scripts/systems/RecallDroneSystem.gd")
const MetaProgressionSystemScript = preload("res://scripts/systems/MetaProgressionSystem.gd")
const BuildSynergySystemScript = preload("res://scripts/systems/BuildSynergySystem.gd")
const MeleeRushSystemScript = preload("res://scripts/systems/MeleeRushSystem.gd")
const ShockStackSystemScript = preload("res://scripts/systems/ShockStackSystem.gd")
const FieldDropSystemScript = preload("res://scripts/systems/FieldDropSystem.gd")
const FieldGimmickSystemScript = preload("res://scripts/systems/FieldGimmickSystem.gd")
const UiSafeAreaSystemScript = preload("res://scripts/systems/UiSafeAreaSystem.gd")
const FieldDropSpawnSystemScript = preload("res://scripts/systems/FieldDropSpawnSystem.gd")
const FieldHelpSystemScript = preload("res://scripts/systems/FieldHelpSystem.gd")
const GoalHintSystemScript = preload("res://scripts/systems/GoalHintSystem.gd")
const ExplorationMasterySystemScript = preload("res://scripts/systems/ExplorationMasterySystem.gd")
const ExplorationChainSystemScript = preload("res://scripts/systems/ExplorationChainSystem.gd")
const TooltipSystemScript = preload("res://scripts/systems/TooltipSystem.gd")
const UiLayoutFixSystemScript = preload("res://scripts/systems/UiLayoutFixSystem.gd")
const SpeedHoldSystemScript = preload("res://scripts/systems/SpeedHoldSystem.gd")
const NotificationLogSystemScript = preload("res://scripts/systems/NotificationLogSystem.gd")
const BossAlertSystemScript = preload("res://scripts/systems/BossAlertSystem.gd")
const EquipmentHudSystemScript = preload("res://scripts/systems/EquipmentHudSystem.gd")
const ArenaViewScript = preload("res://scripts/ui/ArenaView.gd")
const CrystalButtonScript = preload("res://scripts/ui/components/CrystalButton.gd")
const ConfirmDialogScript = preload("res://scripts/ui/components/ConfirmDialog.gd")

signal game_finished(summary: Dictionary)
signal title_requested

var state
var player_system
var weapon_system
var enemy_spawner
var pickup_system
var level_up_system
var chest_system
var field_system
var field_event_system
var balance_log_system
var recall_drone_system
var meta_system
var build_synergy_system
var melee_rush_system
var shock_stack_system
var field_drop_system
var field_gimmick_system
var ui_safe_area_system
var field_drop_spawn_system
var field_help_system
var goal_hint_system
var exploration_mastery_system
var exploration_chain_system
var tooltip_system
var ui_layout_fix_system
var speed_hold_system
var notification_log_system
var boss_alert_system
var equipment_hud_system
var arena_view
var audio_manager: AudioManager
var reward_popup: RewardPopup
var hp_label: Label
var hp_bar: ProgressBar
var hud_label: Label
var weapon_label: Label
var passive_label: Label
var combo_label: Label
var message_label: Label
var exp_bar: ProgressBar
var goal_label: Label
var event_label: Label
var field_help_label: Label
var exploration_label: Label
var speed_label: Label
var notification_label: Label
var boss_alert_label: Label
var boss_hp_label: Label
var boss_hp_bar: ProgressBar
var low_hp_overlay: ColorRect
var pending_finish = false
var initial_auto_infinite_enabled = true
var initial_character_id = "noah"
var initial_blessing_id = "attack"
var initial_save_data: Dictionary = {}
var initial_seed_text := ""
var pause_overlay: PanelContainer
var pause_content: Label
var pause_action_row: HBoxContainer
var pause_confirm_dialog
var pause_title_label: Label
var pause_summary: Label
var pause_tab_buttons: Array = []
var pause_tab_index := 0
var pause_tabs := ["ステータス", "武器", "パッシブ", "進化条件", "ビルド相性", "フィールドヘルプ", "契約/過充電", "設定", "ログ"]
var speed_active := false

func _ready() -> void:
	state = SurvivorStateScript.new()
	player_system = PlayerScript.new()
	weapon_system = WeaponSystemScript.new()
	enemy_spawner = EnemySpawnerScript.new()
	pickup_system = PickupSystemScript.new()
	level_up_system = LevelUpSystemScript.new()
	chest_system = ChestSystemScript.new()
	field_system = CrystalFieldSystemScript.new()
	field_event_system = FieldEventSystemScript.new()
	balance_log_system = BalanceLogSystemScript.new()
	recall_drone_system = RecallDroneSystemScript.new()
	meta_system = MetaProgressionSystemScript.new()
	build_synergy_system = BuildSynergySystemScript.new()
	melee_rush_system = MeleeRushSystemScript.new()
	shock_stack_system = ShockStackSystemScript.new()
	field_drop_system = FieldDropSystemScript.new()
	field_gimmick_system = FieldGimmickSystemScript.new()
	ui_safe_area_system = UiSafeAreaSystemScript.new()
	field_drop_spawn_system = FieldDropSpawnSystemScript.new()
	field_help_system = FieldHelpSystemScript.new()
	goal_hint_system = GoalHintSystemScript.new()
	exploration_mastery_system = ExplorationMasterySystemScript.new()
	exploration_chain_system = ExplorationChainSystemScript.new()
	tooltip_system = TooltipSystemScript.new()
	ui_layout_fix_system = UiLayoutFixSystemScript.new()
	speed_hold_system = SpeedHoldSystemScript.new()
	notification_log_system = NotificationLogSystemScript.new()
	boss_alert_system = BossAlertSystemScript.new()
	equipment_hud_system = EquipmentHudSystemScript.new()
	state.start_new_run(0, initial_seed_text)
	var save_data = initial_save_data if not initial_save_data.is_empty() else SaveSystem.new().load_data()
	var settings: Dictionary = save_data.get("settings", {})
	speed_hold_system.configure(settings)
	notification_log_system.configure(settings)
	equipment_hud_system.configure(settings)
	state.effect_density = String(settings.get("effect_density", "normal"))
	meta_system.apply_to_state(state, initial_character_id, initial_blessing_id, save_data)
	state.auto_infinite_enabled = initial_auto_infinite_enabled
	state.auto_recall_drone_enabled = bool(save_data.get("settings", {}).get("auto_recall_drone", false))
	build_synergy_system.process(state, [])
	_build_ui()
	set_process(true)
	_refresh()

func _process(delta: float) -> void:
	notification_log_system.tick(delta)
	boss_alert_system.tick(delta)
	if state.game_over:
		speed_active = false
		return
	if state.paused:
		speed_active = false
		_refresh_pause_ui()
		return
	if state.level_up_pending:
		speed_active = false
		_refresh()
		return
	if state.chest_pending:
		speed_active = false
		state.chest_timer = maxf(0.0, state.chest_timer - delta)
		if state.chest_timer <= 0.0:
			state.chest_pending = false
		_tick_flashes(delta)
		_refresh()
		return
	var speed_blocked = state.paused or state.level_up_pending or state.chest_pending or state.rune_contract_pending or boss_alert_system.warning_timer > 0.0
	var time_scale = speed_hold_system.simulation_multiplier(speed_hold_system.is_pressed(), speed_blocked)
	speed_active = time_scale > 1.0
	var sim_delta = delta * time_scale
	state.elapsed_seconds += sim_delta
	state.camera_position = state.camera_position.lerp(state.player_position, minf(1.0, sim_delta * 6.0))
	var events: Array = []
	field_system.process(state, sim_delta, events)
	field_event_system.process(state, sim_delta, events)
	field_drop_spawn_system.process(state, sim_delta, events)
	build_synergy_system.process(state, events)
	melee_rush_system.process(state, sim_delta, events)
	shock_stack_system.process(state, sim_delta, events)
	player_system.process_input_movement(state, sim_delta)
	enemy_spawner.process(state, sim_delta, events)
	field_gimmick_system.process(state, sim_delta, events)
	weapon_system.process(state, sim_delta, events)
	pickup_system.process_gems(state, sim_delta, events)
	field_drop_system.process(state, sim_delta, events)
	chest_system.process_pickups(state, events, sim_delta)
	player_system.process_survival(state, sim_delta, events)
	field_help_system.process(state, events)
	goal_hint_system.process(state, events)
	exploration_mastery_system.process(state, events)
	exploration_chain_system.process(state, sim_delta, events)
	if state.auto_recall_drone_enabled and state.recall_drone_ready:
		recall_drone_system.activate(state, events)
	balance_log_system.process(state, sim_delta)
	_tick_flashes(sim_delta)
	_handle_events(events)
	if state.game_over and not pending_finish:
		_finish_game(events)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and not state.paused:
		_scan_field_target()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if state.paused:
			if event.keycode == KEY_ESCAPE:
				_toggle_pause()
			elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
				set_pause_tab(event.keycode - KEY_1)
			elif event.keycode == KEY_T:
				_show_title_confirm()
			elif event.keycode == KEY_I and pause_tab_index == 7:
				state.auto_infinite_enabled = not state.auto_infinite_enabled
				SaveSystem.new().update_settings({"auto_infinite": state.auto_infinite_enabled})
				_refresh_pause_ui()
			elif event.keycode == KEY_R and pause_tab_index == 7:
				state.auto_recall_drone_enabled = not state.auto_recall_drone_enabled
				SaveSystem.new().update_settings({"auto_recall_drone": state.auto_recall_drone_enabled})
				_refresh_pause_ui()
		elif state.level_up_pending:
			if event.keycode == KEY_1:
				_select_reward(0)
			elif event.keycode == KEY_2:
				_select_reward(1)
			elif event.keycode == KEY_3:
				_select_reward(2)
			elif event.keycode == KEY_ENTER:
				_select_reward(state.selected_reward_index)
		elif event.keycode == KEY_ESCAPE:
			_toggle_pause()
		elif event.keycode == KEY_H:
			message_label.text = "ジェムを吸ってLvを上げ、攻撃を強化しましょう"
		elif event.keycode == KEY_F:
			_scan_field_target()
		elif event.keycode == KEY_R:
			_activate_recall_drone()

func _build_ui() -> void:
	var requested_scale = float(SaveSystem.new().get_setting("ui_scale", 1.0))
	var viewport_size = get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	var ui_scale = ui_safe_area_system.ui_scale_for(viewport_size, requested_scale, state.ui_layout_defs)
	var safe_margin = float(state.ui_layout_defs.get("safe_margin", 24.0))
	var bg = ColorRect.new()
	bg.color = Color(0.020, 0.030, 0.052)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	arena_view = ArenaViewScript.new()
	arena_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(arena_view)
	arena_view.bind_state(state)

	low_hp_overlay = ColorRect.new()
	low_hp_overlay.color = Color(0.88, 0.04, 0.03, 0.0)
	low_hp_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	low_hp_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(low_hp_overlay)

	var top = VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = safe_margin
	top.offset_right = -safe_margin
	top.offset_top = float(state.ui_layout_defs.get("hud_top_margin", 18.0))
	top.offset_bottom = float(state.ui_layout_defs.get("hud_max_height", 118.0)) * ui_scale
	top.add_theme_constant_override("separation", 3)
	add_child(top)

	var hp_row = HBoxContainer.new()
	hp_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_theme_constant_override("separation", 10)
	top.add_child(hp_row)
	hp_label = Label.new()
	hp_label.custom_minimum_size.x = 170.0 * ui_scale
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hp_label.add_theme_font_size_override("font_size", int(20.0 * ui_scale))
	hp_label.add_theme_color_override("font_color", Color(0.98, 1.0, 0.92))
	hp_row.add_child(hp_label)

	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(0, 16.0 * ui_scale)
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_bar.min_value = 0
	hp_bar.show_percentage = false
	hp_row.add_child(hp_bar)

	hud_label = Label.new()
	hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hud_label.add_theme_font_size_override("font_size", int(17.0 * ui_scale))
	hud_label.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	top.add_child(hud_label)

	weapon_label = Label.new()
	weapon_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	weapon_label.offset_left = -316.0
	weapon_label.offset_right = -18.0
	weapon_label.offset_top = -226.0
	weapon_label.offset_bottom = -72.0
	weapon_label.add_theme_font_size_override("font_size", int(13.0 * ui_scale))
	weapon_label.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	add_child(weapon_label)

	passive_label = Label.new()
	passive_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	passive_label.offset_left = -610.0
	passive_label.offset_right = -328.0
	passive_label.offset_top = -226.0
	passive_label.offset_bottom = -72.0
	passive_label.add_theme_font_size_override("font_size", int(13.0 * ui_scale))
	passive_label.add_theme_color_override("font_color", Color(0.72, 1.0, 0.76))
	add_child(passive_label)

	combo_label = Label.new()
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	combo_label.add_theme_font_size_override("font_size", int(14.0 * ui_scale))
	combo_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.38))
	top.add_child(combo_label)

	exp_bar = ProgressBar.new()
	exp_bar.custom_minimum_size = Vector2(0, 10.0 * ui_scale)
	exp_bar.min_value = 0
	exp_bar.max_value = 100
	exp_bar.show_percentage = false
	top.add_child(exp_bar)

	var goal_panel = PanelContainer.new()
	goal_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	goal_panel.offset_left = -float(state.ui_layout_defs.get("goal_panel_width", 330.0)) - safe_margin
	goal_panel.offset_right = -safe_margin
	goal_panel.offset_top = 132.0 * ui_scale
	goal_panel.offset_bottom = 302.0 * ui_scale
	goal_panel.add_theme_stylebox_override("panel", _hud_panel_style(Color(0.42, 0.82, 1.0)))
	add_child(goal_panel)
	var goal_box = VBoxContainer.new()
	goal_box.add_theme_constant_override("separation", 4)
	goal_panel.add_child(goal_box)
	goal_label = Label.new()
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_label.custom_minimum_size.x = 285
	goal_label.add_theme_font_size_override("font_size", int(16.0 * ui_scale))
	goal_label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0))
	goal_box.add_child(goal_label)
	event_label = Label.new()
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_label.custom_minimum_size.x = 285
	event_label.add_theme_font_size_override("font_size", int(14.0 * ui_scale))
	event_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.36))
	goal_box.add_child(event_label)
	exploration_label = Label.new()
	exploration_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exploration_label.custom_minimum_size.x = 285
	exploration_label.add_theme_font_size_override("font_size", int(14.0 * ui_scale))
	exploration_label.add_theme_color_override("font_color", Color(0.52, 1.0, 0.72))
	goal_box.add_child(exploration_label)

	speed_label = Label.new()
	speed_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	speed_label.offset_top = 122.0
	speed_label.offset_bottom = 154.0
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed_label.add_theme_font_size_override("font_size", int(20.0 * ui_scale))
	speed_label.add_theme_color_override("font_color", Color(0.52, 1.0, 0.86))
	add_child(speed_label)

	boss_alert_label = Label.new()
	boss_alert_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_alert_label.offset_left = viewport_size.x * 0.24
	boss_alert_label.offset_right = -viewport_size.x * 0.24
	boss_alert_label.offset_top = 154.0
	boss_alert_label.offset_bottom = 196.0
	boss_alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_alert_label.add_theme_font_size_override("font_size", int(24.0 * ui_scale))
	boss_alert_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.24))
	add_child(boss_alert_label)

	boss_hp_label = Label.new()
	boss_hp_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_hp_label.offset_left = viewport_size.x * 0.28
	boss_hp_label.offset_right = -viewport_size.x * 0.28
	boss_hp_label.offset_top = 154.0
	boss_hp_label.offset_bottom = 180.0
	boss_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_hp_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.76))
	add_child(boss_hp_label)
	boss_hp_bar = ProgressBar.new()
	boss_hp_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_hp_bar.offset_left = viewport_size.x * 0.28
	boss_hp_bar.offset_right = -viewport_size.x * 0.28
	boss_hp_bar.offset_top = 181.0
	boss_hp_bar.offset_bottom = 197.0
	boss_hp_bar.show_percentage = false
	add_child(boss_hp_bar)

	notification_label = Label.new()
	notification_label.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	notification_label.offset_left = -390.0
	notification_label.offset_right = -safe_margin
	notification_label.offset_top = 318.0
	notification_label.offset_bottom = 494.0
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	notification_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notification_label.add_theme_font_size_override("font_size", int(14.0 * ui_scale))
	notification_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	add_child(notification_label)

	var help_panel = PanelContainer.new()
	help_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help_panel.offset_left = safe_margin
	help_panel.offset_right = safe_margin + float(state.ui_layout_defs.get("field_help_panel_width", 390.0))
	help_panel.offset_top = -190.0 * ui_scale
	help_panel.offset_bottom = -72.0 * ui_scale
	help_panel.add_theme_stylebox_override("panel", _hud_panel_style(Color(0.46, 1.0, 0.70)))
	add_child(help_panel)
	field_help_label = Label.new()
	field_help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	field_help_label.custom_minimum_size.x = 340
	field_help_label.add_theme_font_size_override("font_size", int(15.0 * ui_scale))
	field_help_label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0))
	help_panel.add_child(field_help_label)

	message_label = Label.new()
	message_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	message_label.offset_left = safe_margin * 3.0
	message_label.offset_right = -safe_margin * 3.0
	message_label.offset_top = -58.0 * ui_scale
	message_label.offset_bottom = -float(state.ui_layout_defs.get("message_bottom_margin", 22.0))
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", int(18.0 * ui_scale))
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.34))
	message_label.text = "移動 WASD/矢印　F/右クリック スキャン　R ドローン　Esc ポーズ"
	add_child(message_label)

	audio_manager = AudioManager.new()
	add_child(audio_manager)

	reward_popup = preload("res://scenes/RewardPopup.tscn").instantiate()
	reward_popup.set_anchors_preset(Control.PRESET_CENTER)
	reward_popup.offset_left = -minf(340.0, viewport_size.x * 0.42)
	reward_popup.offset_right = minf(340.0, viewport_size.x * 0.42)
	reward_popup.offset_top = -minf(220.0, viewport_size.y * 0.38)
	reward_popup.offset_bottom = minf(220.0, viewport_size.y * 0.38)
	add_child(reward_popup)
	reward_popup.reward_chosen.connect(_on_reward_chosen)
	_build_pause_ui()

func _handle_events(events: Array) -> void:
	for event in events:
		notification_log_system.ingest(event, state.elapsed_seconds)
		boss_alert_system.ingest(event)
		match String(event.get("type", "")):
			"attack":
				audio_manager.play_sfx("attack")
			"enemy_attack_warning":
				audio_manager.play_sfx("attack")
			"enemy_die":
				audio_manager.play_sfx("enemy_die")
			"gem_collect":
				audio_manager.play_sfx("gem")
			"level_up":
				audio_manager.play_sfx("levelup")
				message_label.text = "レベルアップ！強化を選択"
			"auto_infinite":
				audio_manager.play_sfx("reward_select")
				message_label.text = "%s" % String(event.get("name", "無限強化"))
			"overclock":
				audio_manager.play_sfx("evolution")
				message_label.text = "%s 過充電！" % String(event.get("name", "過充電"))
			"rune_contract_offer":
				audio_manager.play_sfx("levelup")
				message_label.text = "ルーン契約を選べます"
			"rune_contract_apply":
				audio_manager.play_sfx("reward_select")
				message_label.text = "%sを結んだ" % String(event.get("name", "契約"))
			"rune_contract_skip":
				message_label.text = "契約を見送りました"
			"reward_select":
				audio_manager.play_sfx("reward_select")
			"chest_drop":
				audio_manager.play_sfx("chest")
			"chest_open":
				audio_manager.play_sfx("chest")
				message_label.text = String(event.get("message", "宝箱！"))
			"evolution":
				audio_manager.play_sfx("evolution")
				message_label.text = "%sへ進化！" % String(event.get("name", "進化武器"))
			"player_damage":
				audio_manager.play_sfx("damage")
			"player_heal":
				message_label.text = "HP回復"
			"gem_fever":
				audio_manager.play_sfx("levelup")
				message_label.text = "ジェムフィーバー！"
			"combo_milestone":
				message_label.text = String(event.get("message", "吸収コンボ！"))
			"crystal_break":
				message_label.text = "クリスタル破壊！"
			"crystal_overdrive":
				audio_manager.play_sfx("evolution")
				message_label.text = "クリスタルオーバードライブ！"
			"boss_warning":
				message_label.text = String(event.get("message", "ボス接近！"))
			"boss_spawn":
				message_label.text = "%s 出現！" % String(event.get("name", "ボス"))
			"boss_enrage":
				message_label.text = "生存中のボスが強化！"
			"field_event_start":
				audio_manager.play_sfx("levelup")
				message_label.text = "イベント発生：%s　%s　残り%.0f秒" % [
					String(event.get("name", "イベント")),
					String(state.active_field_event.get("objective_ja", "目標を達成")),
					float(event.get("duration", 0.0))
				]
			"field_event_end":
				message_label.text = "イベント%s：%s" % ["成功" if bool(event.get("success", false)) else "終了", String(event.get("name", "イベント"))]
			"field_event_success":
				audio_manager.play_sfx("reward_select")
				message_label.text = "イベント成功：%s" % String(event.get("name", "イベント"))
			"field_event_failed":
				message_label.text = "イベント終了：%sの目標は未達成" % String(event.get("name", "イベント"))
			"recall_drone_ready":
				message_label.text = "回収ドローン READY [R]"
			"recall_drone":
				audio_manager.play_sfx("gem")
				message_label.text = "回収ドローン発動！"
			"best_score":
				audio_manager.play_sfx("bestscore")
			"build_synergy":
				audio_manager.play_sfx("evolution")
				message_label.text = "ビルド完成：%s" % String(event.get("name", "相性"))
			"melee_rush":
				audio_manager.play_sfx("levelup")
				message_label.text = "近接ラッシュ Lv%d！" % int(event.get("level", 1))
			"shock_explosion":
				message_label.text = "感電爆発！"
			"field_drop_pickup":
				audio_manager.play_sfx("reward_select")
				message_label.text = String(event.get("message", "フィールド報酬"))
			"dynamic_drop_spawn":
				audio_manager.play_sfx("levelup")
				message_label.text = "遠方に%sが出現！ 距離%dm　矢印を追って回収" % [
					String(event.get("name", "フィールド報酬")),
					int(round(float(event.get("distance", 0.0)) / 10.0))
				]
			"dynamic_drop_expired":
				message_label.text = "%sは消滅しました" % String(event.get("name", "フィールド報酬"))
			"field_discovery":
				SaveSystem.new().mark_field_discovered(String(event.get("kind", "")), String(event.get("id", "")))
				audio_manager.play_sfx("reward_select")
				message_label.text = "新発見：%s　Fで詳しくスキャン" % String(event.get("name", "フィールド対象"))
			"goal_changed":
				state.goal_change_timer = 3.0
			"exploration_chain":
				var effect = String(event.get("message", ""))
				message_label.text = "探索チェーン x%d%s" % [int(event.get("chain", 1)), "　%s！" % effect if effect != "" else ""]
			"exploration_score":
				pass
			"gimmick_reflect":
				message_label.text = "反射水晶！"
			"gimmick_explosion":
				audio_manager.play_sfx("chest")
				message_label.text = "爆薬鉱脈が爆発！"
			"gimmick_heal":
				message_label.text = "回復泉"
			"gimmick_spawn":
				message_label.text = "召喚裂け目から敵出現"
			"gimmick_open":
				audio_manager.play_sfx("chest")
				message_label.text = "封印宝箱柱が開いた"

func _refresh() -> void:
	var exp_percent = int(round(100.0 * clampf(float(state.exp) / float(maxi(state.exp_to_next, 1)), 0.0, 1.0)))
	hp_label.text = "HP %d / %d" % [maxi(state.hp, 0), state.max_hp]
	hp_bar.max_value = state.max_hp
	hp_bar.value = clampi(state.hp, 0, state.max_hp)
	_update_hp_bar_style()
	hud_label.text = "Lv %d　EXP %d%%　時間 %s　撃破 %s" % [
		state.level,
		exp_percent,
		JaText.format_time(state.elapsed_seconds),
		JaText.format_int(state.kills)
	]
	weapon_label.text = equipment_hud_system.weapon_text(state)
	passive_label.text = equipment_hud_system.passive_text(state)
	speed_label.text = speed_hold_system.display_text(speed_active)
	notification_label.text = notification_log_system.visible_text()
	boss_alert_label.text = boss_alert_system.warning_text if boss_alert_system.warning_timer > 0.0 else ""
	var boss_snapshot = boss_alert_system.active_boss_snapshot(state)
	boss_hp_label.visible = not boss_snapshot.is_empty()
	boss_hp_bar.visible = not boss_snapshot.is_empty()
	if not boss_snapshot.is_empty():
		boss_hp_label.text = "%s  %d / %d" % [String(boss_snapshot.get("name", "ボス")), int(boss_snapshot.get("hp", 0)), int(boss_snapshot.get("max_hp", 1))]
		boss_hp_bar.max_value = int(boss_snapshot.get("max_hp", 1))
		boss_hp_bar.value = int(boss_snapshot.get("hp", 0))
	if state.pickup_combo_count > 0:
		combo_label.text = "吸収コンボ %d　最大 %d　現在地：%s" % [state.pickup_combo_count, state.max_combo, state.current_terrain_name]
	else:
		combo_label.text = "最大コンボ %d　現在地：%s" % [state.max_combo, state.current_terrain_name]
	if state.boss_warning_timer > 0.0:
		message_label.text = state.boss_warning_text
	if state.chest_pending:
		message_label.text = state.chest_message
	elif state.chest_notice_timer > 0.0:
		message_label.text = state.chest_message
	if state.gem_fever_timer > 0.0:
		combo_label.text += "　FEVER %.1fs" % state.gem_fever_timer
	if state.crystal_overdrive_timer > 0.0:
		combo_label.text += "　OD %.1fs" % state.crystal_overdrive_timer
	if state.recall_drone_ready:
		combo_label.text += "　回収ドローン READY [R]"
	else:
		var charge = int(round(100.0 * state.recall_drone_meter / float(state.balance_data.get("recall_drone_charge_seconds", 180.0))))
		combo_label.text += "　ドローン %d%%" % clampi(charge, 0, 100)
	if state.melee_rush_timer > 0.0:
		combo_label.text += "　近接ラッシュLv%d %.0fs" % [state.melee_rush_level, state.melee_rush_timer]
	if not state.active_synergies.is_empty():
		combo_label.text += "　%s" % state.active_synergy_label()
	exp_bar.value = exp_percent
	_refresh_goal_hud()
	_refresh_field_help_hud()
	_refresh_low_hp_overlay()
	if state.level_up_pending:
		reward_popup.show_options(state.level_up_options)
	else:
		reward_popup.hide_popup()
	arena_view.queue_redraw()

func _refresh_goal_hud() -> void:
	if goal_label == null:
		return
	if state.current_goals.is_empty():
		goal_label.text = "次の目標\nジェムを回収してLvを上げる"
	else:
		var main: Dictionary = state.current_goals[0]
		var distance = int(round(float(main.get("distance", 0.0)) / 10.0))
		var lines: Array = [
			"次の目標",
			String(main.get("title", "周辺を探索")),
			"理由：%s" % String(main.get("reason", "")),
			"距離：%dm" % distance if distance > 0 else "現在地点"
		]
		for i in range(1, mini(3, state.current_goals.size())):
			lines.append("副：%s" % String(state.current_goals[i].get("title", "")))
		goal_label.text = "\n".join(lines)
	if not state.active_field_event.is_empty():
		event_label.text = "イベント：%s　残り%.0f秒\n目標：%s" % [
			String(state.active_field_event.get("name_ja", "イベント")),
			state.field_event_timer,
			String(state.active_field_event.get("objective_ja", "生存"))
		]
	else:
		event_label.text = "次イベント：%s" % ("未定" if state.next_field_event_time <= 0.0 else JaText.format_time(maxf(0.0, state.next_field_event_time - state.elapsed_seconds)))
	exploration_label.text = "探索ランク %s　スコア %d\n探索チェーン x%d　残り%.0f秒" % [
		state.exploration_rank,
		state.exploration_score,
		state.exploration_chain,
		state.exploration_chain_timer
	]

func _refresh_field_help_hud() -> void:
	if field_help_label == null:
		return
	var target: Dictionary = state.scanned_field_help if state.field_scan_timer > 0.0 and not state.scanned_field_help.is_empty() else state.nearby_field_help
	if target.is_empty():
		field_help_label.text = "現在地：%s\n%s\nF / 右クリックで周辺をスキャン" % [state.current_terrain_name, state.current_terrain_guide()]
		return
	field_help_label.text = "現在地：%s\n%s\n\n%s" % [state.current_terrain_name, state.current_terrain_guide(), tooltip_system.format_field_help(target, state.field_scan_timer > 0.0)]

func _refresh_low_hp_overlay() -> void:
	if low_hp_overlay == null:
		return
	var ratio = state.hp_ratio()
	if ratio <= 0.10:
		var alpha = 0.10 + 0.08 * (0.5 + 0.5 * sin(state.elapsed_seconds * 6.0))
		low_hp_overlay.color = Color(0.90, 0.03, 0.02, alpha)
	else:
		low_hp_overlay.color = Color(0.90, 0.03, 0.02, 0.0)

func _select_reward(index: int) -> void:
	if not state.level_up_pending or index < 0 or index >= state.level_up_options.size():
		return
	var uid = String(state.level_up_options[index].get("uid", ""))
	_on_reward_chosen(uid)

func _on_reward_chosen(reward_id: String) -> void:
	var events: Array = []
	if level_up_system.apply_option(state, reward_id, events):
		_handle_events(events)
		_refresh()

func _tick_flashes(delta: float) -> void:
	state.field_scan_timer = maxf(0.0, state.field_scan_timer - delta)
	state.goal_change_timer = maxf(0.0, state.goal_change_timer - delta)
	for flash in state.hit_flashes.duplicate():
		flash["life"] = float(flash.get("life", 0.0)) - delta
		if float(flash.get("life", 0.0)) <= 0.0:
			state.hit_flashes.erase(flash)
	for line in state.effect_lines.duplicate():
		line["life"] = float(line.get("life", 0.0)) - delta
		if float(line.get("life", 0.0)) <= 0.0:
			state.effect_lines.erase(line)
	for text_data in state.floating_texts.duplicate():
		text_data["life"] = float(text_data.get("life", 0.0)) - delta
		if float(text_data.get("life", 0.0)) <= 0.0:
			state.floating_texts.erase(text_data)

func _finish_game(events: Array) -> void:
	pending_finish = true
	state.update_best_score(events)
	balance_log_system.flush(state)
	_handle_events(events)
	audio_manager.play_sfx("gameover")
	game_finished.emit(_summary())

func _summary() -> Dictionary:
	var best: int = maxi(state.best_score, state.score)
	return {
		"score": state.score,
		"map_seed": state.map_seed,
		"map_seed_text": state.map_seed_text,
		"character_id": state.selected_character_id,
		"character_name": state.selected_character_name,
		"blessing_id": state.selected_blessing_id,
		"best_score": best,
		"best_delta": maxi(best - state.score, 0),
		"survival_time": state.elapsed_seconds,
		"kills": state.kills,
		"level": state.level,
		"max_weapon": state.max_weapon_label(),
		"evolved_weapon_count": state.evolved_weapon_count,
		"gems_collected": state.gems_collected,
		"gem_exp_collected": state.gem_exp_collected,
		"max_combo": state.max_combo,
		"crystals_destroyed": state.crystals_destroyed,
		"chests_opened": state.chests_opened,
		"max_damage": state.max_damage,
		"danger_time": state.danger_time,
		"low_hp_survival_time": state.low_hp_survival_time,
		"overdrive_count": state.overdrive_count,
		"auto_infinite_count": state.auto_infinite_count,
		"overclock_count": _total_overclocks(),
		"rune_contracts": state.rune_contracts,
		"recall_drone_activations": state.recall_drone_activations,
		"field_event_count": state.field_event_count,
		"boss_defeats": state.boss_defeated_ids.size(),
		"boss_defeated_ids": state.boss_defeated_ids,
		"weapon_levels": state.weapons.duplicate(true),
		"evolved_weapon_ids": state.evolved_weapons.keys(),
		"enemy_seen": state.enemy_seen,
		"weapon_kill_counts": state.weapon_kill_counts,
		"active_synergies": state.active_synergies.keys(),
		"synergy_history": state.active_synergy_history,
		"melee_rush_kills": state.melee_rush_kills,
		"shock_explosions": state.shock_explosions,
		"field_drops_collected": state.field_drops_collected,
		"field_gimmicks_triggered": state.field_gimmicks_triggered,
		"dynamic_drops_spawned": state.dynamic_drops_spawned,
		"exploration_score": state.exploration_score,
		"exploration_rank": state.exploration_rank,
		"exploration_currency_bonus": state.exploration_currency_bonus,
		"exploration_far_pickups": state.exploration_far_pickups,
		"exploration_danger_pickups": state.exploration_danger_pickups,
		"exploration_chain_max": state.exploration_chain_max,
		"exploration_chain_currency_bonus": state.exploration_chain_currency_bonus,
		"field_event_successes": state.field_event_successes,
		"field_event_failures": state.field_event_failures,
		"rooms_discovered": state.rooms_discovered,
		"terrain_time": state.terrain_time.duplicate(true),
		"terrain_kills": state.terrain_kills.duplicate(true),
		"terrain_crystals": state.terrain_crystals.duplicate(true),
		"shortcut_walls_broken": state.shortcut_walls_broken,
		"oasis_healing": state.oasis_healing,
		"cursed_relics": state.cursed_relic_count,
		"title_badges": state.title_badges,
		"reason": state.game_over_reason,
		"best_updated": state.best_score_updated
	}

func _activate_recall_drone() -> void:
	if state == null or not state.recall_drone_ready or state.game_over or state.level_up_pending or state.chest_pending:
		return
	var events: Array = []
	if recall_drone_system.activate(state, events):
		_handle_events(events)

func _scan_field_target() -> void:
	if state == null or state.game_over or state.level_up_pending:
		return
	var target = field_help_system.scan(state)
	if target.is_empty():
		message_label.text = "スキャン：近くに調査対象はありません"
	else:
		message_label.text = "スキャン完了：%s" % String(target.get("name_ja", "フィールド対象"))

func _total_overclocks() -> int:
	var total = 0
	for weapon_id in state.overclocks.keys():
		total += (state.overclocks[weapon_id] as Array).size()
	return total

func _update_hp_bar_style() -> void:
	var ratio = state.hp_ratio()
	var fill = StyleBoxFlat.new()
	if ratio < 0.25:
		fill.bg_color = Color(1.0, 0.14, 0.10)
		hp_label.add_theme_color_override("font_color", Color(1.0, 0.36, 0.30))
	elif ratio < 0.50:
		fill.bg_color = Color(1.0, 0.82, 0.18)
		hp_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.34))
	else:
		fill.bg_color = Color(0.30, 0.95, 0.42)
		hp_label.add_theme_color_override("font_color", Color(0.90, 1.0, 0.92))
	fill.set_corner_radius_all(4)
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.05, 0.07, 0.94)
	bg.border_color = Color(0.88, 0.96, 1.0, 0.45)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(4)
	hp_bar.add_theme_stylebox_override("fill", fill)
	hp_bar.add_theme_stylebox_override("background", bg)

func _hud_panel_style(accent: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.038, 0.058, 0.90)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style

func _build_pause_ui() -> void:
	var safe_margin = float(state.ui_layout_defs.get("safe_margin", 24.0))
	pause_overlay = PanelContainer.new()
	pause_overlay.visible = false
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.offset_left = safe_margin * 2.0
	pause_overlay.offset_right = -safe_margin * 2.0
	pause_overlay.offset_top = safe_margin * 1.6
	pause_overlay.offset_bottom = -safe_margin * 1.6
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.055, 0.075, 0.97)
	style.border_color = Color(0.46, 0.75, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	pause_overlay.add_theme_stylebox_override("panel", style)
	add_child(pause_overlay)
	var root = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	pause_overlay.add_child(root)
	pause_title_label = Label.new()
	pause_title_label.text = "ポーズ"
	pause_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	pause_title_label.custom_minimum_size.x = 700
	pause_title_label.add_theme_font_size_override("font_size", 30)
	pause_title_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	root.add_child(pause_title_label)
	var body = HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)
	var tabs = VBoxContainer.new()
	tabs.custom_minimum_size.x = float(state.ui_layout_defs.get("pause_tab_width", 178.0))
	tabs.add_theme_constant_override("separation", 6)
	body.add_child(tabs)
	pause_tab_buttons = []
	for i in range(pause_tabs.size()):
		var button = CrystalButtonScript.new()
		button.setup("%d  %s" % [i + 1, pause_tabs[i]], Color(0.42, 0.82, 1.0), Vector2(float(state.ui_layout_defs.get("pause_tab_width", 178.0)), 42))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var index = i
		button.pressed.connect(func(): set_pause_tab(index))
		tabs.add_child(button)
		pause_tab_buttons.append(button)
	var scroll = ScrollContainer.new()
	ui_layout_fix_system.prepare_scroll(scroll)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	pause_content = Label.new()
	pause_content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pause_content.custom_minimum_size.x = float(state.ui_layout_defs.get("pause_content_min_width", 520.0))
	pause_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_content.add_theme_font_size_override("font_size", 18)
	pause_content.add_theme_color_override("font_color", Color(0.86, 0.92, 0.98))
	scroll.add_child(pause_content)
	var summary_panel = PanelContainer.new()
	summary_panel.custom_minimum_size.x = float(state.ui_layout_defs.get("pause_summary_width", 286.0))
	summary_panel.add_theme_stylebox_override("panel", _hud_panel_style(Color(1.0, 0.82, 0.34)))
	body.add_child(summary_panel)
	pause_summary = Label.new()
	pause_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pause_summary.custom_minimum_size.x = float(state.ui_layout_defs.get("pause_summary_width", 286.0)) - 24.0
	pause_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_summary.add_theme_font_size_override("font_size", 16)
	pause_summary.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	summary_panel.add_child(pause_summary)
	pause_action_row = HBoxContainer.new()
	pause_action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	pause_action_row.add_theme_constant_override("separation", 10)
	root.add_child(pause_action_row)
	pause_confirm_dialog = ConfirmDialogScript.new()
	pause_confirm_dialog.visible = false
	pause_confirm_dialog.set_anchors_preset(Control.PRESET_CENTER)
	pause_confirm_dialog.offset_left = -250
	pause_confirm_dialog.offset_right = 250
	pause_confirm_dialog.offset_top = -120
	pause_confirm_dialog.offset_bottom = 120
	pause_confirm_dialog.setup("タイトルへ戻りますか？", "現在のランは終了します。誤操作防止のため確認してください。", "タイトルへ", "キャンセル")
	pause_confirm_dialog.confirmed.connect(func(): title_requested.emit())
	pause_confirm_dialog.canceled.connect(func(): pause_confirm_dialog.hide())
	add_child(pause_confirm_dialog)

func _toggle_pause() -> void:
	state.paused = not state.paused
	pause_overlay.visible = state.paused
	if pause_confirm_dialog != null:
		pause_confirm_dialog.hide()
	if state.paused:
		_refresh_pause_ui()
	else:
		message_label.text = "移動 WASD/矢印　F/右クリック スキャン　R ドローン　Esc ポーズ"

func set_pause_tab(index: int) -> void:
	pause_tab_index = clampi(index, 0, pause_tabs.size() - 1)
	_refresh_pause_ui()

func pause_tab_text() -> String:
	match pause_tab_index:
		0:
			return _pause_status_text()
		1:
			return _pause_weapons_text()
		2:
			return _pause_passives_text()
		3:
			return _pause_evolution_text()
		4:
			return _pause_build_text()
		5:
			return _pause_field_help_text()
		6:
			return _pause_contract_text()
		7:
			return _pause_settings_text()
		8:
			return notification_log_system.history_text()
	return ""

func _refresh_pause_ui() -> void:
	if pause_content == null:
		return
	pause_content.text = "%s\n\n%s" % [pause_tabs[pause_tab_index], pause_tab_text()]
	pause_title_label.text = "ポーズ　%s　%s" % [JaText.format_time(state.elapsed_seconds), state.selected_character_name]
	pause_summary.text = _pause_summary_text()
	for i in range(pause_tab_buttons.size()):
		var button: Button = pause_tab_buttons[i]
		button.setup("%d  %s" % [i + 1, pause_tabs[i]], Color(1.0, 0.82, 0.34) if i == pause_tab_index else Color(0.42, 0.82, 1.0), Vector2(float(state.ui_layout_defs.get("pause_tab_width", 178.0)), 42))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_refresh_pause_actions()

func _refresh_pause_actions() -> void:
	if pause_action_row == null:
		return
	for child in pause_action_row.get_children():
		child.queue_free()
	if pause_tab_index == 7:
		var auto_button = CrystalButtonScript.new()
		auto_button.setup("無限強化 %s" % ("ON" if state.auto_infinite_enabled else "OFF"), Color(0.52, 1.0, 0.72), Vector2(180, 42))
		auto_button.pressed.connect(func():
			state.auto_infinite_enabled = not state.auto_infinite_enabled
			SaveSystem.new().update_settings({"auto_infinite": state.auto_infinite_enabled})
			_refresh_pause_ui()
		)
		pause_action_row.add_child(auto_button)
		var recall_button = CrystalButtonScript.new()
		recall_button.setup("自動ドローン %s" % ("ON" if state.auto_recall_drone_enabled else "OFF"), Color(0.52, 1.0, 0.72), Vector2(180, 42))
		recall_button.pressed.connect(func():
			state.auto_recall_drone_enabled = not state.auto_recall_drone_enabled
			SaveSystem.new().update_settings({"auto_recall_drone": state.auto_recall_drone_enabled})
			_refresh_pause_ui()
		)
		pause_action_row.add_child(recall_button)
	var settings_button = CrystalButtonScript.new()
	settings_button.setup("設定", Color(0.52, 1.0, 0.72), Vector2(130, 42))
	settings_button.pressed.connect(func(): set_pause_tab(7))
	pause_action_row.add_child(settings_button)
	var title_button = CrystalButtonScript.new()
	title_button.setup("タイトルへ戻る", Color(1.0, 0.34, 0.42), Vector2(180, 42), true)
	title_button.pressed.connect(_show_title_confirm)
	pause_action_row.add_child(title_button)
	var resume_button = CrystalButtonScript.new()
	resume_button.setup("ゲームへ戻る", Color(0.42, 0.82, 1.0), Vector2(170, 42))
	resume_button.pressed.connect(_toggle_pause)
	pause_action_row.add_child(resume_button)

func _show_title_confirm() -> void:
	if pause_confirm_dialog != null:
		pause_confirm_dialog.show()

func _pause_status_text() -> String:
	return "\n".join([
		"キャラ：%s" % state.selected_character_name,
		"HP：%d / %d　Lv：%d　EXP：%d%%" % [state.hp, state.max_hp, state.level, int(exp_bar.value)],
		"生存時間：%s　撃破：%s　スコア：%s" % [JaText.format_time(state.elapsed_seconds), JaText.format_int(state.kills), JaText.format_int(state.score)],
		"攻撃倍率：%.2f　CD倍率：%.2f　範囲倍率：%.2f　移動速度：%.1f　吸収範囲：%.1f" % [state.get_damage_multiplier(), state.get_cooldown_multiplier(), state.get_area_multiplier(), state.get_move_speed(), state.get_magnet_radius()],
		"ジェム価値：%.2f　スコア倍率：%.2f　現在バイオーム：%s" % [state.get_gem_value_multiplier(), state.get_score_multiplier(), state.current_biome_name],
		"イベント：%s　契約数：%d　進化武器：%d" % [String(state.active_field_event.get("name_ja", "なし")), state.rune_contracts.size(), state.evolved_weapon_count],
		state.active_synergy_label(),
		"探索：ランク%s / %d点 / 最大チェーンx%d" % [state.exploration_rank, state.exploration_score, state.exploration_chain_max],
		"発見：ドロップ%d　ギミック%d　動的出現%d" % [state.field_drops_collected, state.field_gimmicks_triggered, state.dynamic_drops_spawned]
	])

func _pause_weapons_text() -> String:
	var lines: Array = []
	for id in state.weapons.keys():
		var weapon_id = String(id)
		var level = int(state.weapons[id])
		var evo = state.evolution_for_weapon(weapon_id)
		lines.append("%s Lv%d" % [state.weapon_name(weapon_id), level])
		lines.append("タグ：%s" % ", ".join(state.weapon_tags(weapon_id)))
		lines.append("現在：%s" % _weapon_effect_text(weapon_id, level))
		lines.append("次Lv：%s" % _weapon_effect_text(weapon_id, mini(level + 1, int(state.weapon_defs[weapon_id].get("max_level", 8)))))
		if not evo.is_empty():
			lines.append("進化：%s / 条件：%s Lv%d + %s Lv%d + 宝箱" % [String(evo.get("name_ja", "")), state.weapon_name(weapon_id), int(evo.get("weapon_level", 8)), state.passive_name(String(evo.get("passive", ""))), int(evo.get("passive_level", 1))])
			lines.append("状態：%s" % _evolution_status_text(weapon_id))
		lines.append("過充電：%s" % _overclock_label(weapon_id))
		lines.append("")
	if lines.is_empty():
		lines.append("武器なし")
	return "\n".join(lines)

func _pause_passives_text() -> String:
	var lines: Array = []
	for id in state.passives.keys():
		var passive_id = String(id)
		var level = int(state.passives[id])
		lines.append("%s Lv%d / %s" % [state.passive_name(passive_id), level, String(state.passive_defs[passive_id].get("description_ja", ""))])
		var related: Array = []
		for evo_id in state.evolution_defs.keys():
			if String(state.evolution_defs[evo_id].get("passive", "")) == passive_id:
				related.append(String(state.evolution_defs[evo_id].get("name_ja", evo_id)))
		lines.append("関連進化：%s / %s" % [", ".join(related) if not related.is_empty() else "なし", "最大Lv" if level >= int(state.passive_defs[passive_id].get("max_level", 5)) else "強化可能"])
	if lines.is_empty():
		lines.append("パッシブなし")
	return "\n".join(lines)

func _pause_evolution_text() -> String:
	var lines: Array = []
	for weapon_id in state.weapons.keys():
		var id = String(weapon_id)
		var evo = state.evolution_for_weapon(id)
		if evo.is_empty():
			continue
		var passive_id = String(evo.get("passive", ""))
		lines.append("%s → %s" % [state.weapon_name(id), String(evo.get("name_ja", ""))])
		lines.append("必要：%s Lv%d / %s Lv%d / 宝箱" % [state.weapon_name(id), int(evo.get("weapon_level", 8)), state.passive_name(passive_id), int(evo.get("passive_level", 1))])
		lines.append("現在：%s Lv%d / %s Lv%d" % [state.weapon_name(id), int(state.weapons.get(id, 0)), state.passive_name(passive_id), int(state.passives.get(passive_id, 0))])
		lines.append("状態：%s" % _evolution_status_text(id))
		lines.append("不足：%s" % _evolution_shortage_text(id))
		lines.append("")
	if lines.is_empty():
		lines.append("所持武器に進化条件はまだありません")
	return "\n".join(lines)

func _pause_build_text() -> String:
	var lines: Array = ["発動中のビルド相性："]
	if state.active_synergies.is_empty():
		lines.append("なし。武器とパッシブのタグを揃えると発動します。")
	else:
		for raw_id in state.active_synergies.keys():
			var id = String(raw_id)
			var data: Dictionary = state.active_synergies[id]
			lines.append("%s\n%s" % [String(data.get("name_ja", id)), String(data.get("description_ja", ""))])
	lines.append("")
	lines.append("現在のタグ：")
	for tag in state.build_tag_counts.keys():
		lines.append("%s x%d" % [String(tag), int(state.build_tag_counts[tag])])
	lines.append("")
	lines.append("レベルアップ候補の「ビルド完成」表示を優先すると相性を完成できます。")
	return "\n".join(lines)

func _pause_field_help_text() -> String:
	var lines: Array = [
		"地形ガイド",
		state.current_terrain_guide(),
		"探索済み部屋：%d / %d" % [state.explored_room_ids.size(), state.map_data.get("rooms", []).size()],
		""
	]
	for terrain_id in state.terrain_type_defs.keys():
		var terrain: Dictionary = state.terrain_type_defs[terrain_id]
		lines.append("%s：%s" % [String(terrain.get("name_ja", terrain_id)), String(terrain.get("description_ja", ""))])
	lines.append_array([
		"",
		"フィールド対象へ近づくと左下に短い説明が出ます。",
		"Fキーまたは右クリックで、効果・対処・報酬・危険度をスキャンできます。",
		"初回発見はセーブされ、図鑑のドロップ/ギミック/イベントへ記録されます。",
		""
	])
	for section in ["drops", "gimmicks"]:
		lines.append("ドロップ：" if section == "drops" else "ギミック：")
		for raw_id in state.field_help_defs.get(section, {}).keys():
			var id = String(raw_id)
			var key = "%s:%s" % ["drop" if section == "drops" else "gimmick", id]
			var entry: Dictionary = state.field_help_defs[section][id]
			lines.append("%s %s - %s" % [
				"発見済み" if bool(state.field_help_discovered.get(key, false)) else "未発見",
				String(entry.get("name_ja", "？？？")) if bool(state.field_help_discovered.get(key, false)) else "？？？",
				String(entry.get("effect_ja", "")) if bool(state.field_help_discovered.get(key, false)) else "近づくと記録"
			])
		lines.append("")
	return "\n".join(lines)

func _pause_contract_text() -> String:
	var lines: Array = ["ルーン契約："]
	if state.rune_contracts.is_empty():
		lines.append("なし")
	else:
		for id in state.rune_contracts:
			var data = state.rune_contract_defs.get(String(id), {})
			lines.append("%s：%s" % [String(data.get("name_ja", id)), String(data.get("description_ja", ""))])
	lines.append("")
	lines.append("オーバークロック：")
	if state.overclocks.is_empty():
		lines.append("なし")
	else:
		for weapon_id in state.overclocks.keys():
			lines.append("%s：%s" % [state.weapon_name(String(weapon_id)), ", ".join(state.overclocks[weapon_id])])
	lines.append("現在のスコア倍率：%.2f" % state.get_score_multiplier())
	return "\n".join(lines)

func _pause_settings_text() -> String:
	var settings: Dictionary = SaveSystem.new().load_data().get("settings", {})
	return "\n".join([
		"I：無限強化だけ自動選択 %s" % ("ON" if state.auto_infinite_enabled else "OFF"),
		"R：自動回収ドローン %s" % ("ON" if state.auto_recall_drone_enabled else "OFF"),
		"長押し倍速：%s / %s / x%.1f" % ["ON" if bool(settings.get("speed_hold_enabled", true)) else "OFF", String(settings.get("speed_hold_key", "left_shift")), float(settings.get("speed_multiplier", 2.0))],
		"通知ログ：%s　武器HUD：%s　パッシブHUD：%s" % ["ON" if bool(settings.get("notification_log_enabled", true)) else "OFF", "ON" if bool(settings.get("weapon_hud_enabled", true)) else "OFF", "ON" if bool(settings.get("passive_hud_enabled", true)) else "OFF"],
		"詳細設定はタイトル画面の設定で変更できます。",
		"Esc：ゲームへ戻る"
	])

func _pause_summary_text() -> String:
	var evolution_ready = 0
	for weapon_id in state.weapons.keys():
		if _evolution_status_text(String(weapon_id)) == "宝箱で進化可能":
			evolution_ready += 1
	var goal_text = "ジェムを回収"
	var goal_reason = "序盤の強化"
	if not state.current_goals.is_empty():
		goal_text = String(state.current_goals[0].get("title", goal_text))
		goal_reason = String(state.current_goals[0].get("reason", goal_reason))
	return "\n".join([
		"現在の重要情報",
		"",
		"HP %d / %d" % [state.hp, state.max_hp],
		"生存 %s" % JaText.format_time(state.elapsed_seconds),
		"ビルド：%s" % state.active_synergy_label(),
		"進化可能：%d武器" % evolution_ready,
		"",
		"おすすめ目標",
		goal_text,
		"理由：%s" % goal_reason,
		"",
		"イベント：%s" % String(state.active_field_event.get("name_ja", "なし")),
		"探索：%s / %d点" % [state.exploration_rank, state.exploration_score]
	])

func _weapon_effect_text(weapon_id: String, level: int) -> String:
	if level >= int(state.weapon_defs[weapon_id].get("max_level", 8)):
		return "最大Lv。宝箱で進化条件を確認"
	if level >= 7:
		return "威力、範囲、特殊効果が大きく伸びる"
	if level >= 4:
		return "弾数/範囲/回転率が伸びる"
	return "基礎性能が伸びる"

func _evolution_status_text(weapon_id: String) -> String:
	if state.is_weapon_evolved(weapon_id):
		return "進化済み"
	var evo = state.evolution_for_weapon(weapon_id)
	if evo.is_empty():
		return "進化なし"
	var passive_id = String(evo.get("passive", ""))
	var missing: Array = []
	if int(state.weapons.get(weapon_id, 0)) < int(evo.get("weapon_level", 8)):
		missing.append("武器Lv不足")
	if int(state.passives.get(passive_id, 0)) < int(evo.get("passive_level", 1)):
		missing.append("素材不足")
	if missing.is_empty():
		return "宝箱で進化可能"
	return "条件不足：" + " / ".join(missing)

func _evolution_shortage_text(weapon_id: String) -> String:
	if state.is_weapon_evolved(weapon_id):
		return "なし（進化済み）"
	var evo = state.evolution_for_weapon(weapon_id)
	if evo.is_empty():
		return "進化なし"
	var parts: Array = []
	var weapon_need = maxi(0, int(evo.get("weapon_level", 8)) - int(state.weapons.get(weapon_id, 0)))
	var passive_id = String(evo.get("passive", ""))
	var passive_need = maxi(0, int(evo.get("passive_level", 1)) - int(state.passives.get(passive_id, 0)))
	if weapon_need > 0:
		parts.append("%s +%dLv" % [state.weapon_name(weapon_id), weapon_need])
	if passive_need > 0:
		parts.append("%s +%dLv" % [state.passive_name(passive_id), passive_need])
	if parts.is_empty():
		return "なし。宝箱または進化核で進化可能！"
	return " / ".join(parts)

func _overclock_label(weapon_id: String) -> String:
	if not state.overclocks.has(weapon_id):
		return "なし"
	return ", ".join(state.overclocks[weapon_id])
