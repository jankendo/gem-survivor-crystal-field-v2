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
const FieldEquipmentPickupSystemScript = preload("res://scripts/systems/FieldEquipmentPickupSystem.gd")
const FieldEquipmentRewardSystemScript = preload("res://scripts/systems/FieldEquipmentRewardSystem.gd")
const FieldGimmickSystemScript = preload("res://scripts/systems/FieldGimmickSystem.gd")
const UiSafeAreaSystemScript = preload("res://scripts/systems/UiSafeAreaSystem.gd")
const FieldDropSpawnSystemScript = preload("res://scripts/systems/FieldDropSpawnSystem.gd")
const ResonanceMagnetSystemScript = preload("res://scripts/systems/ResonanceMagnetSystem.gd")
const CharacterEvolutionSystemScript = preload("res://scripts/systems/CharacterEvolutionSystem.gd")
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
const SelectionActionSystemScript = preload("res://scripts/systems/SelectionActionSystem.gd")
const CorePickupChoiceSystemScript = preload("res://scripts/systems/CorePickupChoiceSystem.gd")
const TouchControlSystemScript = preload("res://scripts/systems/TouchControlSystem.gd")
const PerformanceProfileSystemScript = preload("res://scripts/systems/PerformanceProfileSystem.gd")
const InputModeSystemScript = preload("res://scripts/systems/InputModeSystem.gd")
const MobileSafeAreaSystemScript = preload("res://scripts/systems/MobileSafeAreaSystem.gd")
const IosSafePlayAreaSystemScript = preload("res://scripts/systems/IosSafePlayAreaSystem.gd")
const NotchLetterboxSystemScript = preload("res://scripts/systems/NotchLetterboxSystem.gd")
const MobileHudLayoutSystemScript = preload("res://scripts/systems/MobileHudLayoutSystem.gd")
const MobileScrollSystemScript = preload("res://scripts/systems/MobileScrollSystem.gd")
const DebugOverlaySystemScript = preload("res://scripts/systems/DebugOverlaySystem.gd")
const TouchHitTestDebugSystemScript = preload("res://scripts/systems/TouchHitTestDebugSystem.gd")
const IosPerformanceLogSystemScript = preload("res://scripts/systems/IosPerformanceLogSystem.gd")
const UiDirtyFlagSystemScript = preload("res://scripts/systems/UiDirtyFlagSystem.gd")
const IosPerformanceBudgetSystemScript = preload("res://scripts/systems/IosPerformanceBudgetSystem.gd")
const EffectBatchSystemScript = preload("res://scripts/systems/EffectBatchSystem.gd")
const IosEnergyOptimizerScript = preload("res://scripts/systems/IosEnergyOptimizer.gd")
const IosEnergyLogSystemScript = preload("res://scripts/systems/IosEnergyLogSystem.gd")
const IosFramePacingSystemScript = preload("res://scripts/systems/IosFramePacingSystem.gd")
const IosBackgroundThrottleSystemScript = preload("res://scripts/systems/IosBackgroundThrottleSystem.gd")
const MapPauseSystemScript = preload("res://scripts/systems/MapPauseSystem.gd")
const V2MomentumSystemScript = preload("res://scripts/systems/V2MomentumSystem.gd")
const V2MomentumTelemetryScript = preload("res://scripts/systems/V2MomentumTelemetry.gd")
const V2FeedbackDirectorScript = preload("res://scripts/systems/V2FeedbackDirector.gd")
const V2HudPresenterScript = preload("res://scripts/systems/V2HudPresenter.gd")
const V2ThemeProviderScript = preload("res://scripts/ui/v2/V2ThemeProvider.gd")
const ArenaViewScript = preload("res://scripts/ui/ArenaView.gd")
const CrystalButtonScript = preload("res://scripts/ui/components/CrystalButton.gd")
const ConfirmDialogScript = preload("res://scripts/ui/components/ConfirmDialog.gd")
const VirtualJoystickScript = preload("res://scripts/ui/components/VirtualJoystick.gd")
const TouchActionButtonScript = preload("res://scripts/ui/components/TouchActionButton.gd")

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
var field_equipment_pickup_system
var field_equipment_reward_system
var field_gimmick_system
var ui_safe_area_system
var field_drop_spawn_system
var resonance_magnet_system
var character_evolution_system
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
var selection_action_system
var core_pickup_choice_system
var touch_control_system
var performance_profile_system
var input_mode
var mobile_safe_area_system
var ios_safe_play_area_system
var notch_letterbox_system
var mobile_hud_layout_system
var mobile_scroll_system
var debug_overlay_system
var touch_hit_test_debug_system
var ios_performance_log_system
var ui_dirty_flag_system
var ios_performance_budget_system
var effect_batch_system
var ios_energy_optimizer
var ios_energy_log_system
var ios_frame_pacing_system
var ios_background_throttle_system
var map_pause_system
var v2_momentum_system
var v2_momentum_telemetry
var v2_feedback_director
var v2_hud_presenter
var v2_theme
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
var notification_panel: PanelContainer
var mobile_equipment_label: Label
var debug_overlay_label: Label
var boss_alert_label: Label
var boss_hp_label: Label
var boss_hp_bar: ProgressBar
var v2_momentum_panel: PanelContainer
var v2_momentum_label: Label
var v2_feedback_panel: PanelContainer
var v2_feedback_label: Label
var low_hp_overlay: ColorRect
var safe_play_left_bar: ColorRect
var safe_play_right_bar: ColorRect
var pending_finish = false
var initial_auto_infinite_enabled = true
var initial_character_id = "noah"
var initial_blessing_id = "attack"
var initial_save_data: Dictionary = {}
var initial_seed_text := ""
var pause_overlay: PanelContainer
var pause_backdrop: ColorRect
var pause_content: Label
var pause_content_scroll: ScrollContainer
var pause_tab_scroll: ScrollContainer
var pause_action_row: Container
var pause_confirm_dialog
var pause_dialog_layer: Control
var pause_title_label: Label
var pause_summary: Label
var pause_tab_buttons: Array = []
var pause_tab_index := 0
var pause_tabs := ["ステータス", "武器", "パッシブ", "進化条件", "ビルド相性", "フィールドヘルプ", "契約/過充電", "設定", "ログ"]
var pause_actions_signature := ""
var speed_active := false
var touch_root: Control
var virtual_joystick
var touch_direction := Vector2.ZERO
var touch_scan_button
var touch_drone_button
var touch_speed_button
var touch_pause_button
var touch_log_button
var touch_map_button
var touch_chest_button
var goal_panel: PanelContainer
var help_panel: PanelContainer
var runtime_settings: Dictionary = {}
var last_reward_signature := ""
var touch_rerolls_remaining := 0
var touch_banishes_remaining := 0
var mobile_layout: Dictionary = {}
var map_expanded := false
var runtime_ui_limits: Dictionary = {}
var pause_ui_signature := ""

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
	field_equipment_pickup_system = FieldEquipmentPickupSystemScript.new()
	field_equipment_reward_system = FieldEquipmentRewardSystemScript.new()
	field_gimmick_system = FieldGimmickSystemScript.new()
	ui_safe_area_system = UiSafeAreaSystemScript.new()
	field_drop_spawn_system = FieldDropSpawnSystemScript.new()
	resonance_magnet_system = ResonanceMagnetSystemScript.new()
	character_evolution_system = CharacterEvolutionSystemScript.new()
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
	selection_action_system = SelectionActionSystemScript.new()
	core_pickup_choice_system = CorePickupChoiceSystemScript.new()
	touch_control_system = TouchControlSystemScript.new()
	performance_profile_system = PerformanceProfileSystemScript.new()
	input_mode = InputModeSystemScript.new()
	mobile_safe_area_system = MobileSafeAreaSystemScript.new()
	ios_safe_play_area_system = IosSafePlayAreaSystemScript.new()
	notch_letterbox_system = NotchLetterboxSystemScript.new()
	mobile_hud_layout_system = MobileHudLayoutSystemScript.new()
	mobile_scroll_system = MobileScrollSystemScript.new()
	debug_overlay_system = DebugOverlaySystemScript.new()
	touch_hit_test_debug_system = TouchHitTestDebugSystemScript.new()
	ios_performance_log_system = IosPerformanceLogSystemScript.new()
	ui_dirty_flag_system = UiDirtyFlagSystemScript.new()
	ios_performance_budget_system = IosPerformanceBudgetSystemScript.new()
	effect_batch_system = EffectBatchSystemScript.new()
	ios_energy_optimizer = IosEnergyOptimizerScript.new()
	ios_energy_log_system = IosEnergyLogSystemScript.new()
	ios_frame_pacing_system = IosFramePacingSystemScript.new()
	ios_background_throttle_system = IosBackgroundThrottleSystemScript.new()
	map_pause_system = MapPauseSystemScript.new()
	v2_momentum_system = V2MomentumSystemScript.new()
	v2_momentum_telemetry = V2MomentumTelemetryScript.new()
	v2_feedback_director = V2FeedbackDirectorScript.new()
	v2_hud_presenter = V2HudPresenterScript.new()
	v2_theme = V2ThemeProviderScript.new()
	state.start_new_run(0, initial_seed_text)
	var save_data = initial_save_data if not initial_save_data.is_empty() else SaveSystem.new().load_data()
	var settings: Dictionary = save_data.get("settings", {})
	runtime_settings = settings.duplicate(true)
	v2_momentum_telemetry.configure(bool(settings.get("v2_momentum_telemetry", false)))
	ios_energy_optimizer.configure(settings)
	input_mode.configure(settings)
	add_child(mobile_scroll_system)
	mobile_scroll_system.configure(input_mode.is_touch_mode(), input_mode.is_touch_mode() and not input_mode.is_ios_touch())
	speed_hold_system.configure(settings)
	notification_log_system.configure(settings, "iOS" if input_mode.is_ios_touch() else OS.get_name())
	equipment_hud_system.configure(settings)
	touch_control_system.configure(settings, "iOS" if input_mode.is_ios_touch() else OS.get_name())
	debug_overlay_system.configure(
		settings,
		"iOS" if input_mode.is_ios_touch() else OS.get_name(),
		OS.has_feature("release"),
		input_mode.is_touch_mode(),
		input_mode.is_touch_mode() and not input_mode.is_ios_touch()
	)
	var touch_debug_enabled: bool = bool(settings.get("touch_hit_test_debug", false)) and debug_overlay_system.can_create_overlay_node()
	add_child(touch_hit_test_debug_system)
	touch_hit_test_debug_system.configure(self, touch_debug_enabled, not input_mode.is_ios_touch())
	ios_performance_log_system.configure(input_mode.is_ios_touch())
	ios_energy_log_system.configure(input_mode.is_ios_touch())
	ios_frame_pacing_system.apply(ios_energy_optimizer.budget, input_mode.is_ios_touch())
	ui_dirty_flag_system.configure({
		"equipment": float(ios_energy_optimizer.budget.get("equipment_hud_update_interval", 0.25)),
		"notifications": float(ios_energy_optimizer.budget.get("notification_update_interval", 0.20)),
		"goal": float(ios_energy_optimizer.budget.get("goal_update_interval", 0.25))
	})
	performance_profile_system.apply_to_state(state, settings)
	runtime_ui_limits = performance_profile_system.ui_limits(settings, "iOS" if input_mode.is_ios_touch() else OS.get_name())
	state.balance_data["max_effects"] = mini(state.max_effects(), int(runtime_ui_limits.get("max_effects", state.max_effects())))
	state.balance_data["max_texts"] = int(runtime_ui_limits.get("max_damage_numbers", state.max_texts())) if bool(runtime_ui_limits.get("damage_numbers_enabled", true)) else 0
	if not bool(runtime_ui_limits.get("background_particles_enabled", true)):
		state.background_particles.clear()
	elif state.background_particles.size() > state.max_background_particles():
		state.background_particles.resize(state.max_background_particles())
	state.effect_density = String(settings.get("effect_density", "normal"))
	meta_system.apply_to_state(state, initial_character_id, initial_blessing_id, save_data)
	state.debug_exp_multiplier = clampf(float(settings.get("debug_exp_multiplier", 1.0)), 0.25, 20.0)
	state.allow_debug_progress = bool(settings.get("allow_debug_progress", false))
	var unlocked_evolutions: Dictionary = save_data.get("character_evolutions_unlocked", {"noah": true})
	state.character_evolution_unlocked_ids = []
	for id in unlocked_evolutions.keys():
		if bool(unlocked_evolutions[id]):
			state.character_evolution_unlocked_ids.append(String(id))
	if state.selected_character_id == "noah" and not state.character_evolution_unlocked_ids.has("noah"):
		state.character_evolution_unlocked_ids.append("noah")
	field_equipment_reward_system.sanitize_for_state(state)
	selection_action_system.begin_run(state, save_data)
	state.auto_infinite_enabled = initial_auto_infinite_enabled
	state.auto_recall_drone_enabled = bool(save_data.get("settings", {}).get("auto_recall_drone", false))
	build_synergy_system.process(state, [])
	_build_ui()
	set_process(true)
	_refresh()

func _exit_tree() -> void:
	if ios_frame_pacing_system != null:
		ios_frame_pacing_system.restore()

func _process(delta: float) -> void:
	ui_dirty_flag_system.tick(delta)
	ios_energy_optimizer.tick(delta)
	ios_energy_optimizer.haptic_count = touch_control_system.haptic_count
	if audio_manager != null:
		ios_energy_optimizer.audio_event_count = audio_manager.audio_event_count
	notification_log_system.tick(delta)
	boss_alert_system.tick(delta)
	if v2_feedback_director != null:
		v2_feedback_director.tick(delta, state != null and state.paused)
	ios_performance_log_system.tick(delta, state, self)
	ios_energy_log_system.tick(delta, state, self, ios_energy_optimizer)
	if state.game_over:
		speed_active = false
		return
	map_pause_system.refresh_modal_reasons(state, map_expanded)
	if state.paused:
		speed_active = false
		_refresh_pause_ui()
		return
	if map_pause_system.gameplay_paused(state):
		speed_active = false
		touch_control_system.set_speed_pressed(false)
		state.map_pause_count += 1
		_refresh()
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
	var speed_pressed = speed_hold_system.is_pressed() or touch_control_system.speed_pressed
	var time_scale = speed_hold_system.simulation_multiplier(speed_pressed, speed_blocked)
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
	var keyboard_direction: Vector2 = player_system.input_direction() if input_mode.keyboard_hints_allowed() else Vector2.ZERO
	var movement = touch_control_system.combined_direction(keyboard_direction, touch_direction)
	player_system.process_movement(state, movement, sim_delta)
	enemy_spawner.process(state, sim_delta, events)
	field_gimmick_system.process(state, sim_delta, events)
	weapon_system.process(state, sim_delta, events)
	pickup_system.process_gems(state, sim_delta, events)
	resonance_magnet_system.process(state, sim_delta, events)
	character_evolution_system.process(state, events)
	field_drop_system.process(state, sim_delta, events)
	if not state.level_up_pending:
		field_equipment_pickup_system.process(state, sim_delta, events)
	chest_system.process_pickups(state, events, sim_delta)
	player_system.process_survival(state, sim_delta, events)
	field_help_system.process(state, events)
	goal_hint_system.process(state, events)
	exploration_mastery_system.process(state, events)
	exploration_chain_system.process(state, sim_delta, events)
	v2_momentum_system.process(state, sim_delta, events)
	if state.auto_recall_drone_enabled and state.recall_drone_ready:
		recall_drone_system.activate(state, events)
	balance_log_system.process(state, sim_delta)
	_tick_flashes(sim_delta)
	_handle_events(events)
	if state.game_over and not pending_finish:
		_finish_game(events)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed and event.keycode == KEY_F12:
		if debug_overlay_system.toggle_hidden():
			if debug_overlay_label != null:
				debug_overlay_label.show()
		elif debug_overlay_label != null:
			debug_overlay_label.hide()
		return
	if input_mode.is_ios_touch():
		return
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
			elif event.keycode == KEY_S:
				_on_touch_skip()
			elif event.keycode == KEY_B:
				var uid := String(state.level_up_options[state.selected_reward_index].get("uid", "")) if state.selected_reward_index >= 0 and state.selected_reward_index < state.level_up_options.size() else ""
				if uid != "":
					_on_touch_banish(uid)
		elif event.keycode == KEY_ESCAPE:
			_toggle_pause()
		elif event.keycode == KEY_H:
			message_label.text = "ジェムを吸ってLvを上げ、攻撃を強化しましょう"
		elif event.keycode == KEY_F:
			_scan_field_target()
		elif event.keycode == KEY_R:
			_activate_recall_drone()

func _runtime_safe_rect(viewport_size: Vector2, extra_margin: float = 16.0) -> Rect2:
	var base_safe: Rect2 = mobile_safe_area_system.runtime_safe_rect(viewport_size, extra_margin)
	if ios_safe_play_area_system == null or input_mode == null:
		return base_safe
	return ios_safe_play_area_system.safe_play_rect(viewport_size, runtime_settings, input_mode.is_ios_touch(), base_safe)

func _build_ui() -> void:
	var requested_scale = float(SaveSystem.new().get_setting("ui_scale", 1.0))
	var viewport_size = get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	var ui_scale = ui_safe_area_system.ui_scale_for(viewport_size, requested_scale, state.ui_layout_defs)
	var safe_margin = float(state.ui_layout_defs.get("safe_margin", 24.0))
	var mobile_safe: Rect2 = _runtime_safe_rect(viewport_size, float(runtime_settings.get("safe_area_margin", 16.0)))
	var safe_left: float = mobile_safe.position.x if input_mode.is_touch_mode() else safe_margin
	var safe_right: float = viewport_size.x - mobile_safe.end.x if input_mode.is_touch_mode() else safe_margin
	var safe_top: float = mobile_safe.position.y if input_mode.is_touch_mode() else float(state.ui_layout_defs.get("hud_top_margin", 18.0))
	var layout_settings := runtime_settings.duplicate(true)
	layout_settings["_device_size"] = _layout_device_size()
	mobile_layout = mobile_hud_layout_system.layout(viewport_size, mobile_safe, layout_settings) if input_mode.is_touch_mode() else {}
	var bg = ColorRect.new()
	bg.color = Color(0.020, 0.030, 0.052)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build_safe_play_bars(viewport_size, mobile_safe)

	arena_view = ArenaViewScript.new()
	arena_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(arena_view)
	arena_view.bind_state(state)
	if input_mode.is_touch_mode():
		arena_view.configure_mobile(mobile_layout)
		arena_view.minimap_tapped.connect(_toggle_expanded_map)

	low_hp_overlay = ColorRect.new()
	low_hp_overlay.color = Color(0.88, 0.04, 0.03, 0.0)
	low_hp_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	low_hp_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(low_hp_overlay)

	var top = VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = safe_left
	top.offset_right = -safe_right
	top.offset_top = safe_top
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

	goal_panel = PanelContainer.new()
	goal_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	if input_mode.is_touch_mode():
		goal_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		goal_panel.offset_left = safe_left
		goal_panel.offset_right = safe_left + minf(330.0, viewport_size.x * 0.28)
		goal_panel.offset_top = 132.0 * ui_scale
		goal_panel.offset_bottom = 236.0 * ui_scale
	else:
		goal_panel.offset_left = -float(state.ui_layout_defs.get("goal_panel_width", 330.0)) - safe_right
		goal_panel.offset_right = -safe_right
		goal_panel.offset_top = 132.0 * ui_scale
		goal_panel.offset_bottom = 302.0 * ui_scale
	goal_panel.add_theme_stylebox_override("panel", _hud_panel_style(Color(0.42, 0.82, 1.0)))
	add_child(goal_panel)
	var goal_box = VBoxContainer.new()
	goal_box.add_theme_constant_override("separation", 4)
	goal_panel.add_child(goal_box)
	goal_label = Label.new()
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_label.custom_minimum_size.x = 250 if input_mode.is_touch_mode() else 285
	goal_label.add_theme_font_size_override("font_size", int((17.0 if input_mode.is_touch_mode() else 16.0) * ui_scale))
	goal_label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0))
	goal_box.add_child(goal_label)
	event_label = Label.new()
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_label.custom_minimum_size.x = 250 if input_mode.is_touch_mode() else 285
	event_label.add_theme_font_size_override("font_size", int(14.0 * ui_scale))
	event_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.36))
	goal_box.add_child(event_label)
	exploration_label = Label.new()
	exploration_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exploration_label.custom_minimum_size.x = 250 if input_mode.is_touch_mode() else 285
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

	v2_momentum_panel = PanelContainer.new()
	v2_momentum_panel.visible = false
	v2_momentum_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v2_momentum_panel.custom_minimum_size = Vector2(220.0 if input_mode.is_touch_mode() else 260.0, 82.0)
	v2_momentum_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	v2_momentum_panel.offset_left = safe_left
	v2_momentum_panel.offset_right = safe_left + (220.0 if input_mode.is_touch_mode() else 260.0)
	v2_momentum_panel.offset_top = 96.0 * ui_scale
	v2_momentum_panel.offset_bottom = 178.0 * ui_scale
	v2_momentum_panel.add_theme_stylebox_override("panel", _hud_panel_style(v2_theme.color("momentum", Color(0.62, 0.50, 1.0))))
	add_child(v2_momentum_panel)
	v2_momentum_label = Label.new()
	v2_momentum_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v2_momentum_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v2_momentum_label.add_theme_font_size_override("font_size", int((15.0 if input_mode.is_touch_mode() else 16.0) * ui_scale))
	v2_momentum_label.add_theme_color_override("font_color", v2_theme.color("momentum_high", Color(0.86, 0.96, 1.0)))
	v2_momentum_panel.add_child(v2_momentum_label)

	v2_feedback_panel = PanelContainer.new()
	v2_feedback_panel.visible = false
	v2_feedback_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v2_feedback_panel.custom_minimum_size = Vector2(300.0, 76.0)
	v2_feedback_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	v2_feedback_panel.offset_left = viewport_size.x * 0.30
	v2_feedback_panel.offset_right = -viewport_size.x * 0.30
	v2_feedback_panel.offset_top = 202.0 * ui_scale
	v2_feedback_panel.offset_bottom = 278.0 * ui_scale
	v2_feedback_panel.add_theme_stylebox_override("panel", _hud_panel_style(v2_theme.color("crystal", Color(0.42, 0.92, 1.0))))
	add_child(v2_feedback_panel)
	v2_feedback_label = Label.new()
	v2_feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v2_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v2_feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	v2_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v2_feedback_label.add_theme_font_size_override("font_size", int((16.0 if input_mode.is_touch_mode() else 18.0) * ui_scale))
	v2_feedback_label.add_theme_color_override("font_color", v2_theme.color("text", Color(0.94, 0.98, 1.0)))
	v2_feedback_panel.add_child(v2_feedback_label)

	notification_panel = PanelContainer.new()
	notification_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	notification_panel.offset_left = -390.0
	notification_panel.offset_right = -safe_right
	notification_panel.offset_top = 318.0
	notification_panel.offset_bottom = 494.0
	if input_mode.is_touch_mode():
		var minimap: Rect2 = mobile_layout.get("minimap_rect", Rect2(Vector2(viewport_size.x - 220.0, 90.0), Vector2.ONE * 204.0))
		notification_panel.offset_left = minimap.position.x
		notification_panel.offset_right = -(viewport_size.x - minimap.end.x)
		notification_panel.offset_top = minimap.end.y + 10.0
		notification_panel.offset_bottom = minf(viewport_size.y - 210.0, minimap.end.y + 112.0)
	notification_panel.add_theme_stylebox_override("panel", _hud_panel_style(Color(0.62, 0.78, 1.0)))
	add_child(notification_panel)
	notification_label = Label.new()
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	notification_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notification_label.add_theme_font_size_override("font_size", int((16.0 if input_mode.is_touch_mode() else 14.0) * ui_scale))
	notification_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	notification_panel.add_child(notification_label)

	help_panel = PanelContainer.new()
	help_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help_panel.offset_left = safe_margin
	help_panel.offset_right = safe_margin + float(state.ui_layout_defs.get("field_help_panel_width", 390.0))
	if input_mode.is_touch_mode():
		help_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		help_panel.offset_left = safe_left
		help_panel.offset_right = safe_left + minf(360.0, viewport_size.x * 0.30)
		help_panel.offset_top = maxf(310.0, viewport_size.y * 0.42)
		help_panel.offset_bottom = minf(viewport_size.y - 210.0, help_panel.offset_top + 125.0)
	else:
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
	message_label.text = "左下をドラッグして移動　右下でスキャン・回収・倍速" if input_mode.is_touch_mode() else "移動 WASD/矢印　F/右クリック スキャン　R ドローン　Esc ポーズ"
	add_child(message_label)

	mobile_equipment_label = Label.new()
	mobile_equipment_label.visible = input_mode.is_touch_mode()
	mobile_equipment_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	mobile_equipment_label.offset_left = viewport_size.x * 0.30
	mobile_equipment_label.offset_right = -viewport_size.x * 0.30
	mobile_equipment_label.offset_top = -112.0
	mobile_equipment_label.offset_bottom = -72.0
	mobile_equipment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mobile_equipment_label.add_theme_font_size_override("font_size", int(16.0 * ui_scale))
	mobile_equipment_label.add_theme_color_override("font_color", Color(0.84, 0.96, 1.0))
	add_child(mobile_equipment_label)

	if debug_overlay_system.can_create_overlay_node():
		debug_overlay_label = Label.new()
		debug_overlay_label.visible = false
		debug_overlay_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		debug_overlay_label.process_mode = Node.PROCESS_MODE_DISABLED
		debug_overlay_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
		debug_overlay_label.offset_left = safe_left
		debug_overlay_label.offset_top = safe_top + 150.0
		debug_overlay_label.offset_right = safe_left + 220.0
		debug_overlay_label.offset_bottom = safe_top + 280.0
		debug_overlay_label.add_theme_font_size_override("font_size", 14)
		debug_overlay_label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.30))
		add_child(debug_overlay_label)
	else:
		debug_overlay_label = null

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
	reward_popup.reroll_requested.connect(_on_touch_reroll)
	reward_popup.banish_requested.connect(_on_touch_banish)
	reward_popup.skip_requested.connect(_on_touch_skip)
	_build_touch_controls(ui_scale)
	_build_pause_ui()

func _handle_events(events: Array) -> void:
	for event in events:
		var notification_revision: int = int(notification_log_system.revision)
		notification_log_system.ingest(event, state.elapsed_seconds)
		v2_feedback_director.ingest(event, state.elapsed_seconds)
		if String(event.get("type", "")) in ["v2_momentum", "v2_momentum_tier_up", "v2_momentum_ending"]:
			v2_momentum_telemetry.record(state, String(event.get("trigger_type", "")))
		if notification_log_system.revision != notification_revision:
			ios_energy_optimizer.mark_notification()
		boss_alert_system.ingest(event)
		match String(event.get("type", "")):
			"attack":
				_play_sfx("attack")
			"enemy_attack_warning":
				_play_sfx("attack")
			"enemy_die":
				_play_sfx("enemy_die")
			"gem_collect":
				_play_sfx("gem")
			"level_up":
				_play_sfx("levelup")
				message_label.text = "レベルアップ！強化を選択"
			"auto_infinite":
				_play_sfx("reward_select")
				message_label.text = "%s" % String(event.get("name", "無限強化"))
			"overclock":
				_play_sfx("evolution")
				message_label.text = "%s 過充電！" % String(event.get("name", "過充電"))
			"rune_contract_offer":
				_play_sfx("levelup")
				message_label.text = "ルーン契約を選べます"
			"rune_contract_apply":
				_play_sfx("reward_select")
				message_label.text = "%sを結んだ" % String(event.get("name", "契約"))
			"rune_contract_skip":
				message_label.text = "契約を見送りました"
			"reward_select":
				_play_sfx("reward_select")
			"chest_drop":
				_play_sfx("chest")
			"chest_open":
				_play_sfx("chest")
				message_label.text = String(event.get("message", "宝箱！"))
			"evolution":
				_play_sfx("evolution")
				message_label.text = "%sへ進化！" % String(event.get("name", "進化武器"))
			"player_damage":
				_play_sfx("damage")
			"player_heal":
				message_label.text = "HP回復"
			"gem_fever":
				_play_sfx("levelup")
				message_label.text = "ジェムフィーバー！"
			"combo_milestone":
				message_label.text = String(event.get("message", "吸収コンボ！"))
			"crystal_break":
				message_label.text = "クリスタル破壊！"
			"crystal_overdrive":
				_play_sfx("evolution")
				message_label.text = "クリスタルオーバードライブ！"
			"boss_warning":
				message_label.text = String(event.get("message", "ボス接近！"))
			"boss_spawn":
				message_label.text = "%s 出現！" % String(event.get("name", "ボス"))
			"boss_enrage":
				message_label.text = "生存中のボスが強化！"
			"field_event_start":
				_play_sfx("levelup")
				message_label.text = "イベント発生：%s　報酬：%s　リスク：%s　残り%.0f秒" % [
					String(event.get("name", "イベント")),
					String(event.get("reward", state.active_field_event.get("reward", ""))),
					String(event.get("risk", state.active_field_event.get("risk", ""))),
					float(event.get("duration", 0.0))
				]
			"field_event_end":
				message_label.text = "イベント%s：%s" % ["成功" if bool(event.get("success", false)) else "終了", String(event.get("name", "イベント"))]
			"field_event_success":
				_play_sfx("reward_select")
				message_label.text = "イベント成功：%s" % String(event.get("name", "イベント"))
			"field_event_failed":
				message_label.text = "イベント終了：%sの目標は未達成" % String(event.get("name", "イベント"))
			"field_event_reward":
				message_label.text = "イベント報酬：%s" % String(event.get("message", "報酬獲得"))
			"recall_drone_ready":
				message_label.text = "回収ドローン READY [R]"
			"recall_drone":
				_play_sfx("gem")
				message_label.text = "回収ドローン発動！ 全ジェム %d / EXP %d" % [int(event.get("count", 0)), int(event.get("exp", 0))]
			"global_gem_collection":
				if int(event.get("count", 0)) > 0:
					message_label.text = "全フィールドジェム回収：%d / EXP %d" % [int(event.get("count", 0)), int(event.get("exp", 0))]
			"resonance_magnet_collect":
				message_label.text = "共鳴磁核：周辺ジェム %d 回収" % int(event.get("count", 0))
			"character_evolution_ready":
				message_label.text = "キャラ進化条件達成：進化核を探そう"
			"character_evolution":
				message_label.text = "キャラ進化：%s" % String(event.get("name", "進化"))
			"best_score":
				_play_sfx("bestscore")
			"build_synergy":
				_play_sfx("evolution")
				message_label.text = "ビルド完成：%s" % String(event.get("name", "相性"))
			"melee_rush":
				_play_sfx("levelup")
				message_label.text = "近接ラッシュ Lv%d！" % int(event.get("level", 1))
			"shock_explosion":
				message_label.text = "感電爆発！"
			"field_drop_pickup":
				_play_sfx("reward_select")
				message_label.text = String(event.get("message", "フィールド報酬"))
			"core_choice_open":
				_play_sfx("levelup")
				message_label.text = "%sの中身を選択できます" % ("武器コア" if String(event.get("kind", "")) == "weapon" else "パッシブ結晶")
			"core_choice_accept":
				_play_sfx("reward_select")
				message_label.text = "%sを取得" % String(event.get("name", "コア報酬"))
			"core_choice_decline":
				message_label.text = "コアを見送りました"
			"field_equipment_choice_open":
				_play_sfx("levelup")
				message_label.text = "フィールド装備発見：%s" % String(event.get("name", "装備"))
			"field_equipment_pickup":
				_play_sfx("reward_select")
				message_label.text = "フィールド装備取得：%s" % String(event.get("name", "装備"))
			"field_equipment_decline":
				message_label.text = "フィールド装備を見送りました"
			"field_equipment_converted":
				message_label.text = "取得できないフィールド装備をスコアに変換"
			"selection_skip":
				message_label.text = "選択をスキップしました"
			"selection_reroll":
				message_label.text = "候補を再抽選：残り%d" % int(event.get("remaining", 0))
			"selection_seal":
				message_label.text = "候補を封印：%s" % String(event.get("name", "候補"))
			"dynamic_drop_spawn":
				_play_sfx("levelup")
				message_label.text = "遠方に%sが出現！ 距離%dm　矢印を追って回収" % [
					String(event.get("name", "フィールド報酬")),
					int(round(float(event.get("distance", 0.0)) / 10.0))
				]
			"dynamic_drop_expired":
				message_label.text = "%sは消滅しました" % String(event.get("name", "フィールド報酬"))
			"field_discovery":
				SaveSystem.new().mark_field_discovered(String(event.get("kind", "")), String(event.get("id", "")))
				_play_sfx("reward_select")
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
				_play_sfx("chest")
				message_label.text = "爆薬鉱脈が爆発！"
			"gimmick_heal":
				message_label.text = "回復泉"
			"gimmick_spawn":
				message_label.text = "召喚裂け目から敵出現"
			"gimmick_open":
				_play_sfx("chest")
				message_label.text = "封印宝箱柱が開いた"
			"v2_momentum":
				message_label.text = String(event.get("message", "Momentum"))

func _play_sfx(name: String) -> void:
	return

func _refresh() -> void:
	var exp_percent = int(round(100.0 * clampf(float(state.exp) / float(maxi(state.exp_to_next, 1)), 0.0, 1.0)))
	_set_label_text(hp_label, "HP %d / %d" % [maxi(state.hp, 0), state.max_hp])
	var hp_changed: bool = hp_bar.max_value != state.max_hp or hp_bar.value != clampi(state.hp, 0, state.max_hp)
	if hp_changed:
		hp_bar.max_value = state.max_hp
		hp_bar.value = clampi(state.hp, 0, state.max_hp)
		_update_hp_bar_style()
	var hud_text := "Lv %d　EXP %d%%　時間 %s　撃破 %s" % [
		state.level,
		exp_percent,
		JaText.format_time(state.elapsed_seconds),
		JaText.format_int(state.kills)
	]
	if input_mode.is_touch_mode():
		hud_text += "　武器 %s　パッシブ %s" % [state.equipment_count_label("weapon"), state.equipment_count_label("passive")]
	if not is_equal_approx(state.debug_exp_multiplier, 1.0):
		hud_text += "　テストEXP：%.1fx" % state.debug_exp_multiplier
	if int(state.passives.get("resonance_magnet_core", 0)) > 0 and state.resonance_magnet_timer > 0.0:
		hud_text += "　共鳴 %.0fs" % state.resonance_magnet_timer
	if state.character_evolution_available:
		hud_text += "　キャラ進化可"
	hud_text += v2_hud_presenter.top_hud_suffix(state)
	_set_label_text(hud_label, hud_text)
	var equipment_signature := "%s:%s:%s" % [str(state.weapons), str(state.passives), str(state.evolved_weapons)]
	if ui_dirty_flag_system.should_update("equipment", equipment_signature):
		_set_label_text(weapon_label, equipment_hud_system.weapon_text(state))
		_set_label_text(passive_label, equipment_hud_system.passive_text(state))
		_set_label_text(mobile_equipment_label, equipment_hud_system.compact_text(state))
	weapon_label.visible = not input_mode.is_touch_mode() and equipment_hud_system.show_weapons
	passive_label.visible = not input_mode.is_touch_mode() and equipment_hud_system.show_passives
	mobile_equipment_label.visible = input_mode.is_touch_mode() and not map_expanded and mobile_equipment_label.text != ""
	_set_label_text(speed_label, speed_hold_system.display_text(speed_active))
	if ui_dirty_flag_system.should_update("notifications", str(notification_log_system.revision)):
		_set_label_text(notification_label, notification_log_system.visible_text())
	notification_panel.visible = not map_expanded and notification_log_system.enabled and notification_label.text != ""
	if debug_overlay_label != null:
		_set_label_text(debug_overlay_label, debug_overlay_system.overlay_text())
		debug_overlay_label.visible = debug_overlay_system.should_show()
		debug_overlay_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_label_text(boss_alert_label, boss_alert_system.warning_text if boss_alert_system.warning_timer > 0.0 else "")
	var boss_snapshot = boss_alert_system.active_boss_snapshot(state)
	boss_hp_label.visible = not boss_snapshot.is_empty()
	boss_hp_bar.visible = not boss_snapshot.is_empty()
	if not boss_snapshot.is_empty():
		_set_label_text(boss_hp_label, "%s  %d / %d" % [String(boss_snapshot.get("name", "ボス")), int(boss_snapshot.get("hp", 0)), int(boss_snapshot.get("max_hp", 1))])
		boss_hp_bar.max_value = int(boss_snapshot.get("max_hp", 1))
		boss_hp_bar.value = int(boss_snapshot.get("hp", 0))
	var combo_text := ""
	if state.pickup_combo_count > 0:
		combo_text = "吸収コンボ %d　最大 %d　現在地：%s" % [state.pickup_combo_count, state.max_combo, state.current_terrain_name]
	else:
		combo_text = "最大コンボ %d　現在地：%s" % [state.max_combo, state.current_terrain_name]
	if state.boss_warning_timer > 0.0:
		message_label.text = state.boss_warning_text
	if state.chest_pending:
		message_label.text = state.chest_message
	elif state.chest_notice_timer > 0.0:
		message_label.text = state.chest_message
	if state.gem_fever_timer > 0.0:
		combo_text += "　FEVER %.1fs" % state.gem_fever_timer
	if state.crystal_overdrive_timer > 0.0:
		combo_text += "　OD %.1fs" % state.crystal_overdrive_timer
	if state.recall_drone_ready:
		combo_text += "　回収ドローン READY" if input_mode.is_touch_mode() else "　回収ドローン READY [R]"
	else:
		var charge = int(round(100.0 * state.recall_drone_meter / float(state.balance_data.get("recall_drone_charge_seconds", 180.0))))
		combo_text += "　ドローン %d%%" % clampi(charge, 0, 100)
	if state.melee_rush_timer > 0.0:
		combo_text += "　近接ラッシュLv%d %.0fs" % [state.melee_rush_level, state.melee_rush_timer]
	if not state.active_synergies.is_empty():
		combo_text += "　%s" % state.active_synergy_label()
	var build_focus: String = v2_hud_presenter.build_focus_text(state)
	if build_focus != "":
		combo_text += "　%s" % build_focus
	var momentum_text: String = v2_hud_presenter.momentum_text(state)
	if momentum_text != "":
		combo_text += "　%s" % momentum_text
	_set_label_text(combo_label, combo_text)
	_refresh_v2_phase2_hud()
	if exp_bar.value != exp_percent:
		exp_bar.value = exp_percent
	var goal_signature := "%s:%d:%d:%d" % [str(state.current_goals), int(state.player_position.x / 16.0), int(state.player_position.y / 16.0), int(state.elapsed_seconds * 4.0)]
	if ui_dirty_flag_system.should_update("goal", goal_signature):
		_refresh_goal_hud()
	_refresh_field_help_hud()
	_refresh_low_hp_overlay()
	if state.level_up_pending:
		var signature := _reward_signature(state.level_up_options)
		if signature != last_reward_signature:
			if last_reward_signature == "":
				touch_rerolls_remaining = int(state.selection_reroll_remaining)
				touch_banishes_remaining = int(state.selection_seal_remaining)
			last_reward_signature = signature
			touch_rerolls_remaining = int(state.selection_reroll_remaining)
			var controls: Dictionary = selection_action_system.controls_for(state, {
				"banishes": int(state.selection_seal_remaining),
				"can_skip": _has_contract_skip(state.level_up_options) or _has_pending_pickup_choice(),
				"title": _reward_popup_title()
			})
			if _has_pending_pickup_choice():
				controls["can_seal"] = false
				controls["seal_remaining"] = 0
			reward_popup.show_options(state.level_up_options, controls, input_mode.is_touch_mode())
	else:
		reward_popup.hide_popup()
		last_reward_signature = ""
	arena_view.queue_redraw()
	_refresh_touch_controls()

func _refresh_goal_hud() -> void:
	if goal_label == null:
		return
	if state.current_goals.is_empty():
		_set_label_text(goal_label, "次の目標\nジェムを回収してLvを上げる")
	else:
		var main: Dictionary = state.current_goals[0]
		var distance = int(round(float(main.get("distance", 0.0)) / 10.0))
		var lines: Array
		if input_mode.is_touch_mode():
			lines = [
				"目標　%s" % String(main.get("title", "周辺を探索")),
				"%dm" % distance if distance > 0 else "現在地点"
			]
		else:
			lines = [
				"次の目標",
				String(main.get("title", "周辺を探索")),
				"理由：%s" % String(main.get("reason", "")),
				"距離：%dm" % distance if distance > 0 else "現在地点"
			]
			for i in range(1, mini(3, state.current_goals.size())):
				lines.append("副：%s" % String(state.current_goals[i].get("title", "")))
		_set_label_text(goal_label, "\n".join(lines))
	if input_mode.is_touch_mode():
		event_label.visible = not state.active_field_event.is_empty()
		exploration_label.visible = false
	if not state.active_field_event.is_empty():
		_set_label_text(event_label, "イベント：%s　残り%.0f秒\n目標：%s\n報酬：%s / リスク：%s" % [
			String(state.active_field_event.get("name_ja", "イベント")),
			state.field_event_timer,
			String(state.active_field_event.get("success_condition_ja", state.active_field_event.get("objective_ja", "生存"))),
			String(state.active_field_event.get("reward", "")),
			String(state.active_field_event.get("risk", ""))
		])
	else:
		_set_label_text(event_label, "次イベント：%s" % ("未定" if state.next_field_event_time <= 0.0 else JaText.format_time(maxf(0.0, state.next_field_event_time - state.elapsed_seconds))))
	_set_label_text(exploration_label, "探索ランク %s　スコア %d\n探索チェーン x%d　残り%.0f秒" % [
		state.exploration_rank,
		state.exploration_score,
		state.exploration_chain,
		state.exploration_chain_timer
	])

func _refresh_v2_phase2_hud() -> void:
	if v2_momentum_panel != null:
		var text: String = v2_hud_presenter.momentum_panel_text(state)
		v2_momentum_panel.visible = text != "" and not map_expanded
		_set_label_text(v2_momentum_label, text)
	if v2_feedback_panel != null:
		var feedback_text: String = v2_feedback_director.active_text()
		v2_feedback_panel.visible = feedback_text != "" and not map_expanded and not state.level_up_pending and not state.chest_pending
		_set_label_text(v2_feedback_label, feedback_text)
		if v2_feedback_panel.visible:
			v2_feedback_panel.add_theme_stylebox_override("panel", _hud_panel_style(_feedback_color(v2_feedback_director.active_accent())))

func _feedback_color(accent: String) -> Color:
	match accent:
		"growth":
			return v2_theme.color("growth", Color(1.0, 0.82, 0.34))
		"weapon":
			return v2_theme.color("weapon", Color(1.0, 0.48, 0.32))
		"passive":
			return v2_theme.color("passive", Color(0.38, 1.0, 0.74))
		"momentum":
			return v2_theme.color("momentum", Color(0.62, 0.50, 1.0))
		"danger":
			return v2_theme.color("danger", Color(1.0, 0.28, 0.44))
		_:
			return v2_theme.color("crystal", Color(0.42, 0.92, 1.0))

func _set_label_text(label: Label, value: String) -> void:
	if ios_energy_optimizer != null:
		ios_energy_optimizer.set_label(label, value)
	elif label != null and label.text != value:
		label.text = value

func _refresh_field_help_hud() -> void:
	if field_help_label == null:
		return
	var target: Dictionary = state.scanned_field_help if state.field_scan_timer > 0.0 and not state.scanned_field_help.is_empty() else state.nearby_field_help
	if input_mode.is_touch_mode():
		help_panel.visible = not map_expanded and not target.is_empty()
	if target.is_empty():
		var scan_hint := "スキャンボタンで周辺を調査" if input_mode.is_touch_mode() else "F / 右クリックで周辺をスキャン"
		_set_label_text(field_help_label, "現在地：%s\n%s\n%s" % [state.current_terrain_name, state.current_terrain_guide(), scan_hint])
		return
	_set_label_text(field_help_label, "現在地：%s\n%s\n\n%s" % [state.current_terrain_name, state.current_terrain_guide(), tooltip_system.format_field_help(target, state.field_scan_timer > 0.0)])

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
	if not state.pending_core_choice.is_empty():
		if core_pickup_choice_system.accept_current(state, reward_id, events):
			level_up_system.open_queued_level_up_if_ready(state, events)
			_handle_events(events)
			_refresh()
		return
	if not state.pending_field_equipment_choice.is_empty():
		if field_equipment_pickup_system.accept_current(state, reward_id, events):
			level_up_system.open_queued_level_up_if_ready(state, events)
			_handle_events(events)
			_refresh()
		return
	if level_up_system.apply_option(state, reward_id, events):
		_handle_events(events)
		_refresh()

func _on_touch_reroll() -> void:
	if int(state.selection_reroll_remaining) <= 0 or not state.level_up_pending or _has_pending_pickup_choice():
		return
	var events: Array = []
	if not selection_action_system.consume_reroll(state, events):
		return
	var before_signature := _reward_signature(state.level_up_options)
	var next_options: Array = level_up_system.prepare_options(state, 3)
	for i in range(4):
		if _reward_signature(next_options) != before_signature:
			break
		next_options = level_up_system.prepare_options(state, 3)
	state.level_up_options = next_options
	touch_rerolls_remaining = int(state.selection_reroll_remaining)
	last_reward_signature = _reward_signature(state.level_up_options)
	reward_popup.show_options(state.level_up_options, selection_action_system.controls_for(state, {
		"banishes": int(state.selection_seal_remaining),
		"can_skip": _has_contract_skip(state.level_up_options),
		"title": _reward_popup_title()
	}), input_mode.is_touch_mode())
	_handle_events(events)
	touch_control_system.feedback_light()
	_refresh()

func _on_touch_banish(reward_id: String) -> void:
	if not state.level_up_pending or _has_pending_pickup_choice():
		return
	var events: Array = []
	if not selection_action_system.seal_option(state, reward_id, events):
		return
	touch_banishes_remaining = int(state.selection_seal_remaining)
	var replacement_pool: Array = level_up_system.prepare_options(state, 4)
	var next_options: Array = []
	for option in state.level_up_options:
		if String(option.get("uid", "")) != reward_id:
			next_options.append(option)
	for option in replacement_pool:
		if next_options.size() >= 3:
			break
		var uid := String(option.get("uid", ""))
		var exists := false
		for current in next_options:
			if String(current.get("uid", "")) == uid:
				exists = true
				break
		if uid != reward_id and not exists:
			next_options.append(option)
	state.level_up_options = next_options
	last_reward_signature = _reward_signature(state.level_up_options)
	reward_popup.show_options(state.level_up_options, selection_action_system.controls_for(state, {
		"banishes": int(state.selection_seal_remaining),
		"can_skip": _has_contract_skip(state.level_up_options),
		"title": _reward_popup_title()
	}), input_mode.is_touch_mode())
	_handle_events(events)
	touch_control_system.feedback_light()
	_refresh()

func _on_touch_skip() -> void:
	if not state.level_up_pending:
		return
	var events: Array = []
	if not state.pending_core_choice.is_empty():
		if core_pickup_choice_system.decline_current(state, events):
			level_up_system.open_queued_level_up_if_ready(state, events)
			_handle_events(events)
			_refresh()
		return
	if not state.pending_field_equipment_choice.is_empty():
		if field_equipment_pickup_system.decline_current(state, events):
			level_up_system.open_queued_level_up_if_ready(state, events)
			_handle_events(events)
			_refresh()
		return
	for option in state.level_up_options:
		if String(option.get("kind", "")) == "contract_skip":
			_on_reward_chosen(String(option.get("uid", "")))
			return
	if selection_action_system.skip_current(state, events):
		level_up_system.open_queued_level_up_if_ready(state, events)
		_handle_events(events)
		touch_control_system.feedback_light()
		_refresh()

func _has_contract_skip(options: Array) -> bool:
	for option in options:
		if String(option.get("kind", "")) == "contract_skip":
			return true
	return false

func _has_pending_pickup_choice() -> bool:
	return not state.pending_core_choice.is_empty() or not state.pending_field_equipment_choice.is_empty()

func _reward_popup_title() -> String:
	if not state.pending_core_choice.is_empty():
		return "コアの中身を選択"
	if not state.pending_field_equipment_choice.is_empty():
		return "フィールド装備"
	if not state.level_up_options.is_empty() and String(state.level_up_options[0].get("kind", "")).begins_with("contract"):
		return "ルーン契約"
	return "レベルアップ！"

func _reward_signature(options: Array) -> String:
	var ids: Array = []
	for option in options:
		ids.append(String(option.get("uid", option.get("id", ""))))
	return "|".join(ids)

func _tick_flashes(delta: float) -> void:
	state.field_scan_timer = maxf(0.0, state.field_scan_timer - delta)
	state.goal_change_timer = maxf(0.0, state.goal_change_timer - delta)
	for flash in state.hit_flashes.duplicate():
		flash["life"] = float(flash.get("life", 0.0)) - delta
		if float(flash.get("life", 0.0)) <= 0.0:
			state.hit_flashes.erase(flash)
			state.release_runtime("hit_flash", flash)
	for line in state.effect_lines.duplicate():
		line["life"] = float(line.get("life", 0.0)) - delta
		if float(line.get("life", 0.0)) <= 0.0:
			state.effect_lines.erase(line)
			state.release_runtime("effect_line", line)
	for text_data in state.floating_texts.duplicate():
		text_data["life"] = float(text_data.get("life", 0.0)) - delta
		if float(text_data.get("life", 0.0)) <= 0.0:
			state.floating_texts.erase(text_data)
			state.release_runtime("damage_text", text_data)
	for ring in state.gem_ring_effects.duplicate():
		if state.elapsed_seconds - float(ring.get("start_time", state.elapsed_seconds)) >= float(ring.get("duration", 0.78)):
			state.gem_ring_effects.erase(ring)
	if input_mode.is_ios_touch() and arena_view != null:
		var visible_world: Vector2 = arena_view.size / maxf(arena_view.camera_zoom, 0.01)
		var visible_flashes: Array = effect_batch_system.visible_items(state.hit_flashes, state.camera_position, visible_world, 128.0)
		var visible_lines: Array = effect_batch_system.visible_items(state.effect_lines, state.camera_position, visible_world, 128.0)
		var visible_texts: Array = effect_batch_system.merge_damage_numbers(
			effect_batch_system.visible_items(state.floating_texts, state.camera_position, visible_world, 128.0)
		)
		_release_removed_effects("hit_flash", state.hit_flashes, visible_flashes)
		_release_removed_effects("effect_line", state.effect_lines, visible_lines)
		_release_removed_effects("damage_text", state.floating_texts, visible_texts)
		state.hit_flashes = visible_flashes
		state.effect_lines = visible_lines
		state.floating_texts = visible_texts

func _release_removed_effects(type_id: String, previous: Array, current: Array) -> void:
	for value in previous:
		var retained := false
		for candidate in current:
			if is_same(value, candidate):
				retained = true
				break
		if not retained:
			state.release_runtime(type_id, value)

func _finish_game(events: Array) -> void:
	pending_finish = true
	state.update_best_score(events, state.progress_saving_allowed())
	balance_log_system.flush(state)
	_handle_events(events)
	_play_sfx("gameover")
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
		"blessing_name": String(meta_system.blessings.get(state.selected_blessing_id, {}).get("name_ja", state.selected_blessing_id)),
		"blessing_effect": String(meta_system.blessings.get(state.selected_blessing_id, {}).get("effect_description_ja", "")),
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
		"passive_levels": state.passives.duplicate(true),
		"evolved_weapon_ids": state.evolved_weapons.keys(),
		"enemy_seen": state.enemy_seen,
		"weapon_kill_counts": state.weapon_kill_counts,
		"weapon_damage_by_id": state.weapon_damage_by_id,
		"weapon_pick_count_by_id": state.weapon_pick_counts,
		"passive_pick_count_by_id": state.passive_pick_counts,
		"weapon_evolved_by_id": state.evolved_weapons,
		"damage_by_category": state.damage_by_category,
		"boss_damage_by_weapon_id": state.boss_damage_by_weapon_id,
		"enemy_damage_by_weapon_id": state.enemy_damage_by_weapon_id,
		"healing_by_source": state.healing_by_source,
		"currency_gain_by_source": state.currency_gain_by_source,
		"evolution_time_by_weapon_id": state.evolution_time_by_weapon_id,
		"disabled_weapons": state.disabled_weapon_ids,
		"disabled_passives": state.disabled_passive_ids,
		"active_synergies": state.active_synergies.keys(),
		"synergy_history": state.active_synergy_history,
		"melee_rush_kills": state.melee_rush_kills,
		"shock_explosions": state.shock_explosions,
		"field_drops_collected": state.field_drops_collected,
		"field_equipment_collected": state.field_equipment_collected,
		"global_gem_collections": state.global_gem_collections,
		"global_gem_collection_batches": state.global_gem_collection_batches,
		"global_gem_collection_exp": state.global_gem_collection_exp,
		"global_gem_collection_last_metrics": state.global_gem_collection_last_metrics,
		"gems_collected_by_magnet": state.gems_collected_by_magnet,
		"gems_collected_by_drone": state.gems_collected_by_drone,
		"gems_collected_by_passive": state.gems_collected_by_passive,
		"magnet_ore_collected": state.magnet_ore_collected_run,
		"character_evolved": state.character_evolved,
		"character_evolution_name": state.character_evolution_name,
		"character_evolution_time": state.character_evolution_time,
		"character_evolution_contribution": state.character_evolution_contribution,
		"debug_exp_multiplier": state.debug_exp_multiplier,
		"allow_debug_progress": state.allow_debug_progress,
		"debug_progress_blocked": not state.progress_saving_allowed(),
		"reward_room_pickups": state.reward_room_pickups,
		"field_over_cap_pickups": state.field_over_cap_pickups,
		"selection_skip_rewards": state.selection_skip_rewards,
		"selection_rerolls_used": state.selection_rerolls_used,
		"selection_seals_used": state.selection_seals_used,
		"run_sealed_history": state.run_sealed_history,
		"field_gimmicks_triggered": state.field_gimmicks_triggered,
		"dynamic_drops_spawned": state.dynamic_drops_spawned,
		"field_drop_respawns_spawned": state.field_drop_respawns_spawned,
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
		"v2_peak_momentum_tier": state.v2_peak_momentum_tier,
		"v2_momentum_triggers": state.v2_momentum_triggers,
		"v2_momentum_active_time_total": state.v2_momentum_active_time_total,
		"v2_momentum_score_base": state.v2_momentum_score_base,
		"v2_momentum_score_bonus": state.v2_momentum_score_bonus,
		"v2_momentum_weighted_multiplier": state.v2_momentum_weighted_multiplier_sum / maxf(0.001, state.v2_momentum_weighted_time),
		"v2_momentum_trigger_counts": state.v2_momentum_trigger_counts.duplicate(true),
		"v2_momentum_main_trigger": v2_momentum_system.most_common_trigger(state),
		"v2_momentum_suppressed_duplicates": state.v2_momentum_suppressed_duplicates,
		"v2_best_kill_streak": state.v2_best_kill_streak,
		"v2_no_damage_best": state.v2_no_damage_best,
		"v2_momentum_history": state.v2_momentum_history.duplicate(true),
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

func _build_safe_play_bars(viewport_size: Vector2, play_rect: Rect2) -> void:
	safe_play_left_bar = ColorRect.new()
	safe_play_right_bar = ColorRect.new()
	for bar in [safe_play_left_bar, safe_play_right_bar]:
		bar.color = Color(0.0, 0.0, 0.0, 1.0)
		bar.mouse_filter = Control.MOUSE_FILTER_STOP
		bar.visible = false
		add_child(bar)
	if input_mode.is_ios_touch() and bool(runtime_settings.get("notch_protection", true)):
		notch_letterbox_system.apply_to_color_rects(safe_play_left_bar, safe_play_right_bar, viewport_size, play_rect)

func _build_pause_ui() -> void:
	var safe_margin = float(state.ui_layout_defs.get("safe_margin", 24.0))
	var viewport_size := get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	var mobile_safe: Rect2 = _runtime_safe_rect(viewport_size, float(runtime_settings.get("safe_area_margin", 0.0)))
	pause_backdrop = ColorRect.new()
	pause_backdrop.visible = false
	pause_backdrop.color = Color(0.005, 0.009, 0.018, 0.78)
	pause_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(pause_backdrop)
	pause_overlay = PanelContainer.new()
	pause_overlay.visible = false
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.offset_left = mobile_safe.position.x if input_mode.is_touch_mode() else safe_margin * 2.0
	pause_overlay.offset_right = -(viewport_size.x - mobile_safe.end.x) if input_mode.is_touch_mode() else -safe_margin * 2.0
	pause_overlay.offset_top = mobile_safe.position.y if input_mode.is_touch_mode() else safe_margin * 1.6
	pause_overlay.offset_bottom = -(viewport_size.y - mobile_safe.end.y) if input_mode.is_touch_mode() else -safe_margin * 1.6
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
	pause_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	pause_title_label.custom_minimum_size.x = 0 if input_mode.is_touch_mode() else 700
	pause_title_label.add_theme_font_size_override("font_size", 26 if input_mode.is_touch_mode() else 30)
	pause_title_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	root.add_child(pause_title_label)
	var body: BoxContainer = VBoxContainer.new() if input_mode.is_touch_mode() else HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)
	var tabs: Container = HBoxContainer.new() if input_mode.is_touch_mode() else VBoxContainer.new()
	tabs.custom_minimum_size.x = 0 if input_mode.is_touch_mode() else float(state.ui_layout_defs.get("pause_tab_width", 178.0))
	tabs.add_theme_constant_override("separation", 6)
	if not input_mode.is_touch_mode():
		body.add_child(tabs)
	pause_tab_buttons = []
	for i in range(pause_tabs.size()):
		var button = CrystalButtonScript.new()
		var tab_text: String = pause_tabs[i] if input_mode.is_touch_mode() else "%d  %s" % [i + 1, pause_tabs[i]]
		button.setup(tab_text, Color(0.42, 0.82, 1.0), Vector2(132 if input_mode.is_touch_mode() else float(state.ui_layout_defs.get("pause_tab_width", 178.0)), 56 if input_mode.is_touch_mode() else 42))
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER if input_mode.is_touch_mode() else HORIZONTAL_ALIGNMENT_LEFT
		var index = i
		button.pressed.connect(func(): set_pause_tab(index))
		tabs.add_child(button)
		pause_tab_buttons.append(button)
	pause_content_scroll = ScrollContainer.new()
	pause_content_scroll.name = "PauseContentScroll"
	ui_layout_fix_system.prepare_scroll(pause_content_scroll)
	pause_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(pause_content_scroll)
	if input_mode.is_touch_mode():
		mobile_scroll_system.register_scroll(pause_content_scroll, MobileScrollSystemScript.AXIS_VERTICAL)
	pause_content = Label.new()
	pause_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pause_content.custom_minimum_size.x = float(state.ui_layout_defs.get("pause_content_min_width", 520.0))
	pause_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_content.add_theme_font_size_override("font_size", 18)
	pause_content.add_theme_color_override("font_color", Color(0.86, 0.92, 0.98))
	pause_content_scroll.add_child(pause_content)
	var summary_panel = PanelContainer.new()
	summary_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	summary_panel.custom_minimum_size.x = 0 if input_mode.is_touch_mode() else float(state.ui_layout_defs.get("pause_summary_width", 286.0))
	summary_panel.visible = not input_mode.is_touch_mode()
	summary_panel.add_theme_stylebox_override("panel", _hud_panel_style(Color(1.0, 0.82, 0.34)))
	body.add_child(summary_panel)
	pause_summary = Label.new()
	pause_summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pause_summary.custom_minimum_size.x = float(state.ui_layout_defs.get("pause_summary_width", 286.0)) - 24.0
	pause_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_summary.add_theme_font_size_override("font_size", 16)
	pause_summary.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	summary_panel.add_child(pause_summary)
	if input_mode.is_touch_mode():
		pause_tab_scroll = ScrollContainer.new()
		pause_tab_scroll.name = "PauseTabScroll"
		pause_tab_scroll.custom_minimum_size.y = 64
		pause_tab_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pause_tab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		pause_tab_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		root.add_child(pause_tab_scroll)
		pause_tab_scroll.add_child(tabs)
		mobile_scroll_system.register_scroll(pause_tab_scroll, MobileScrollSystemScript.AXIS_HORIZONTAL)
	pause_action_row = GridContainer.new() if input_mode.is_touch_mode() else HBoxContainer.new()
	if pause_action_row is GridContainer:
		(pause_action_row as GridContainer).columns = 3
	else:
		pause_action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	pause_action_row.add_theme_constant_override("separation", 10)
	root.add_child(pause_action_row)
	pause_dialog_layer = Control.new()
	pause_dialog_layer.visible = false
	pause_dialog_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_dialog_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(pause_dialog_layer)
	var dialog_backdrop := ColorRect.new()
	dialog_backdrop.color = Color(0.0, 0.0, 0.0, 0.72)
	dialog_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_dialog_layer.add_child(dialog_backdrop)
	pause_confirm_dialog = ConfirmDialogScript.new()
	pause_confirm_dialog.visible = false
	pause_confirm_dialog.set_anchors_preset(Control.PRESET_CENTER)
	pause_confirm_dialog.offset_left = -250
	pause_confirm_dialog.offset_right = 250
	pause_confirm_dialog.offset_top = -120
	pause_confirm_dialog.offset_bottom = 120
	pause_confirm_dialog.setup("タイトルへ戻りますか？", "現在のランは終了します。誤操作防止のため確認してください。", "タイトルへ", "キャンセル", input_mode.is_touch_mode())
	pause_confirm_dialog.confirmed.connect(func(): title_requested.emit())
	pause_confirm_dialog.canceled.connect(_hide_title_confirm)
	pause_dialog_layer.add_child(pause_confirm_dialog)

func _toggle_pause() -> void:
	state.paused = not state.paused
	map_pause_system.set_reason(state, MapPauseSystemScript.REASON_MENU, state.paused)
	pause_overlay.visible = state.paused
	pause_backdrop.visible = state.paused
	touch_control_system.set_speed_pressed(false)
	_hide_title_confirm()
	if arena_view != null:
		ios_background_throttle_system.set_branch_active(arena_view, not state.paused)
	if state.paused:
		pause_actions_signature = ""
		pause_ui_signature = ""
		_refresh_pause_ui()
	else:
		message_label.text = "左下をドラッグして移動　右下でスキャン・回収・倍速" if input_mode.is_touch_mode() else "移動 WASD/矢印　F/右クリック スキャン　R ドローン　Esc ポーズ"
	_refresh_touch_controls()

func _build_touch_controls(ui_scale: float) -> void:
	touch_root = Control.new()
	touch_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	touch_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(touch_root)
	var viewport_size := get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	var layout: Dictionary = mobile_layout
	if layout.is_empty():
		var safe_rect: Rect2 = _runtime_safe_rect(viewport_size, float(runtime_settings.get("safe_area_margin", 16.0)))
		var layout_settings := runtime_settings.duplicate(true)
		layout_settings["_device_size"] = _layout_device_size()
		layout = mobile_hud_layout_system.layout(viewport_size, safe_rect, layout_settings)
	var joystick_rect: Rect2 = layout["joystick_rect"]
	virtual_joystick = VirtualJoystickScript.new()
	virtual_joystick.set_anchors_preset(Control.PRESET_FULL_RECT)
	virtual_joystick.configure(
		touch_control_system.touch_button_opacity,
		true,
		float(layout.get("joystick_visual_extent", 196.0)),
		float(layout.get("joystick_knob_extent", 82.0))
	)
	var joystick_safe_rect: Rect2 = _runtime_safe_rect(viewport_size, float(runtime_settings.get("safe_area_margin", 16.0)))
	virtual_joystick.configure_anywhere(viewport_size, joystick_safe_rect, runtime_settings, joystick_rect, [
		layout["actions_rect"], layout["pause_rect"], layout["log_rect"], layout["map_rect"], layout["minimap_rect"]
	])
	virtual_joystick.direction_changed.connect(func(value: Vector2):
		touch_direction = value
		touch_control_system.set_move_vector(value)
	)
	touch_root.add_child(virtual_joystick)

	var button_extent := float(layout["button_extent"])
	var actions_rect: Rect2 = layout["actions_rect"]
	var buttons = GridContainer.new()
	buttons.columns = 2
	_place_touch_rect(buttons, actions_rect)
	buttons.add_theme_constant_override("h_separation", 10)
	buttons.add_theme_constant_override("v_separation", 10)
	touch_root.add_child(buttons)

	touch_scan_button = TouchActionButtonScript.new()
	touch_scan_button.setup("action_scan", "スキャン", Color(0.42, 0.88, 1.0), button_extent, false, touch_control_system.touch_button_opacity)
	touch_scan_button.action_started.connect(_on_touch_action_started)
	buttons.add_child(touch_scan_button)
	touch_drone_button = TouchActionButtonScript.new()
	touch_drone_button.setup("action_drone", "回収", Color(0.50, 1.0, 0.70), button_extent, false, touch_control_system.touch_button_opacity)
	touch_drone_button.action_started.connect(_on_touch_action_started)
	buttons.add_child(touch_drone_button)
	touch_speed_button = TouchActionButtonScript.new()
	touch_speed_button.setup("action_speed_hold", "倍速\n長押し", Color(1.0, 0.82, 0.28), button_extent, true, touch_control_system.touch_button_opacity)
	touch_speed_button.action_started.connect(_on_touch_action_started)
	touch_speed_button.action_ended.connect(_on_touch_action_ended)
	buttons.add_child(touch_speed_button)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(button_extent, button_extent)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buttons.add_child(spacer)

	touch_pause_button = TouchActionButtonScript.new()
	touch_pause_button.setup("action_pause", "ポーズ", Color(1.0, 0.46, 0.42), float(layout["pause_rect"].size.x), false, touch_control_system.touch_button_opacity)
	_place_touch_rect(touch_pause_button, layout["pause_rect"])
	touch_pause_button.action_started.connect(_on_touch_action_started)
	touch_root.add_child(touch_pause_button)
	touch_log_button = TouchActionButtonScript.new()
	touch_log_button.setup("action_open_log", "ログ", Color(0.62, 0.78, 1.0), float(layout["log_rect"].size.x), false, touch_control_system.touch_button_opacity)
	_place_touch_rect(touch_log_button, layout["log_rect"])
	touch_log_button.action_started.connect(_on_touch_action_started)
	touch_root.add_child(touch_log_button)
	touch_map_button = TouchActionButtonScript.new()
	touch_map_button.setup("action_open_map", "マップ", Color(0.58, 1.0, 0.76), float(layout["map_rect"].size.x), false, touch_control_system.touch_button_opacity)
	_place_touch_rect(touch_map_button, layout["map_rect"])
	touch_map_button.action_started.connect(_on_touch_action_started)
	touch_root.add_child(touch_map_button)

	touch_chest_button = TouchActionButtonScript.new()
	touch_chest_button.setup("action_confirm", "報酬を確認", Color(1.0, 0.82, 0.28), 190.0, false, 0.94)
	touch_chest_button.set_anchors_preset(Control.PRESET_CENTER)
	touch_chest_button.offset_left = -120
	touch_chest_button.offset_right = 120
	touch_chest_button.offset_top = 70
	touch_chest_button.offset_bottom = 132
	touch_chest_button.action_started.connect(_on_touch_action_started)
	touch_root.add_child(touch_chest_button)
	_refresh_touch_controls()

func _refresh_touch_controls() -> void:
	if touch_root == null:
		return
	var show_touch = touch_control_system.should_show()
	touch_root.visible = show_touch and not state.paused
	if not show_touch or state.paused:
		touch_direction = Vector2.ZERO
		touch_control_system.set_speed_pressed(false)
	if not show_touch:
		return
	var action_blocked = map_expanded or state.paused or state.level_up_pending or state.chest_pending or state.rune_contract_pending or state.game_over
	virtual_joystick.visible = touch_control_system.should_show_joystick() and not action_blocked
	virtual_joystick.set_enabled(virtual_joystick.visible)
	touch_scan_button.visible = not action_blocked
	touch_drone_button.visible = not action_blocked
	touch_speed_button.visible = not action_blocked
	touch_drone_button.set_ready_state(state.recall_drone_ready)
	touch_scan_button.set_active_state(not state.nearby_field_help.is_empty())
	touch_speed_button.text = "×%.1f" % speed_hold_system.speed_multiplier if speed_active else "倍速\n長押し"
	touch_pause_button.text = "再開" if state.paused else "ポーズ"
	touch_map_button.text = "閉じる" if map_expanded else "マップ"
	touch_log_button.visible = not state.game_over
	touch_map_button.visible = not state.game_over
	touch_chest_button.visible = state.chest_pending

func _place_touch_rect(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.end.x
	control.offset_bottom = rect.end.y

func _on_touch_action_started(action: String) -> void:
	touch_control_system.set_action_pressed(action, true, false)
	match action:
		"action_scan":
			_scan_field_target()
		"action_drone":
			_activate_recall_drone()
		"action_speed_hold":
			touch_control_system.set_speed_pressed(true)
		"action_pause":
			_toggle_pause()
		"action_open_log":
			if not state.paused:
				_toggle_pause()
			set_pause_tab(8)
		"action_open_map":
			_toggle_expanded_map()
		"action_confirm":
			if state.chest_pending:
				state.chest_pending = false
				state.chest_timer = 0.0
				message_label.text = state.chest_message

func _on_touch_action_ended(action: String) -> void:
	touch_control_system.set_action_pressed(action, false, false)
	if action == "action_speed_hold":
		touch_control_system.set_speed_pressed(false)

func _toggle_expanded_map() -> void:
	if not bool(mobile_layout.get("map_tap_expand", true)):
		return
	map_expanded = not map_expanded
	map_pause_system.set_reason(state, MapPauseSystemScript.REASON_MAP, map_expanded)
	arena_view.set_map_expanded(map_expanded)
	if goal_panel != null:
		goal_panel.visible = not map_expanded
	if notification_panel != null:
		notification_panel.visible = not map_expanded and notification_label.text != ""
	if message_label != null:
		message_label.visible = not map_expanded
	_refresh_touch_controls()

func _layout_device_size() -> Vector2:
	var viewport_size := get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	if not input_mode.is_ios_touch():
		return viewport_size
	var screen_size := Vector2(DisplayServer.screen_get_size())
	if screen_size.x <= 0.0 or screen_size.y <= 0.0:
		return viewport_size
	return Vector2(maxf(screen_size.x, screen_size.y), minf(screen_size.x, screen_size.y))

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
	var content_text := "%s\n\n%s" % [pause_tabs[pause_tab_index], pause_tab_text()]
	var signature := "%d:%s:%s:%s" % [pause_tab_index, content_text, str(state.auto_infinite_enabled), str(state.auto_recall_drone_enabled)]
	if not ios_energy_optimizer.should_update("pause", signature, "pause_update_interval", 0.20):
		return
	_set_label_text(pause_content, content_text)
	_set_label_text(pause_title_label, "ポーズ　%s　%s" % [JaText.format_time(state.elapsed_seconds), state.selected_character_name])
	_set_label_text(pause_summary, _pause_summary_text())
	ios_energy_optimizer.mark_ui_rebuild()
	for i in range(pause_tab_buttons.size()):
		var button: Button = pause_tab_buttons[i]
		var tab_text: String = pause_tabs[i] if input_mode.is_touch_mode() else "%d  %s" % [i + 1, pause_tabs[i]]
		button.setup(tab_text, Color(1.0, 0.82, 0.34) if i == pause_tab_index else Color(0.42, 0.82, 1.0), Vector2(132 if input_mode.is_touch_mode() else float(state.ui_layout_defs.get("pause_tab_width", 178.0)), 56 if input_mode.is_touch_mode() else 42))
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER if input_mode.is_touch_mode() else HORIZONTAL_ALIGNMENT_LEFT
	_refresh_pause_actions()

func _refresh_pause_actions() -> void:
	if pause_action_row == null:
		return
	var signature := "%d:%s:%s" % [pause_tab_index, str(state.auto_infinite_enabled), str(state.auto_recall_drone_enabled)]
	if signature == pause_actions_signature:
		return
	pause_actions_signature = signature
	for child in pause_action_row.get_children():
		child.queue_free()
	if pause_tab_index == 7:
		var auto_button = CrystalButtonScript.new()
		auto_button.setup("無限強化 %s" % ("ON" if state.auto_infinite_enabled else "OFF"), Color(0.52, 1.0, 0.72), Vector2(180, 56 if input_mode.is_touch_mode() else 42))
		auto_button.pressed.connect(func():
			state.auto_infinite_enabled = not state.auto_infinite_enabled
			SaveSystem.new().update_settings({"auto_infinite": state.auto_infinite_enabled})
			_refresh_pause_ui()
		)
		pause_action_row.add_child(auto_button)
		var recall_button = CrystalButtonScript.new()
		recall_button.setup("自動ドローン %s" % ("ON" if state.auto_recall_drone_enabled else "OFF"), Color(0.52, 1.0, 0.72), Vector2(180, 56 if input_mode.is_touch_mode() else 42))
		recall_button.pressed.connect(func():
			state.auto_recall_drone_enabled = not state.auto_recall_drone_enabled
			SaveSystem.new().update_settings({"auto_recall_drone": state.auto_recall_drone_enabled})
			_refresh_pause_ui()
		)
		pause_action_row.add_child(recall_button)
	var settings_button = CrystalButtonScript.new()
	settings_button.setup("設定", Color(0.52, 1.0, 0.72), Vector2(160, 56 if input_mode.is_touch_mode() else 42))
	settings_button.pressed.connect(func(): set_pause_tab(7))
	pause_action_row.add_child(settings_button)
	var title_button = CrystalButtonScript.new()
	title_button.setup("タイトルへ戻る", Color(1.0, 0.34, 0.42), Vector2(180, 56 if input_mode.is_touch_mode() else 42), true)
	title_button.pressed.connect(_show_title_confirm)
	pause_action_row.add_child(title_button)
	var resume_button = CrystalButtonScript.new()
	resume_button.setup("ゲームへ戻る", Color(0.42, 0.82, 1.0), Vector2(180, 64 if input_mode.is_touch_mode() else 42))
	resume_button.pressed.connect(_toggle_pause)
	pause_action_row.add_child(resume_button)

func _show_title_confirm() -> void:
	if pause_confirm_dialog != null and pause_dialog_layer != null:
		pause_dialog_layer.show()
		pause_confirm_dialog.show()

func _hide_title_confirm() -> void:
	if pause_confirm_dialog != null:
		pause_confirm_dialog.hide()
	if pause_dialog_layer != null:
		pause_dialog_layer.hide()

func _pause_status_text() -> String:
	var blessing_data: Dictionary = meta_system.blessings.get(state.selected_blessing_id, {})
	return "\n".join([
		"キャラ：%s" % state.selected_character_name,
		"HP：%d / %d　Lv：%d　EXP：%d%%" % [state.hp, state.max_hp, state.level, int(exp_bar.value)],
		"生存時間：%s　撃破：%s　スコア：%s" % [JaText.format_time(state.elapsed_seconds), JaText.format_int(state.kills), JaText.format_int(state.score)],
		"攻撃倍率：%.2f　CD倍率：%.2f　範囲倍率：%.2f　移動速度：%.1f　吸収範囲：%.1f" % [state.get_damage_multiplier(), state.get_cooldown_multiplier(), state.get_area_multiplier(), state.get_move_speed(), state.get_magnet_radius()],
		"ジェム価値：%.2f　スコア倍率：%.2f　現在バイオーム：%s" % [state.get_gem_value_multiplier(), state.get_score_multiplier(), state.current_biome_name],
		"イベント：%s　契約数：%d　進化武器：%d" % [String(state.active_field_event.get("name_ja", "なし")), state.rune_contracts.size(), state.evolved_weapon_count],
		state.active_synergy_label(),
		"探索：ランク%s / %d点 / 最大チェーンx%d" % [state.exploration_rank, state.exploration_score, state.exploration_chain_max],
		"発見：ドロップ%d　ギミック%d　動的出現%d" % [state.field_drops_collected, state.field_gimmicks_triggered, state.dynamic_drops_spawned],
		"祝福：%s" % String(blessing_data.get("name_ja", state.selected_blessing_id)),
		String(blessing_data.get("effect_description_ja", blessing_data.get("description_ja", ""))),
		"数値：%s" % " / ".join(blessing_data.get("numeric_effects_ja", []))
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
	lines.append("キャラクター進化")
	lines.append_array(character_evolution_system.run_condition_lines(state))
	lines.append("")
	lines.append("武器進化")
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
		"スキャンボタンで、効果・対処・報酬・危険度を確認できます。" if input_mode.is_touch_mode() else "Fキーまたは右クリックで、効果・対処・報酬・危険度をスキャンできます。",
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
	if input_mode.is_touch_mode():
		return "\n".join([
			"無限強化だけ自動選択 %s" % ("ON" if state.auto_infinite_enabled else "OFF"),
			"自動回収ドローン %s" % ("ON" if state.auto_recall_drone_enabled else "OFF"),
			"倍速ボタン長押し：%s / x%.1f" % ["ON" if bool(settings.get("speed_hold_enabled", true)) else "OFF", float(settings.get("speed_multiplier", 2.0))],
			"通知ログ：%s　武器HUD：%s　パッシブHUD：%s" % ["ON" if bool(settings.get("notification_log_enabled", true)) else "OFF", "ON" if bool(settings.get("weapon_hud_enabled", true)) else "OFF", "ON" if bool(settings.get("passive_hud_enabled", true)) else "OFF"],
			"詳細設定はタイトル画面の設定で変更できます。",
			"再開ボタンでゲームへ戻る"
		])
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
	var blessing_data: Dictionary = meta_system.blessings.get(state.selected_blessing_id, {})
	if not state.current_goals.is_empty():
		goal_text = String(state.current_goals[0].get("title", goal_text))
		goal_reason = String(state.current_goals[0].get("reason", goal_reason))
	return "\n".join([
		"現在の重要情報",
		"",
		"HP %d / %d" % [state.hp, state.max_hp],
		"生存 %s" % JaText.format_time(state.elapsed_seconds),
		"ビルド：%s" % state.active_synergy_label(),
		"祝福：%s" % String(blessing_data.get("name_ja", state.selected_blessing_id)),
		String(blessing_data.get("effect_description_ja", blessing_data.get("description_ja", ""))),
		"進化可能：%d武器" % evolution_ready,
		"キャラ進化：%s" % (state.character_evolution_name if state.character_evolved else state.character_evolution_progress_text),
		"全ジェム回収：%d回 / 磁石%d / ドローン%d" % [state.global_gem_collections, state.gems_collected_by_magnet, state.gems_collected_by_drone],
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
		if not state.evolution_timing_ready():
			return "進化待機中（%s）" % _evolution_wait_text()
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
		if not state.evolution_timing_ready():
			return _evolution_wait_text()
		return "なし。宝箱または進化核で進化可能！"
	return " / ".join(parts)

func _evolution_wait_text() -> String:
	var remaining = 0.0
	if state.evolved_weapon_count <= 0:
		remaining = float(state.balance_data.get("first_evolution_seconds", 300.0)) - state.elapsed_seconds
	else:
		remaining = float(state.balance_data.get("evolution_cooldown_seconds", 180.0)) - (state.elapsed_seconds - state.last_evolution_seconds)
	var seconds = maxi(0, int(ceil(remaining)))
	return "進化解禁まで %d:%02d" % [int(seconds / 60), seconds % 60]

func _overclock_label(weapon_id: String) -> String:
	if not state.overclocks.has(weapon_id):
		return "なし"
	return ", ".join(state.overclocks[weapon_id])
