extends Control

const GameScene := preload("res://scenes/Game.tscn")
const ResultScene := preload("res://scenes/Result.tscn")
const JaText := preload("res://scripts/ui/JaText.gd")
const MetaProgressionSystemScript := preload("res://scripts/systems/MetaProgressionSystem.gd")
const CrystalButtonScript := preload("res://scripts/ui/components/CrystalButton.gd")
const CrystalCardScript := preload("res://scripts/ui/components/CrystalCard.gd")
const CharacterCardScript := preload("res://scripts/ui/components/CharacterCard.gd")
const ToggleOptionScript := preload("res://scripts/ui/components/ToggleOption.gd")
const SettingsSliderScript := preload("res://scripts/ui/components/SettingsSlider.gd")
const AchievementCardScript := preload("res://scripts/ui/components/AchievementCard.gd")
const CollectionCardScript := preload("res://scripts/ui/components/CollectionCard.gd")
const UiLayoutFixSystemScript := preload("res://scripts/systems/UiLayoutFixSystem.gd")
const CurrencySinkSystemScript := preload("res://scripts/systems/CurrencySinkSystem.gd")
const ShopCategorySystemScript := preload("res://scripts/systems/ShopCategorySystem.gd")
const ShopRerollSystemScript := preload("res://scripts/systems/ShopRerollSystem.gd")
const CollectionFilterSystemScript := preload("res://scripts/systems/CollectionFilterSystem.gd")
const InputModeSystemScript := preload("res://scripts/systems/InputModeSystem.gd")
const MobileSafeAreaSystemScript := preload("res://scripts/systems/MobileSafeAreaSystem.gd")
const MobileUiScaleSystemScript := preload("res://scripts/systems/MobileUiScaleSystem.gd")
const MobileScrollSystemScript := preload("res://scripts/systems/MobileScrollSystem.gd")
const LoadoutDisableSystemScript := preload("res://scripts/systems/LoadoutDisableSystem.gd")
const AchievementProgressSystemScript := preload("res://scripts/systems/AchievementProgressSystem.gd")
const ConfirmDialogScript := preload("res://scripts/ui/components/ConfirmDialog.gd")
const UiNavigation := preload("res://scripts/ui/UiNavigation.gd")

var current_screen: Node = null
var screen_mode := "title"
var title_visible := false
var help_visible := false
var help_start_after := true
var auto_infinite_enabled := true
var auto_recall_enabled := false
var save_system := SaveSystem.new()
var meta_system = MetaProgressionSystemScript.new()
var ui_layout_fix = UiLayoutFixSystemScript.new()
var currency_sink_system = CurrencySinkSystemScript.new()
var shop_category_system = ShopCategorySystemScript.new()
var shop_reroll_system = ShopRerollSystemScript.new()
var collection_filter_system = CollectionFilterSystemScript.new()
var loadout_disable_system = LoadoutDisableSystemScript.new()
var achievement_progress_system = AchievementProgressSystemScript.new()
var save_data: Dictionary = {}
var selected_character_id := "noah"
var selected_blessing_id := "attack"
var character_cursor := 0
var blessing_cursor := 0
var shop_message := ""
var shop_category_index := 0
var reset_input: LineEdit
var reset_message := ""
var seed_input: LineEdit
var collection_tab_index := 0
var collection_filter_index := 0
var collection_sort_index := 0
var quest_filter_index := 0
var collection_tabs := ["characters", "weapons", "passives", "blessings", "evolutions", "enemies", "bosses", "field_drops", "field_gimmicks", "field_events"]
var collection_tab_names := ["キャラ", "武器", "パッシブ", "祝福", "進化", "敵", "ボス", "ドロップ", "ギミック", "イベント"]
var blessing_expanded := false
var loadout_kind := "weapon"
var loadout_filter := "all"
var loadout_message := ""
var touch_tutorial_page := 0
var input_mode = InputModeSystemScript.new()
var mobile_safe_area = MobileSafeAreaSystemScript.new()
var mobile_ui_scale = MobileUiScaleSystemScript.new()
var mobile_scroll_system
var settings_scroll: ScrollContainer
var settings_section_nodes: Dictionary = {}

func _ready() -> void:
	_sync_from_save()
	_configure_mobile_viewport()
	mobile_scroll_system = MobileScrollSystemScript.new()
	add_child(mobile_scroll_system)
	_configure_mobile_scroll()
	show_title()

func _unhandled_input(event: InputEvent) -> void:
	if input_mode.is_ios_touch():
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match screen_mode:
		"title":
			_handle_title_key(event.keycode)
		"help":
			if event.keycode == KEY_ENTER:
				accept_help()
			elif event.keycode == KEY_H or event.keycode == KEY_ESCAPE:
				show_title()
		"characters":
			_handle_character_key(event.keycode)
		"shop":
			if event.keycode == KEY_LEFT:
				shop_category_index = posmod(shop_category_index - 1, shop_category_system.category_ids().size())
				show_shop()
			elif event.keycode == KEY_RIGHT:
				shop_category_index = posmod(shop_category_index + 1, shop_category_system.category_ids().size())
				show_shop()
			elif event.keycode == KEY_ESCAPE or event.keycode == KEY_U:
				show_title()
		"collection":
			_handle_collection_key(event.keycode)
		"quests":
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_A:
				show_title()
		"settings":
			_handle_settings_key(event.keycode)
		"reset":
			if event.keycode == KEY_ESCAPE:
				show_settings()

func _handle_title_key(keycode: int) -> void:
	match keycode:
		KEY_ENTER:
			request_start()
		KEY_C:
			show_character_select()
		KEY_U:
			show_shop()
		KEY_L:
			show_collection()
		KEY_A:
			show_quests()
		KEY_S:
			show_settings()
		KEY_R:
			show_reset()
		KEY_H:
			show_help(false)
		KEY_I:
			_toggle_auto_infinite()
			show_title()
		KEY_ESCAPE:
			get_tree().quit()

func _handle_character_key(keycode: int) -> void:
	var ids := meta_system.character_ids()
	var blessings := meta_system.unlocked_blessings(save_data)
	if keycode == KEY_UP:
		character_cursor = posmod(character_cursor - 1, maxi(ids.size(), 1))
		show_character_select()
	elif keycode == KEY_DOWN:
		character_cursor = posmod(character_cursor + 1, maxi(ids.size(), 1))
		show_character_select()
	elif keycode == KEY_LEFT:
		blessing_cursor = posmod(blessing_cursor - 1, maxi(blessings.size(), 1))
		_select_blessing(String(blessings[blessing_cursor]))
	elif keycode == KEY_RIGHT:
		blessing_cursor = posmod(blessing_cursor + 1, maxi(blessings.size(), 1))
		_select_blessing(String(blessings[blessing_cursor]))
	elif keycode == KEY_ENTER and ids.size() > 0:
		_character_card_clicked(String(ids[character_cursor]))
	elif keycode == KEY_ESCAPE or keycode == KEY_C:
		show_title()

func _handle_collection_key(keycode: int) -> void:
	if keycode == KEY_LEFT:
		collection_tab_index = posmod(collection_tab_index - 1, collection_tabs.size())
		show_collection()
	elif keycode == KEY_RIGHT:
		collection_tab_index = posmod(collection_tab_index + 1, collection_tabs.size())
		show_collection()
	elif keycode == KEY_ESCAPE or keycode == KEY_L:
		show_title()

func _handle_settings_key(keycode: int) -> void:
	match keycode:
		KEY_I:
			_toggle_auto_infinite()
			show_settings()
		KEY_D:
			_update_setting("auto_recall_drone", not auto_recall_enabled)
			show_settings()
		KEY_R:
			show_reset()
		KEY_ESCAPE, KEY_S:
			show_title()

func show_title() -> void:
	_sync_from_save()
	_clear()
	screen_mode = "title"
	title_visible = true
	help_visible = false
	_add_background(Color(0.020, 0.026, 0.048))
	_draw_neon_background()

	var root := _page_box(54, 32, 54, 32)
	root.add_theme_constant_override("separation", 12)
	_add_label(root, JaText.TITLE, 36 if input_mode.is_touch_mode() else 42, Color(0.94, 0.98, 1.0))
	_add_label(root, JaText.SUBTITLE, 18 if input_mode.is_touch_mode() else 20, Color(0.68, 0.84, 1.0))
	if input_mode.is_touch_mode():
		_build_touch_title(root)
		return

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	root.add_child(body)

	var menu := VBoxContainer.new()
	menu.custom_minimum_size = Vector2(330, 0)
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.add_theme_constant_override("separation", 8)
	body.add_child(menu)
	_add_menu_button(menu, "開始", request_start, Color(0.52, 1.0, 1.0))
	_add_menu_button(menu, "キャラクター選択", show_character_select)
	_add_menu_button(menu, "解放 / 強化", show_shop, Color(1.0, 0.82, 0.28))
	_add_menu_button(menu, "武器・パッシブ管理", show_loadout, Color(0.58, 1.0, 0.74))
	_add_menu_button(menu, "図鑑", show_collection, Color(0.70, 0.86, 1.0))
	_add_menu_button(menu, "実績", show_quests, Color(0.48, 1.0, 0.66))
	_add_menu_button(menu, "設定", show_settings)
	_add_menu_button(menu, "セーブ初期化", show_reset, Color(1.0, 0.34, 0.42), true)
	_add_menu_button(menu, "遊び方", func(): show_help(false), Color(0.70, 0.78, 1.0))
	_add_menu_button(menu, "終了", func(): get_tree().quit(), Color(0.50, 0.58, 0.70))

	var info = CrystalCardScript.new()
	info.setup(Color(0.42, 0.92, 1.0), false)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(info)
	var info_box := VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 10)
	info.add_child(info_box)
	_add_label(info_box, "現在の遠征準備", 28, Color(0.96, 0.98, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(info_box, _title_status_text(), 19, Color(0.82, 0.92, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(info_box, _next_goal_text(), 19, Color(1.0, 0.86, 0.38), HORIZONTAL_ALIGNMENT_LEFT)
	var seed_text := String(save_data.get("settings", {}).get("seed_text", ""))
	_add_label(info_box, "シード：%s" % ("ランダム" if seed_text == "" else seed_text), 18, Color(0.74, 0.86, 0.96), HORIZONTAL_ALIGNMENT_LEFT)
	var input_help := "各ボタンをタップして選択できます。" if input_mode.is_touch_mode() else "マウスで開始/選択できます。Enter/C/U/L/A/S/R/H/I/Esc のキーボード操作も有効です。"
	_add_label(info_box, input_help, 17, Color(0.66, 0.76, 0.88), HORIZONTAL_ALIGNMENT_LEFT)

func _build_touch_title(root: VBoxContainer) -> void:
	var status = CrystalCardScript.new()
	status.setup(Color(0.42, 0.92, 1.0), false, Vector2(0, 92))
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(status)
	var status_box := VBoxContainer.new()
	status_box.add_theme_constant_override("separation", 4)
	status.add_child(status_box)
	_add_label(status_box, "現在の遠征準備", 24, Color(0.96, 0.98, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	var stats: Dictionary = save_data.get("stats", {})
	_add_label(
		status_box,
		"%s　クリスタル貨 %s　最高生存 %s" % [
			meta_system.display_name(selected_character_id, save_data),
			JaText.format_int(int(save_data.get("crystal_currency", 0))),
			JaText.format_time(float(stats.get("best_survival", 0.0)))
		],
		17,
		Color(0.82, 0.92, 1.0),
		HORIZONTAL_ALIGNMENT_LEFT
	)
	var primary := GridContainer.new()
	primary.columns = 2
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	primary.add_theme_constant_override("h_separation", 12)
	primary.add_theme_constant_override("v_separation", 12)
	root.add_child(primary)
	_add_menu_button(primary, "開始", request_start, Color(0.52, 1.0, 1.0))
	_add_menu_button(primary, "キャラクター選択", show_character_select)
	_add_menu_button(primary, "解放 / 強化", show_shop, Color(1.0, 0.82, 0.28))
	_add_menu_button(primary, "武器・パッシブ管理", show_loadout, Color(0.58, 1.0, 0.74))
	_add_menu_button(primary, "図鑑", show_collection, Color(0.70, 0.86, 1.0))
	_add_menu_button(primary, "実績", show_quests, Color(0.48, 1.0, 0.66))
	_add_menu_button(primary, "設定", show_settings)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)
	var help_button := _add_menu_button(footer, "遊び方", func(): show_help(false), Color(0.70, 0.78, 1.0))
	help_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var reset_button := _add_menu_button(footer, "データ初期化", show_reset, Color(1.0, 0.34, 0.42), true)
	reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func request_start() -> void:
	var settings: Dictionary = save_data.get("settings", {})
	var tutorial_seen := bool(settings.get("touch_tutorial_seen", false))
	if save_system.load_help_seen() and (not input_mode.is_touch_mode() or tutorial_seen):
		start_game()
	else:
		touch_tutorial_page = 0
		show_help(true)

func show_help(start_after: bool = true) -> void:
	_clear()
	screen_mode = "help"
	title_visible = false
	help_visible = true
	help_start_after = start_after
	_add_background(Color(0.028, 0.038, 0.060))
	var root := _page_box(150, 54, 150, 54)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	if input_mode.is_touch_mode():
		var pages := [
			["1 / 3　移動", "左下をドラッグして移動", "res://assets/survivor/ui/touch_tutorial_move.svg"],
			["2 / 3　アクション", "右下ボタンでスキャン・回収・倍速", "res://assets/survivor/ui/touch_tutorial_actions.svg"],
			["3 / 3　選択", "カード全体をタップして選択", "res://assets/survivor/ui/touch_tutorial_cards.svg"]
		]
		touch_tutorial_page = clampi(touch_tutorial_page, 0, pages.size() - 1)
		var page: Array = pages[touch_tutorial_page]
		_add_label(root, String(page[0]), 36, Color(0.94, 0.98, 1.0))
		if ResourceLoader.exists(String(page[2])):
			var image := TextureRect.new()
			image.texture = load(String(page[2]))
			image.custom_minimum_size = Vector2(180, 180)
			image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			root.add_child(image)
		_add_label(root, String(page[1]), 24, Color(0.80, 0.88, 0.96))
	else:
		_add_label(root, "遊び方", 42, Color(0.94, 0.98, 1.0))
		_add_label(root, JaText.HELP_BODY, 20, Color(0.80, 0.88, 0.96))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	root.add_child(row)
	_add_menu_button(row, "スキップ", accept_help if help_start_after else show_title, Color(0.42, 0.82, 1.0))
	if input_mode.is_touch_mode() and touch_tutorial_page < 2:
		_add_menu_button(row, "次へ", func():
			touch_tutorial_page += 1
			show_help(help_start_after)
		, Color(0.52, 1.0, 1.0))
	else:
		_add_menu_button(row, "開始" if help_start_after else "閉じる", accept_help if help_start_after else show_title, Color(0.52, 1.0, 1.0))

func accept_help() -> void:
	save_system.save_help_seen(true)
	if input_mode.is_touch_mode():
		save_system.update_settings({"touch_tutorial_seen": true})
	if help_start_after:
		start_game()
	else:
		show_title()

func show_character_select() -> void:
	_sync_from_save()
	_clear()
	screen_mode = "characters"
	title_visible = false
	help_visible = false
	_add_background(Color(0.026, 0.034, 0.058))
	var root := _page_box(36, 24, 36, 30)
	var selected_name = meta_system.display_name(selected_character_id, save_data)
	var blessing_name = String(meta_system.blessings.get(selected_blessing_id, {}).get("name_ja", "攻撃の祝福"))
	_add_top_bar(root, "キャラクター選択", "クリスタル貨：%s　現在：%s / %s" % [JaText.format_int(int(save_data.get("crystal_currency", 0))), selected_name, blessing_name], show_title)
	if input_mode.is_touch_mode() and not _is_tablet_layout():
		_build_phone_character_select(root, selected_name)
	elif input_mode.is_touch_mode():
		_build_tablet_character_select(root, selected_name)
	else:
		_build_desktop_character_select(root, selected_name)

func _build_phone_character_select(root: VBoxContainer, selected_name: String) -> void:
	var metrics := mobile_ui_scale.metrics(_layout_device_size())
	var selected_data := meta_system.character_data(selected_character_id)
	var detail = CrystalCardScript.new()
	detail.setup(Color(1.0, 0.82, 0.34), false, Vector2(0, 96))
	detail.custom_minimum_size.y = 96
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(detail)
	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 3)
	detail.add_child(detail_box)
	_add_label(detail_box, "%s　%s" % [selected_name, String(selected_data.get("role_ja", ""))], 24, Color(1.0, 0.88, 0.42), HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(
		detail_box,
		"初期武器：%s　特性：%s" % [_weapon_name(String(selected_data.get("initial_weapon", ""))), String(selected_data.get("trait_ja", ""))],
		16,
		Color(0.86, 0.93, 0.98),
		HORIZONTAL_ALIGNMENT_LEFT
	)
	var selected_blessing: Dictionary = meta_system.blessings.get(selected_blessing_id, {})
	_add_label(
		detail_box,
		"祝福：%s　数値：%s　推奨：%s" % [
			String(selected_blessing.get("name_ja", selected_blessing_id)),
			" / ".join(selected_blessing.get("numeric_effects_ja", [])),
			String(selected_blessing.get("recommended_for_ja", "すべて"))
		],
		15,
		Color(1.0, 0.88, 0.48),
		HORIZONTAL_ALIGNMENT_LEFT
	)
	var carousel := ScrollContainer.new()
	carousel.name = "CharacterCarousel"
	carousel.custom_minimum_size.y = float(metrics.get("character_card_height", 128.0)) + 12.0
	carousel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	carousel.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	carousel.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(carousel)
	_register_mobile_scroll(carousel, MobileScrollSystemScript.AXIS_HORIZONTAL)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 10)
	carousel.add_child(cards)
	_populate_compact_character_cards(cards, metrics)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	root.add_child(actions)
	var blessing := _add_menu_button(actions, "祝福を選ぶ", func():
		blessing_expanded = not blessing_expanded
		show_character_select()
	, Color(1.0, 0.82, 0.28))
	blessing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var start := _add_menu_button(actions, "このキャラで開始\n%s" % _selected_blessing_name(), start_game, Color(0.52, 1.0, 1.0))
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if blessing_expanded:
		_add_phone_blessing_sheet(root)

func _build_tablet_character_select(root: VBoxContainer, selected_name: String) -> void:
	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	root.add_child(body)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 760
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)
	_add_label(left, "キャラ一覧", 22, Color(0.82, 0.92, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	var scroll := _scroll(left)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	_populate_compact_character_cards(grid, mobile_ui_scale.metrics(_layout_device_size()))
	var detail = CrystalCardScript.new()
	detail.setup(Color(1.0, 0.82, 0.34), false, Vector2(410, 0))
	detail.custom_minimum_size.x = 410
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(detail)
	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 9)
	detail.add_child(detail_box)
	var selected_data = meta_system.character_data(selected_character_id)
	_add_label(detail_box, "選択中キャラ", 18, Color(0.72, 0.82, 0.94), HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(detail_box, selected_name, 28, Color(1.0, 0.88, 0.42), HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(detail_box, _character_detail_text(selected_character_id, selected_data), 17, Color(0.86, 0.93, 0.98), HORIZONTAL_ALIGNMENT_LEFT)
	_add_blessing_picker(detail_box)
	_add_menu_button(detail_box, "このキャラで開始\n祝福：%s" % _selected_blessing_name(), start_game, Color(0.52, 1.0, 1.0))

func _build_desktop_character_select(root: VBoxContainer, selected_name: String) -> void:
	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	root.add_child(body)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 720
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)
	_add_label(left, "キャラ一覧", 22, Color(0.82, 0.92, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	var scroll := _scroll(left)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.custom_minimum_size.x = 700
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	var ids := meta_system.character_ids()
	character_cursor = clampi(character_cursor, 0, maxi(ids.size() - 1, 0))
	for i in range(ids.size()):
		var id := String(ids[i])
		var data := meta_system.character_data(id)
		var unlocked := meta_system.is_character_unlocked(save_data, id)
		var selected := id == selected_character_id
		var card = CharacterCardScript.new()
		var cost_text := ""
		if not unlocked:
			cost_text = meta_system.unlock_text(id, save_data)
			if meta_system.can_purchase_character(save_data, id):
				cost_text += " / 購入可能"
		card.setup(
			meta_system.display_name(id, save_data),
			String(data.get("role_ja", "")),
			String(data.get("trait_ja", "")),
			unlocked,
			selected,
			bool(data.get("secret", false)),
			cost_text,
			_weapon_name(String(data.get("initial_weapon", ""))),
			String(data.get("weakness_ja", "なし"))
		)
		card.set_icon_path(_character_asset_path(id, data, unlocked))
		card.pressed.connect(_character_card_clicked.bind(id))
		card.mouse_entered.connect(func(): character_cursor = i)
		grid.add_child(card)
	var detail = CrystalCardScript.new()
	detail.setup(Color(1.0, 0.82, 0.34), false, Vector2(360, 0))
	detail.custom_minimum_size.x = 360
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(detail)
	var detail_box := VBoxContainer.new()
	detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_box.add_theme_constant_override("separation", 9)
	detail.add_child(detail_box)
	var selected_data = meta_system.character_data(selected_character_id)
	_add_label(detail_box, "選択中キャラ", 18, Color(0.72, 0.82, 0.94), HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(detail_box, selected_name, 28, Color(1.0, 0.88, 0.42), HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(detail_box, _character_detail_text(selected_character_id, selected_data), 17, Color(0.86, 0.93, 0.98), HORIZONTAL_ALIGNMENT_LEFT)
	_add_blessing_picker(detail_box)
	_add_menu_button(detail_box, "このキャラで開始\n祝福：%s" % _selected_blessing_name(), start_game, Color(0.52, 1.0, 1.0))

func _populate_compact_character_cards(parent: Container, metrics: Dictionary) -> void:
	var ids := meta_system.character_ids()
	character_cursor = clampi(character_cursor, 0, maxi(ids.size() - 1, 0))
	for i in range(ids.size()):
		var id := String(ids[i])
		var data := meta_system.character_data(id)
		var unlocked := meta_system.is_character_unlocked(save_data, id)
		var selected := id == selected_character_id
		var cost_text := meta_system.unlock_text(id, save_data) if not unlocked else ""
		var card = CharacterCardScript.new()
		card.setup_compact(
			meta_system.display_name(id, save_data),
			String(data.get("role_ja", "")),
			unlocked,
			selected,
			bool(data.get("secret", false)),
			cost_text,
			Vector2(float(metrics.get("character_card_width", 176.0)), float(metrics.get("character_card_height", 128.0)))
		)
		card.set_icon_path(_character_asset_path(id, data, unlocked))
		card.pressed.connect(_character_card_clicked.bind(id))
		card.mouse_entered.connect(func(): character_cursor = i)
		parent.add_child(card)

func _add_phone_blessing_sheet(root: VBoxContainer) -> void:
	var sheet = CrystalCardScript.new()
	sheet.name = "BlessingSheet"
	sheet.setup(Color(1.0, 0.82, 0.28), false, Vector2(0, 142))
	sheet.custom_minimum_size.y = minf(142.0, _layout_device_size().y * 0.38)
	root.add_child(sheet)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	sheet.add_child(box)
	var heading := HBoxContainer.new()
	box.add_child(heading)
	_add_label(heading, "祝福", 22, Color(1.0, 0.90, 0.48), HORIZONTAL_ALIGNMENT_LEFT)
	var close := _add_menu_button(heading, "閉じる", func():
		blessing_expanded = false
		show_character_select()
	, Color(0.58, 0.72, 0.92))
	close.custom_minimum_size = Vector2(120, 60)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_register_mobile_scroll(scroll, MobileScrollSystemScript.AXIS_HORIZONTAL)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	scroll.add_child(row)
	for id in meta_system.unlocked_blessings(save_data):
		var blessing_id := String(id)
		var data: Dictionary = meta_system.blessings.get(blessing_id, {})
		var button = CrystalButtonScript.new()
		button.setup("%s\n%s" % [String(data.get("name_ja", blessing_id)), String(data.get("description_ja", ""))], Color(1.0, 0.82, 0.28), Vector2(220, 78))
		button.pressed.connect(_select_blessing.bind(blessing_id))
		row.add_child(button)

func _character_card_clicked(character_id: String) -> void:
	if meta_system.is_character_unlocked(save_data, character_id):
		_select_character(character_id)
	elif meta_system.can_purchase_character(save_data, character_id):
		_purchase_character(character_id)
	else:
		shop_message = "まだ解放条件を満たしていません：%s" % meta_system.display_name(character_id, save_data)
		show_character_select()

func _add_blessing_picker(parent: VBoxContainer) -> void:
	var selected = meta_system.blessings.get(selected_blessing_id, {})
	var toggle = CrystalButtonScript.new()
	toggle.setup("%s 祝福を選ぶ\n現在：%s" % ["▲" if blessing_expanded else "▼", String(selected.get("name_ja", selected_blessing_id))], Color(1.0, 0.86, 0.28), Vector2(320, 58))
	toggle.pressed.connect(func():
		blessing_expanded = not blessing_expanded
		show_character_select()
	)
	parent.add_child(toggle)
	_add_label(parent, meta_system.blessing_detail_text(selected_blessing_id, save_data), 16, Color(0.82, 0.88, 0.96), HORIZONTAL_ALIGNMENT_LEFT)
	if not blessing_expanded:
		return
	var box := GridContainer.new()
	box.columns = 2
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("h_separation", 8)
	box.add_theme_constant_override("v_separation", 8)
	parent.add_child(box)
	var blessings := meta_system.unlocked_blessings(save_data)
	for id in blessings:
		var blessing_id := String(id)
		var blessing: Dictionary = meta_system.blessings.get(blessing_id, {})
		var button = CrystalButtonScript.new()
		button.setup("%s\n%s" % [String(blessing.get("name_ja", blessing_id)), String(blessing.get("description_ja", ""))], Color(1.0, 0.86, 0.28) if blessing_id == selected_blessing_id else Color(0.46, 0.78, 1.0), Vector2(190, 82))
		button.pressed.connect(_select_blessing.bind(blessing_id))
		box.add_child(button)

func show_shop() -> void:
	_sync_from_save()
	_clear()
	screen_mode = "shop"
	title_visible = false
	help_visible = false
	_add_background(Color(0.026, 0.034, 0.052))
	var root := _page_box(42, 26, 42, 30)
	_add_top_bar(root, "クリスタルショップ", "所持クリスタル貨：%s　%s" % [JaText.format_int(int(save_data.get("crystal_currency", 0))), shop_message], show_title)
	_add_featured_shop(root)
	var category_ids := shop_category_system.category_ids()
	shop_category_index = clampi(shop_category_index, 0, maxi(0, category_ids.size() - 1))
	var category_tabs: Container
	if input_mode.is_touch_mode():
		category_tabs = _horizontal_chip_container(root, "ShopCategoryChips")
	else:
		var category_grid := GridContainer.new()
		category_grid.columns = 5
		category_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		category_grid.add_theme_constant_override("h_separation", 8)
		category_grid.add_theme_constant_override("v_separation", 6)
		root.add_child(category_grid)
		category_tabs = category_grid
	for i in range(category_ids.size()):
		var category_id = String(category_ids[i])
		var tab = CrystalButtonScript.new()
		tab.setup(shop_category_system.category_name(category_id), Color(1.0, 0.84, 0.30) if i == shop_category_index else Color(0.42, 0.82, 1.0), Vector2(164, 60 if input_mode.is_touch_mode() else 42))
		tab.pressed.connect(_select_shop_category.bind(i))
		category_tabs.add_child(tab)
	var current_category = String(category_ids[shop_category_index]) if not category_ids.is_empty() else "characters"
	_add_label(root, "おすすめ：%s" % shop_category_system.recommendation(current_category), 17, Color(0.58, 1.0, 0.78), HORIZONTAL_ALIGNMENT_LEFT)
	var scroll := _scroll(root)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size.x = 0 if input_mode.is_touch_mode() else 900
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	if current_category == "characters":
		_add_label(body, "キャラクター解放", 24, Color(1.0, 0.82, 0.36), HORIZONTAL_ALIGNMENT_LEFT)
		for id in meta_system.character_ids():
			var char_id := String(id)
			var data := meta_system.character_data(char_id)
			if bool(data.get("initial", false)) or int(data.get("unlock_cost", 0)) <= 0:
				continue
			var unlocked := meta_system.is_character_unlocked(save_data, char_id)
			var cost := int(data.get("unlock_cost", 0))
			var button = CrystalButtonScript.new()
			var unlock_progress := "" if unlocked else "\n%s" % meta_system.unlock_text(char_id, save_data)
			button.setup("%s　%s　費用：%s%s" % [meta_system.display_name(char_id, save_data), "解放済み" if unlocked else String(data.get("role_ja", "")), JaText.format_int(cost), unlock_progress], Color(1.0, 0.82, 0.36), Vector2(0, 82 if unlocked else 118))
			button.disabled = unlocked or int(save_data.get("crystal_currency", 0)) < cost
			button.pressed.connect(_purchase_character.bind(char_id))
			body.add_child(button)
	elif current_category == "meta":
		_add_label(body, "永続強化", 24, Color(1.0, 0.82, 0.36), HORIZONTAL_ALIGNMENT_LEFT)
		var levels: Dictionary = save_data.get("meta_upgrades", {})
		for id in meta_system.upgrades.keys():
			var upgrade_id := String(id)
			var data: Dictionary = meta_system.upgrades[upgrade_id]
			var current := int(levels.get(upgrade_id, 0))
			var max_level := int(data.get("max_level", 1))
			var cost := meta_system.upgrade_cost(upgrade_id, current)
			var button = CrystalButtonScript.new()
			button.setup("%s Lv%d/%d　%s　次費用：%s" % [String(data.get("name_ja", upgrade_id)), current, max_level, String(data.get("description_ja", "")), "MAX" if current >= max_level else JaText.format_int(cost)], Color(0.52, 1.0, 0.76), Vector2(0, 60))
			button.disabled = current >= max_level or int(save_data.get("crystal_currency", 0)) < cost
			button.pressed.connect(_purchase_upgrade.bind(upgrade_id))
			body.add_child(button)
	else:
		var items := currency_sink_system.items_for_category(current_category)
		for item in items:
			var sink_id = String(item.get("id", ""))
			var current = currency_sink_system.current_level(save_data, sink_id)
			var max_level = int(item.get("max_level", 1))
			var cost = currency_sink_system.cost_for(sink_id, current)
			var condition_ok = currency_sink_system.condition_met(save_data, sink_id)
			var condition_text = currency_sink_system.progress_text(save_data, sink_id)
			var blessing_detail := ""
			if current_category == "blessings":
				blessing_detail = "\n%s" % meta_system.blessing_detail_text(String(item.get("target", "")), save_data)
			var text = "%s　Lv%d/%d\n%s　次：%s　費用：%s\nおすすめ：%s　%s" % [
				String(item.get("name_ja", sink_id)), current, max_level,
				String(item.get("description_ja", "")), String(item.get("effect_per_level_ja", "")),
				"MAX" if current >= max_level else JaText.format_int(cost),
				String(item.get("recommend_ja", "")), condition_text + blessing_detail
			]
			var button = CrystalButtonScript.new()
			button.setup(text, Color(0.52, 1.0, 0.76) if condition_ok else Color(0.58, 0.62, 0.72), Vector2(0, 144 if current_category == "blessings" else 88))
			button.disabled = current >= max_level or not condition_ok or int(save_data.get("crystal_currency", 0)) < cost
			button.pressed.connect(_purchase_currency_sink.bind(sink_id))
			body.add_child(button)

func _add_featured_shop(root: VBoxContainer) -> void:
	save_data = shop_reroll_system.ensure_featured(save_system)
	var featured: Array = save_data.get("shop_featured_items", [])
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)
	var status = "おすすめ商品　周期%d　再抽選%d/%d　無料%d　次回%s" % [
		int(save_data.get("shop_cycle_id", 0)) + 1,
		int(save_data.get("shop_reroll_count", 0)),
		int(shop_reroll_system.config.get("max_rerolls_per_cycle", 8)),
		shop_reroll_system.free_rerolls_remaining(save_data),
		"無料" if shop_reroll_system.cost_for_count(int(save_data.get("shop_reroll_count", 0))) <= 0 else "費用:%s" % JaText.format_int(shop_reroll_system.cost_for_count(int(save_data.get("shop_reroll_count", 0))))
	]
	_add_label(header, status, 17, Color(1.0, 0.88, 0.42), HORIZONTAL_ALIGNMENT_LEFT)
	var reroll_button = CrystalButtonScript.new()
	reroll_button.setup("再抽選", Color(0.52, 1.0, 0.86), Vector2(150, 58 if input_mode.is_touch_mode() else 46))
	reroll_button.disabled = not shop_reroll_system.can_reroll(save_data)
	reroll_button.tooltip_text = "おすすめ枠だけを更新します。永久カタログは変わりません。"
	reroll_button.pressed.connect(_reroll_shop_featured)
	header.add_child(reroll_button)
	var row = _horizontal_chip_container(root, "ShopFeaturedItems")
	for item in featured:
		var button = CrystalButtonScript.new()
		var cost = int(item.get("cost", 0))
		var text = "%s\n%s　費用：%s" % [
			String(item.get("name_ja", item.get("id", ""))),
			String(item.get("description_ja", "")),
			JaText.format_int(cost)
		]
		button.setup(text, Color(1.0, 0.82, 0.36) if int(save_data.get("crystal_currency", 0)) >= cost else Color(0.58, 0.62, 0.72), Vector2(236, 88 if input_mode.is_touch_mode() else 76))
		button.disabled = int(save_data.get("crystal_currency", 0)) < cost
		button.pressed.connect(_purchase_featured_shop_item.bind(item))
		row.add_child(button)

func _select_shop_category(index: int) -> void:
	shop_category_index = clampi(index, 0, shop_category_system.category_ids().size() - 1)
	show_shop()

func show_loadout() -> void:
	_sync_from_save()
	_clear()
	screen_mode = "loadout"
	title_visible = false
	help_visible = false
	_add_background(Color(0.024, 0.036, 0.050))
	var root := _page_box(42, 26, 42, 30)
	var weapon_usage := loadout_disable_system.usage_text(save_data, "weapon")
	var passive_usage := loadout_disable_system.usage_text(save_data, "passive")
	_add_top_bar(
		root,
		"武器・パッシブ管理",
		"武器OFF枠：%s　パッシブOFF枠：%s　%s" % [weapon_usage, passive_usage, loadout_message],
		show_title
	)
	var tabs := _horizontal_chip_container(root, "LoadoutTabs") if input_mode.is_touch_mode() else HBoxContainer.new()
	if not input_mode.is_touch_mode():
		root.add_child(tabs)
	for kind in ["weapon", "passive"]:
		var tab := CrystalButtonScript.new()
		tab.setup("武器" if kind == "weapon" else "パッシブ", Color(1.0, 0.84, 0.30) if kind == loadout_kind else Color(0.42, 0.82, 1.0), Vector2(180, 58 if input_mode.is_touch_mode() else 42))
		tab.pressed.connect(func():
			loadout_kind = kind
			show_loadout()
		)
		tabs.add_child(tab)
	var filters := _horizontal_chip_container(root, "LoadoutFilters") if input_mode.is_touch_mode() else HBoxContainer.new()
	if not input_mode.is_touch_mode():
		root.add_child(filters)
	var filter_ids := ["all", "on", "off", "unlocked", "locked"]
	var filter_names := ["すべて", "ON", "OFF", "解放済み", "未解放"]
	for i in range(filter_ids.size()):
		var filter_id := String(filter_ids[i])
		var chip := CrystalButtonScript.new()
		chip.setup(filter_names[i], Color(0.58, 1.0, 0.74) if filter_id == loadout_filter else Color(0.34, 0.60, 0.82), Vector2(130, 56 if input_mode.is_touch_mode() else 36))
		chip.pressed.connect(func():
			loadout_filter = filter_id
			show_loadout()
		)
		filters.add_child(chip)
	var info := "OFFにした項目は次回ランの候補、宝箱・フィールド報酬の新規候補から除外されます。所持中の装備は消えません。"
	_add_label(root, info, 16, Color(0.78, 0.88, 0.96), HORIZONTAL_ALIGNMENT_LEFT)
	var scroll := _scroll(root)
	var grid := GridContainer.new()
	grid.columns = 1 if input_mode.is_touch_mode() else 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	var defs := _json_dict("res://data/weapons.json" if loadout_kind == "weapon" else "res://data/passives.json")
	var unlocked_key := "unlocked_weapons" if loadout_kind == "weapon" else "unlocked_passives"
	var unlocked: Array = save_data.get(unlocked_key, [])
	var disabled := loadout_disable_system.disabled_ids(save_data, loadout_kind)
	for raw_id in defs.keys():
		var id := String(raw_id)
		var is_unlocked := unlocked.has(id)
		var enabled := not disabled.has(id)
		if loadout_filter == "on" and (not is_unlocked or not enabled):
			continue
		if loadout_filter == "off" and (not is_unlocked or enabled):
			continue
		if loadout_filter == "unlocked" and not is_unlocked:
			continue
		if loadout_filter == "locked" and is_unlocked:
			continue
		var data: Dictionary = defs[id]
		var description := String(data.get("description_ja", ""))
		var tags := " / ".join(data.get("tags", []))
		var relation := _loadout_relation_text(loadout_kind, id)
		var progress := ""
		if not is_unlocked:
			progress = "\n%s" % meta_system.unlock_system.progress_text("weapons" if loadout_kind == "weapon" else "passives", id, save_data)
		var label := "%s　%s\n%s\n系統：%s%s%s" % [
			"ON" if enabled else "OFF",
			String(data.get("name_ja", id)),
			description,
			tags if tags != "" else "汎用",
			"\n%s" % relation if relation != "" else "",
			progress
		]
		var button := CrystalButtonScript.new()
		button.setup(label, Color(0.52, 1.0, 0.76) if enabled else Color(0.70, 0.48, 0.78), Vector2(0, 104))
		var check := loadout_disable_system.can_disable(save_data, loadout_kind, id)
		button.disabled = not is_unlocked or (enabled and not bool(check.get("ok", false)))
		button.tooltip_text = String(check.get("reason", "")) if button.disabled else ("タップしてOFF確認" if enabled else "タップしてONへ戻す")
		button.pressed.connect(_request_toggle_loadout.bind(loadout_kind, id, not enabled))
		grid.add_child(button)

func _request_toggle_loadout(kind: String, id: String, enabled: bool) -> void:
	var defs := _json_dict("res://data/weapons.json" if kind == "weapon" else "res://data/passives.json")
	var name := String(defs.get(id, {}).get("name_ja", id))
	var dialog = ConfirmDialogScript.new()
	dialog.name = "LoadoutConfirmDialog"
	dialog.set_anchors_preset(Control.PRESET_CENTER)
	dialog.offset_left = -280
	dialog.offset_right = 280
	dialog.offset_top = -132
	dialog.offset_bottom = 132
	var action := "ONに戻す" if enabled else "OFFにする"
	var body := "次回ランから候補に出現します。" if enabled else "次回ランから新規候補に出現しません。所持中の装備は消えません。"
	dialog.setup("%sを%sしますか？" % [name, action], body, action, "キャンセル", input_mode.is_touch_mode())
	dialog.confirmed.connect(func():
		if is_instance_valid(dialog):
			dialog.queue_free()
		_toggle_loadout(kind, id, enabled)
	)
	dialog.canceled.connect(func():
		if is_instance_valid(dialog):
			dialog.queue_free()
	)
	add_child(dialog)

func _toggle_loadout(kind: String, id: String, enabled: bool) -> void:
	var result := loadout_disable_system.set_enabled(save_system, kind, id, enabled)
	if bool(result.get("ok", false)):
		var defs := _json_dict("res://data/weapons.json" if kind == "weapon" else "res://data/passives.json")
		var name := String(defs.get(id, {}).get("name_ja", id))
		loadout_message = "%sを%sにしました。次回ランから反映します。" % [name, "ON" if enabled else "OFF"]
	else:
		loadout_message = String(result.get("reason", "変更できません。"))
	show_loadout()

func _loadout_relation_text(kind: String, id: String) -> String:
	var evolutions := _json_dict("res://data/evolutions.json")
	if kind == "weapon":
		for data in evolutions.values():
			if String(data.get("weapon", "")) == id:
				return "進化：%s / 素材：%s" % [String(data.get("name_ja", "")), _passive_name(String(data.get("passive", "")))]
	else:
		var related: Array = []
		for data in evolutions.values():
			if String(data.get("passive", "")) == id:
				related.append(_weapon_name(String(data.get("weapon", ""))))
		if not related.is_empty():
			return "進化素材：%s" % " / ".join(related)
	return ""

func _passive_name(passive_id: String) -> String:
	var passives := _json_dict("res://data/passives.json")
	return String(passives.get(passive_id, {}).get("name_ja", passive_id))

func show_collection() -> void:
	_sync_from_save()
	_clear()
	screen_mode = "collection"
	title_visible = false
	help_visible = false
	_add_background(Color(0.028, 0.036, 0.054))
	var root := _page_box(42, 26, 42, 30)
	_add_top_bar(root, "図鑑", "カテゴリをクリックまたは←/→で切替", show_title)
	var tabs: Container
	if input_mode.is_touch_mode():
		tabs = _horizontal_chip_container(root, "CollectionCategoryChips")
	else:
		var tabs_grid := GridContainer.new()
		tabs_grid.columns = 5
		tabs_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs_grid.add_theme_constant_override("h_separation", 8)
		tabs_grid.add_theme_constant_override("v_separation", 6)
		root.add_child(tabs_grid)
		tabs = tabs_grid
	for i in range(collection_tabs.size()):
		var button = CrystalButtonScript.new()
		button.setup(String(collection_tab_names[i]), Color(1.0, 0.86, 0.28) if i == collection_tab_index else Color(0.42, 0.82, 1.0), Vector2(150, 60 if input_mode.is_touch_mode() else 40))
		button.pressed.connect(_select_collection_tab.bind(i))
		tabs.add_child(button)
	var filters: Container
	if input_mode.is_touch_mode():
		filters = _horizontal_chip_container(root, "CollectionFilterChips")
	else:
		var filter_grid := GridContainer.new()
		filter_grid.columns = 7
		filter_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		filter_grid.add_theme_constant_override("h_separation", 6)
		filter_grid.add_theme_constant_override("v_separation", 5)
		root.add_child(filter_grid)
		filters = filter_grid
	for i in range(collection_filter_system.FILTER_IDS.size()):
		var filter_button = CrystalButtonScript.new()
		filter_button.setup(String(collection_filter_system.FILTER_NAMES[i]), Color(0.58, 1.0, 0.76) if i == collection_filter_index else Color(0.34, 0.60, 0.82), Vector2(124, 56 if input_mode.is_touch_mode() else 34))
		filter_button.pressed.connect(_select_collection_filter.bind(i))
		filters.add_child(filter_button)
	var sorts := HBoxContainer.new()
	sorts.add_theme_constant_override("separation", 6)
	root.add_child(sorts)
	_add_label(sorts, "並び替え", 15, Color(0.82, 0.88, 0.96), HORIZONTAL_ALIGNMENT_LEFT)
	for i in range(collection_filter_system.SORT_IDS.size()):
		var sort_button = CrystalButtonScript.new()
		sort_button.setup(String(collection_filter_system.SORT_NAMES[i]), Color(1.0, 0.84, 0.30) if i == collection_sort_index else Color(0.42, 0.82, 1.0), Vector2(126 if input_mode.is_touch_mode() else 118, 56 if input_mode.is_touch_mode() else 34))
		sort_button.pressed.connect(_select_collection_sort.bind(i))
		sorts.add_child(sort_button)
	var rows := meta_system.collection_rows(String(collection_tabs[collection_tab_index]), save_data)
	var known := 0
	for row in rows:
		if bool(row.get("known", false)):
			known += 1
	_add_label(root, "発見：%d / %d" % [known, rows.size()], 18, Color(1.0, 0.82, 0.36), HORIZONTAL_ALIGNMENT_LEFT)
	rows = collection_filter_system.filter_rows(rows, String(collection_filter_system.FILTER_IDS[collection_filter_index]))
	rows = collection_filter_system.sort_rows(rows, String(collection_filter_system.SORT_IDS[collection_sort_index]))
	var scroll := _scroll(root)
	var grid := GridContainer.new()
	grid.columns = 2 if input_mode.is_touch_mode() else 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.custom_minimum_size.x = 0 if input_mode.is_touch_mode() else 940
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	for row in rows:
		var card = CollectionCardScript.new()
		card.setup(row)
		grid.add_child(card)

func _select_collection_tab(index: int) -> void:
	collection_tab_index = clampi(index, 0, collection_tabs.size() - 1)
	show_collection()

func _select_collection_filter(index: int) -> void:
	collection_filter_index = clampi(index, 0, collection_filter_system.FILTER_IDS.size() - 1)
	show_collection()

func _select_collection_sort(index: int) -> void:
	collection_sort_index = clampi(index, 0, collection_filter_system.SORT_IDS.size() - 1)
	show_collection()

func show_quests() -> void:
	_sync_from_save()
	_clear()
	screen_mode = "quests"
	title_visible = false
	help_visible = false
	_add_background(Color(0.026, 0.034, 0.052))
	var root := _page_box(42, 26, 42, 30)
	var completed: Dictionary = save_data.get("quests_completed", {})
	var done_count := 0
	for id in completed.keys():
		if bool(completed[id]):
			done_count += 1
	_add_top_bar(root, "実績 / クエスト", "達成率：%d / %d　報酬は達成時に自動受取" % [done_count, meta_system.quests.keys().size()], show_title)
	var quest_filters: Container
	if input_mode.is_touch_mode():
		quest_filters = _horizontal_chip_container(root, "AchievementFilterChips")
	else:
		var filter_row := HBoxContainer.new()
		filter_row.add_theme_constant_override("separation", 8)
		root.add_child(filter_row)
		quest_filters = filter_row
	var filter_names := ["すべて", "未達成", "進行中", "もうすぐ", "達成済み"]
	for i in range(filter_names.size()):
		var filter_index := i
		var filter_button = CrystalButtonScript.new()
		filter_button.setup(filter_names[i], Color(0.48, 1.0, 0.66) if i == quest_filter_index else Color(0.42, 0.82, 1.0), Vector2(150, 56 if input_mode.is_touch_mode() else 40))
		filter_button.pressed.connect(func():
			quest_filter_index = filter_index
			show_quests()
		)
		quest_filters.add_child(filter_button)
	var scroll := _scroll(root)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size.x = 0 if input_mode.is_touch_mode() else 920
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	for id in meta_system.quests.keys():
		var quest_id := String(id)
		var quest: Dictionary = meta_system.quests[quest_id]
		var done := bool(completed.get(quest_id, false))
		var progress := achievement_progress_system.row(save_data, quest, done)
		if quest_filter_index == 1 and done:
			continue
		if quest_filter_index == 2 and not achievement_progress_system.is_in_progress(progress):
			continue
		if quest_filter_index == 3 and not achievement_progress_system.is_near(progress):
			continue
		if quest_filter_index == 4 and not done:
			continue
		var card = AchievementCardScript.new()
		card.setup(String(quest.get("name_ja", quest_id)), String(quest.get("description_ja", "")), _reward_text(quest.get("reward", {})), done, progress)
		body.add_child(card)

func show_settings() -> void:
	_sync_from_save()
	_clear()
	screen_mode = "settings"
	title_visible = false
	help_visible = false
	_add_background(Color(0.028, 0.038, 0.060))
	var root := _page_box(90, 40, 90, 46)
	_add_top_bar(root, "設定", "各項目をタップして変更。シード空欄ならランダム。", show_title)
	var settings: Dictionary = save_data.get("settings", {})
	settings_section_nodes.clear()
	if input_mode.is_touch_mode():
		var category_row := _horizontal_chip_container(root, "SettingsCategoryChips")
		for category in ["操作", "表示", "UIサイズ", "マップ", "性能", "開発者", "音", "データ"]:
			var category_button = CrystalButtonScript.new()
			category_button.setup(String(category), Color(0.42, 0.82, 1.0), Vector2(126, 56))
			category_button.pressed.connect(_scroll_to_settings_section.bind(String(category)))
			category_row.add_child(category_button)
	var scroll := _scroll(root)
	settings_scroll = scroll
	var settings_body := VBoxContainer.new()
	settings_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_body.custom_minimum_size.x = 0 if input_mode.is_touch_mode() else 900
	settings_body.add_theme_constant_override("separation", 10)
	scroll.add_child(settings_body)
	var row := GridContainer.new()
	row.columns = 1 if input_mode.is_touch_mode() else 2
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size.x = 0 if input_mode.is_touch_mode() else 840
	row.add_theme_constant_override("h_separation", 12)
	row.add_theme_constant_override("v_separation", 10)
	settings_body.add_child(row)
	settings_section_nodes["操作"] = _add_label(row, "操作", 24, Color(0.52, 1.0, 0.86), HORIZONTAL_ALIGNMENT_LEFT)
	_add_toggle(row, "画面揺れ", "screen_shake", bool(settings.get("screen_shake", true)))
	_add_toggle(row, "無限強化自動", "auto_infinite", bool(settings.get("auto_infinite", true)))
	_add_toggle(row, "自動回収ドローン", "auto_recall_drone", bool(settings.get("auto_recall_drone", false)))
	_add_toggle(row, "フルスクリーン", "fullscreen", bool(settings.get("fullscreen", false)))
	_add_toggle(row, "長押し倍速", "speed_hold_enabled", bool(settings.get("speed_hold_enabled", true)))
	_add_toggle(row, "仮想スティック", "virtual_joystick_enabled", bool(settings.get("virtual_joystick_enabled", true)))
	if not input_mode.is_touch_mode():
		_add_choice(row, "倍速キー", "speed_hold_key", String(settings.get("speed_hold_key", "left_shift")), ["left_shift", "tab", "space", "middle_mouse"])
	_add_choice(row, "倍速倍率", "speed_multiplier", float(settings.get("speed_multiplier", 2.0)), [1.5, 2.0])
	_add_choice(row, "タッチ操作UI", "touch_ui_mode", String(settings.get("touch_ui_mode", "auto")), ["auto", "on", "off"])
	_add_choice(row, "タッチボタンサイズ", "touch_button_size", String(settings.get("touch_button_size", "standard")), ["small", "standard", "large"])
	_add_choice(row, "利き手", "touch_handedness", String(settings.get("touch_handedness", "right")), ["right", "left"])
	_add_choice(row, "移動スティック", "move_control_mode", String(settings.get("move_control_mode", "dynamic")), ["dynamic", "fixed"])
	_add_choice(row, "スティック表示", "joystick_visual_mode", String(settings.get("joystick_visual_mode", "active")), ["always", "active", "hidden"])
	_add_choice(row, "スティック感度", "joystick_sensitivity", float(settings.get("joystick_sensitivity", 1.0)), [0.8, 1.0, 1.2, 1.5])
	_add_choice(row, "スティック遊び", "joystick_deadzone", float(settings.get("joystick_deadzone", 0.12)), [0.08, 0.12, 0.18, 0.24])
	_add_toggle(row, "タッチ振動", "touch_haptics", bool(settings.get("touch_haptics", true)))
	settings_section_nodes["表示"] = _add_label(row, "表示 / HUD", 24, Color(0.52, 1.0, 0.86), HORIZONTAL_ALIGNMENT_LEFT)
	_add_toggle(row, "ダメージ数字", "damage_numbers", bool(settings.get("damage_numbers", true)))
	_add_toggle(row, "通知ログ", "notification_log_enabled", bool(settings.get("notification_log_enabled", true)))
	_add_choice(row, "通知ログ量", "notification_log_amount", String(settings.get("notification_log_amount", "standard")), ["low", "standard"])
	_add_choice(row, "装備HUD", "equipment_hud_mode", String(settings.get("equipment_hud_mode", "simple")), ["simple", "detail", "hidden"])
	_add_toggle(row, "武器HUD", "weapon_hud_enabled", bool(settings.get("weapon_hud_enabled", true)))
	_add_toggle(row, "パッシブHUD", "passive_hud_enabled", bool(settings.get("passive_hud_enabled", true)))
	_add_choice(row, "ボス警告", "boss_alert_intensity", String(settings.get("boss_alert_intensity", "strong")), ["normal", "strong"])
	_add_choice(row, "UIアニメーション量", "ui_animation_amount", String(settings.get("ui_animation_amount", "standard")), ["low", "standard", "high"])
	settings_section_nodes["マップ"] = _add_label(row, "マップ", 24, Color(0.52, 1.0, 0.86), HORIZONTAL_ALIGNMENT_LEFT)
	_add_choice(row, "ミニマップサイズ", "minimap_size", String(settings.get("minimap_size", "standard")), ["small", "standard", "large"])
	_add_choice(row, "ミニマップ透明度", "minimap_opacity", String(settings.get("minimap_opacity", "standard")), ["low", "standard", "high"])
	_add_toggle(row, "マップタップ拡大", "map_tap_expand", bool(settings.get("map_tap_expand", true)))
	_add_choice(row, "カメラ表示サイズ", "camera_view_size", String(settings.get("camera_view_size", "standard")), ["near", "standard", "wide"])
	settings_section_nodes["性能"] = _add_label(row, "パフォーマンス", 24, Color(0.52, 1.0, 0.86), HORIZONTAL_ALIGNMENT_LEFT)
	_add_choice(row, "エフェクト量", "effect_density", String(settings.get("effect_density", "normal")), ["low", "normal", "high"])
	_add_choice(row, "描画品質", "render_quality", String(settings.get("render_quality", "standard")), ["low", "standard", "high"])
	_add_choice(row, "ミニマップ更新頻度", "minimap_update_hz", int(settings.get("minimap_update_hz", 8)), [4, 8, 12])
	_add_toggle(row, "背景粒子", "background_particles", bool(settings.get("background_particles", true)))
	_add_toggle(row, "省電力モード（45fps・品質維持）", "battery_saver", bool(settings.get("battery_saver", settings.get("low_power_mode", false))))
	settings_section_nodes["開発者"] = _add_label(row, "開発者", 24, Color(1.0, 0.78, 0.38), HORIZONTAL_ALIGNMENT_LEFT)
	_add_choice(row, "経験値倍率", "debug_exp_multiplier", float(settings.get("debug_exp_multiplier", 1.0)), [0.25, 0.5, 1.0, 1.5, 2.0, 3.0, 5.0, 10.0, 20.0])
	_add_toggle(row, "デバッグ倍率中も実績・解放を保存する", "allow_debug_progress", bool(settings.get("allow_debug_progress", false)))
	_add_label(row, "1.0x以外では保存許可OFF時に通貨・解放・最高記録を保存しません。", 16, Color(1.0, 0.88, 0.58), HORIZONTAL_ALIGNMENT_LEFT)
	settings_section_nodes["音"] = _add_label(row, "音", 24, Color(0.52, 1.0, 0.86), HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(row, "音声は廃止済みです。BGM/SE/UI音は読み込まず、iOS実機の省電力を優先します。", 18, Color(0.86, 0.92, 0.98), HORIZONTAL_ALIGNMENT_LEFT)
	settings_section_nodes["UIサイズ"] = _add_label(settings_body, "UIサイズ", 24, Color(0.52, 1.0, 0.86), HORIZONTAL_ALIGNMENT_LEFT)
	_add_slider(settings_body, "UI拡大率", "ui_scale", float(settings.get("ui_scale", 1.0)), 0.85, 1.25)
	_add_slider(settings_body, "HUDサイズ", "hud_scale", float(settings.get("hud_scale", 1.0)), 0.9, 1.3)
	_add_slider(settings_body, "ボタン透明度", "touch_button_opacity", float(settings.get("touch_button_opacity", 0.78)), 0.35, 1.0)
	_add_slider(settings_body, "Safe Area余白", "safe_area_margin", float(settings.get("safe_area_margin", 16.0)), 0.0, 36.0)
	_add_slider(settings_body, "スティック左右位置", "joystick_offset_x", float(settings.get("joystick_offset_x", 0.0)), -80.0, 80.0)
	_add_slider(settings_body, "スティック上下位置", "joystick_offset_y", float(settings.get("joystick_offset_y", 0.0)), -80.0, 80.0)
	if input_mode.is_touch_mode():
		_add_menu_button(settings_body, "タッチ操作説明を再表示", func():
			touch_tutorial_page = 0
			show_help(false)
		, Color(0.70, 0.86, 1.0))
	var seed_row := HBoxContainer.new()
	seed_row.add_theme_constant_override("separation", 10)
	settings_body.add_child(seed_row)
	settings_section_nodes["データ"] = _add_label(seed_row, "シード入力", 18, Color(0.88, 0.94, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	seed_input = LineEdit.new()
	seed_input.text = String(settings.get("seed_text", ""))
	seed_input.placeholder_text = "空欄ならランダム"
	seed_input.custom_minimum_size = Vector2(360, 42)
	seed_input.text_submitted.connect(_set_seed_text)
	seed_row.add_child(seed_input)
	_add_menu_button(seed_row, "保存", func(): _set_seed_text(seed_input.text), Color(0.52, 1.0, 1.0))
	_add_menu_button(settings_body, "セーブ初期化へ", show_reset, Color(1.0, 0.34, 0.42), true)

func _scroll_to_settings_section(section: String) -> void:
	await get_tree().process_frame
	if settings_scroll == null or not settings_section_nodes.has(section):
		return
	var target: Control = settings_section_nodes[section]
	var delta := target.global_position.y - settings_scroll.global_position.y
	settings_scroll.scroll_vertical = maxi(0, settings_scroll.scroll_vertical + int(delta) - 8)

func show_reset() -> void:
	_clear()
	screen_mode = "reset"
	title_visible = false
	help_visible = false
	_add_background(Color(0.040, 0.026, 0.030))
	var root := _page_box(170, 82, 170, 82)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	_add_label(root, "セーブ初期化", 38, Color(1.0, 0.54, 0.42))
	var reset_description := "進行状況・通貨・解放・図鑑を初期化します。\n設定と遊び方既読だけは残ります。"
	if not input_mode.is_touch_mode():
		reset_description += "\n実行には RESET または 初期化 の入力が必要です。"
	_add_label(root, reset_description, 21, Color(0.94, 0.88, 0.86))
	if not input_mode.is_touch_mode():
		reset_input = LineEdit.new()
		reset_input.placeholder_text = "RESET"
		reset_input.custom_minimum_size = Vector2(360, 44)
		reset_input.text_submitted.connect(_confirm_reset)
		root.add_child(reset_input)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	root.add_child(row)
	_add_menu_button(row, "戻る", show_settings, Color(0.42, 0.82, 1.0))
	_add_menu_button(row, "初期化を実行", func(): _confirm_reset("初期化" if input_mode.is_touch_mode() else reset_input.text), Color(1.0, 0.34, 0.42), true)
	_add_label(root, reset_message, 20, Color(1.0, 0.78, 0.34))

func start_game() -> void:
	_sync_from_save()
	_clear()
	screen_mode = "game"
	title_visible = false
	help_visible = false
	var game := GameScene.instantiate()
	current_screen = game
	if game is GameScreen:
		(game as GameScreen).initial_auto_infinite_enabled = auto_infinite_enabled
		(game as GameScreen).initial_character_id = selected_character_id
		(game as GameScreen).initial_blessing_id = selected_blessing_id
		(game as GameScreen).initial_save_data = save_data.duplicate(true)
		(game as GameScreen).initial_seed_text = String(save_data.get("settings", {}).get("seed_text", ""))
	add_child(game)
	game.game_finished.connect(_on_game_finished)
	game.title_requested.connect(show_title)

func _on_game_finished(summary: Dictionary) -> void:
	var meta_result: Dictionary = {}
	if bool(summary.get("debug_progress_blocked", false)):
		meta_result = {
			"currency_earned": 0,
			"currency_total": int(save_system.load_data().get("crystal_currency", 0)),
			"quests_completed": [],
			"characters_unlocked": [],
			"weapons_unlocked": [],
			"passives_unlocked": [],
			"mastery": {},
			"progress_deltas": [],
			"debug_progress_blocked": true
		}
	else:
		meta_result = meta_system.update_after_run(save_system, summary)
		shop_reroll_system.advance_cycle(save_system)
	for key in meta_result.keys():
		summary[key] = meta_result[key]
	summary["meta_result"] = meta_result
	summary["challenge_stamps"] = _result_stamps(summary, meta_result)
	_clear()
	screen_mode = "result"
	title_visible = false
	help_visible = false
	var result := ResultScene.instantiate()
	current_screen = result
	add_child(result)
	result.retry_requested.connect(start_game)
	result.title_requested.connect(show_title)
	result.character_requested.connect(show_character_select)
	result.shop_requested.connect(show_shop)
	result.collection_requested.connect(show_collection)
	result.show_summary(summary)

func _select_character(character_id: String) -> void:
	if save_system.select_character(character_id):
		selected_character_id = character_id
		_sync_from_save()
	show_character_select()

func _select_blessing(blessing_id: String) -> void:
	var blessings := meta_system.unlocked_blessings(save_data)
	if blessings.has(blessing_id):
		save_system.select_blessing(blessing_id)
		selected_blessing_id = blessing_id
		_sync_from_save()
	show_character_select()

func _purchase_character(character_id: String) -> void:
	if meta_system.purchase_character(save_system, character_id):
		shop_message = "購入しました：%s" % meta_system.display_name(character_id, save_system.load_data())
	else:
		shop_message = "購入できません。"
	_sync_from_save()
	if screen_mode == "characters":
		show_character_select()
	else:
		show_shop()

func _purchase_upgrade(upgrade_id: String) -> void:
	shop_message = "強化しました。" if meta_system.purchase_upgrade(save_system, upgrade_id) else "強化できません。"
	show_shop()

func _purchase_currency_sink(sink_id: String) -> void:
	shop_message = "購入しました。" if currency_sink_system.purchase(save_system, sink_id) else "購入できません。条件・所持通貨・最大Lvを確認してください。"
	_sync_from_save()
	show_shop()

func _reroll_shop_featured() -> void:
	var result = shop_reroll_system.reroll(save_system)
	if bool(result.get("ok", false)):
		shop_message = "おすすめ商品を再抽選しました。消費：%s" % JaText.format_int(int(result.get("cost", 0)))
	else:
		shop_message = "再抽選できません。所持通貨または上限を確認してください。"
	_sync_from_save()
	show_shop()

func _purchase_featured_shop_item(item: Dictionary) -> void:
	var kind = String(item.get("kind", ""))
	var id = String(item.get("id", ""))
	match kind:
		"character":
			_purchase_character(id)
		"meta":
			_purchase_upgrade(id)
		"sink":
			_purchase_currency_sink(id)
		_:
			shop_message = "購入できません。"
			show_shop()

func _toggle_auto_infinite() -> void:
	_update_setting("auto_infinite", not auto_infinite_enabled)

func _update_setting(key: String, value) -> void:
	if key == "battery_saver":
		save_system.update_settings({"battery_saver": value, "low_power_mode": value})
	else:
		save_system.update_settings({key: value})
	_sync_from_save()

func _set_seed_text(text: String) -> void:
	_update_setting("seed_text", text.strip_edges())
	show_settings()

func _confirm_reset(text: String) -> void:
	if save_system.reset_play_data(text):
		reset_message = "初期化しました。"
		shop_message = ""
		_sync_from_save()
		show_title()
	else:
		reset_message = "確認文字が違います。"
		show_reset()

func _sync_from_save() -> void:
	save_data = save_system.load_data()
	var unlocked_blessings := meta_system.unlocked_blessings(save_data)
	var current_unlocked: Array = save_data.get("unlocked_blessings", [])
	if unlocked_blessings.size() != current_unlocked.size():
		save_data["unlocked_blessings"] = unlocked_blessings
		save_system.save_data(save_data)
		save_data = save_system.load_data()
	selected_character_id = String(save_data.get("selected_character", "noah"))
	selected_blessing_id = String(save_data.get("selected_blessing", "attack"))
	if not meta_system.is_character_unlocked(save_data, selected_character_id):
		selected_character_id = "noah"
		save_system.select_character(selected_character_id)
	var blessings := save_data.get("unlocked_blessings", ["attack"]) as Array
	if not blessings.has(selected_blessing_id):
		selected_blessing_id = "attack"
		save_system.select_blessing(selected_blessing_id)
	auto_infinite_enabled = bool(save_data.get("settings", {}).get("auto_infinite", true))
	auto_recall_enabled = bool(save_data.get("settings", {}).get("auto_recall_drone", false))
	input_mode.configure(save_data.get("settings", {}))
	_configure_mobile_viewport()
	_configure_mobile_scroll()

func _title_status_text() -> String:
	var character_name := meta_system.display_name(selected_character_id, save_data)
	var blessing: Dictionary = meta_system.blessings.get(selected_blessing_id, {})
	var best_score := save_system.load_best_score()
	var stats: Dictionary = save_data.get("stats", {})
	return "キャラ：%s\n祝福：%s\nクリスタル貨：%s\n最高スコア：%s\n最高生存：%s" % [
		character_name,
		String(blessing.get("name_ja", "攻撃の祝福")),
		JaText.format_int(int(save_data.get("crystal_currency", 0))),
		JaText.format_int(best_score),
		JaText.format_time(float(stats.get("best_survival", 0.0)))
	]

func _next_goal_text() -> String:
	var completed: Dictionary = save_data.get("quests_completed", {})
	for id in meta_system.quests.keys():
		if not bool(completed.get(String(id), false)):
			var quest: Dictionary = meta_system.quests[id]
			return "次の目標：%s - %s" % [String(quest.get("name_ja", id)), String(quest.get("description_ja", ""))]
	return "次の目標：未解放キャラの条件達成と30分以降の高スコア"

func _weapon_name(weapon_id: String) -> String:
	if weapon_id == "":
		return "なし（魔弾を補助装備）"
	var weapons := _json_dict("res://data/weapons.json")
	return String(weapons.get(weapon_id, {}).get("name_ja", weapon_id))

func _character_asset_path(character_id: String, data: Dictionary, unlocked: bool) -> String:
	if bool(data.get("secret", false)) and not unlocked:
		match character_id:
			"ghost":
				return "res://assets/survivor/characters/secret_ghost_locked.svg"
			"collector":
				return "res://assets/survivor/characters/secret_collector_locked.svg"
			"nameless_reaper":
				return "res://assets/survivor/characters/secret_nameless_reaper_locked.svg"
	return "res://assets/survivor/characters/%s.svg" % character_id

func _reward_text(reward: Dictionary) -> String:
	var parts: Array = []
	if reward.has("currency"):
		parts.append("クリスタル貨 %s" % JaText.format_int(int(reward.get("currency", 0))))
	if reward.has("unlock_character"):
		parts.append("キャラ解放")
	if reward.has("secret_flag"):
		parts.append("秘密条件")
	if reward.has("discover_weapon"):
		parts.append("図鑑発見")
	return " / ".join(parts) if not parts.is_empty() else "なし"

func _result_stamps(summary: Dictionary, meta_result: Dictionary) -> Array:
	var stamps: Array = []
	if int(meta_result.get("currency_earned", 0)) >= 500:
		stamps.append("大量採掘")
	if int(summary.get("evolved_weapon_count", 0)) >= 2:
		stamps.append("進化連鎖")
	if int(summary.get("boss_defeats", 0)) > 0:
		stamps.append("ボス討伐")
	if int(summary.get("max_combo", 0)) >= 300:
		stamps.append("吸収名人")
	if not (meta_result.get("characters_unlocked", []) as Array).is_empty():
		stamps.append("新キャラ解放")
	if stamps.is_empty():
		stamps.append("次の遠征へ")
	return stamps

func _add_top_bar(parent: VBoxContainer, title: String, subtitle: String, back_callable: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_box)
	_add_label(title_box, title, 34, Color(0.94, 0.98, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(title_box, subtitle, 17, Color(0.76, 0.86, 0.96), HORIZONTAL_ALIGNMENT_LEFT)
	_add_menu_button(row, "戻る", back_callable, Color(0.42, 0.82, 1.0))

func _add_menu_button(parent: Control, label: String, action: Callable, accent: Color = Color(0.40, 0.92, 1.0), danger: bool = false) -> Button:
	var button = CrystalButtonScript.new()
	button.setup(label, accent, Vector2(0, 64 if input_mode.is_touch_mode() else 48), danger)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _add_toggle(parent: Control, title: String, key: String, value: bool) -> void:
	var toggle = ToggleOptionScript.new()
	toggle.setup(title, value)
	toggle.toggled_value.connect(func(v): _update_setting(key, v))
	parent.add_child(toggle)

func _add_slider(parent: Control, title: String, key: String, value: float, min_value: float = 0.0, max_value: float = 1.0) -> void:
	var slider = SettingsSliderScript.new()
	slider.setup(title, value, min_value, max_value)
	slider.value_changed.connect(func(v): _update_setting(key, v))
	parent.add_child(slider)

func _add_choice(parent: Control, title: String, key: String, value, choices: Array) -> void:
	var button = CrystalButtonScript.new()
	button.setup("%s: %s" % [title, str(value)], Color(0.42, 0.82, 1.0), Vector2(0, 60 if input_mode.is_touch_mode() else 48))
	button.pressed.connect(func():
		var index = choices.find(value)
		var next_value = choices[(index + 1) % choices.size()]
		_update_setting(key, next_value)
		show_settings()
	)
	parent.add_child(button)

func _draw_neon_background() -> void:
	for i in range(5):
		var rect := ColorRect.new()
		rect.color = Color(0.05 + 0.02 * i, 0.12, 0.22 + 0.08 * i, 0.09)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.offset_left = -120 + i * 170
		rect.offset_top = 80 + i * 38
		rect.offset_right = -840 + i * 170
		rect.offset_bottom = -520 + i * 38
		add_child(rect)

func _add_background(color: Color) -> void:
	var bg := ColorRect.new()
	bg.color = color
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

func _page_box(left: int, top: int, right: int, bottom: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	if input_mode.is_touch_mode():
		var viewport_size := get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
		var extra := float(save_data.get("settings", {}).get("safe_area_margin", 0.0))
		var safe := mobile_safe_area.safe_rect(viewport_size, extra)
		box.offset_left = maxf(float(left), safe.position.x)
		box.offset_top = maxf(float(top), safe.position.y)
		box.offset_right = -maxf(float(right), viewport_size.x - safe.end.x)
		box.offset_bottom = -maxf(float(bottom), viewport_size.y - safe.end.y)
	else:
		box.offset_left = left
		box.offset_top = top
		box.offset_right = -right
		box.offset_bottom = -bottom
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	return box

func _is_tablet_layout() -> bool:
	return mobile_ui_scale.classify(_layout_device_size()) == "tablet"

func _layout_device_size() -> Vector2:
	var viewport_size := get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	if not input_mode.is_ios_touch():
		return viewport_size
	var screen_size := Vector2(DisplayServer.screen_get_size())
	if screen_size.x <= 0.0 or screen_size.y <= 0.0:
		return viewport_size
	return Vector2(maxf(screen_size.x, screen_size.y), minf(screen_size.x, screen_size.y))

func _scroll(parent: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	ui_layout_fix.prepare_scroll(scroll)
	parent.add_child(scroll)
	_register_mobile_scroll(scroll, MobileScrollSystemScript.AXIS_VERTICAL)
	return scroll

func _horizontal_chip_container(parent: Control, node_name: String) -> HBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = node_name
	scroll.custom_minimum_size.y = 64
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	_register_mobile_scroll(scroll, MobileScrollSystemScript.AXIS_HORIZONTAL)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	scroll.add_child(row)
	return row

func _add_label(parent: Control, text: String, size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 150
	if parent is VBoxContainer or parent is PanelContainer:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _character_detail_text(character_id: String, data: Dictionary) -> String:
	var unlocked = meta_system.is_character_unlocked(save_data, character_id)
	var lines: Array = [
		"役割：%s" % String(data.get("role_ja", "")),
		"初期武器：%s" % _weapon_name(String(data.get("initial_weapon", ""))),
		"特性：%s" % String(data.get("trait_ja", "")),
		"弱点：%s" % String(data.get("weakness_ja", "なし")),
		"選択中の祝福：%s" % _selected_blessing_name(),
		meta_system.blessing_detail_text(selected_blessing_id, save_data)
	]
	var evolution: Dictionary = meta_system.character_evolutions.get(character_id, {})
	if not evolution.is_empty():
		var unlocked_evolutions: Dictionary = save_data.get("character_evolutions_unlocked", {})
		lines.append("進化後：%s" % String(evolution.get("evolved_name_ja", "")))
		lines.append("進化特性：%s" % String(evolution.get("trait_upgrade_ja", "")))
		lines.append("ラン内条件：Lv%d / %s / %s" % [
			int(evolution.get("required_level", 20)),
			JaText.format_time(float(evolution.get("required_seconds", 600.0))),
			String(evolution.get("unique_condition", {}).get("text_ja", "固有条件"))
		])
		lines.append("進化解放：%s" % ("解放済み" if bool(unlocked_evolutions.get(character_id, character_id == "noah")) else String(meta_system.character_evolution_unlocks.get(character_id, {}).get("text_ja", "熟練度で解放"))))
	if not unlocked:
		lines.append(meta_system.unlock_text(character_id, save_data))
	return "\n".join(lines)

func _selected_blessing_name() -> String:
	return String(meta_system.blessings.get(selected_blessing_id, {}).get("name_ja", selected_blessing_id))

func _json_dict(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func _clear() -> void:
	if mobile_scroll_system != null:
		mobile_scroll_system.clear_registrations()
	for child in get_children():
		if child == mobile_scroll_system:
			continue
		_set_branch_process(child, false)
		remove_child(child)
		child.queue_free()
	current_screen = null

func _set_branch_process(node: Node, active: bool) -> void:
	node.set_process(active)
	node.set_physics_process(active)
	node.set_process_input(active)
	node.set_process_unhandled_input(active)
	for child in node.get_children():
		_set_branch_process(child, active)

func _register_mobile_scroll(scroll: ScrollContainer, axis: String) -> void:
	if mobile_scroll_system != null and input_mode.is_touch_mode():
		mobile_scroll_system.register_scroll(scroll, axis)

func _configure_mobile_scroll() -> void:
	if mobile_scroll_system == null:
		return
	var preview := input_mode.is_touch_mode() and not input_mode.is_ios_touch()
	mobile_scroll_system.configure(input_mode.is_touch_mode(), preview)

func _configure_mobile_viewport() -> void:
	if not is_inside_tree():
		return
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND if input_mode.is_touch_mode() else Window.CONTENT_SCALE_ASPECT_KEEP
