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
const CollectionFilterSystemScript := preload("res://scripts/systems/CollectionFilterSystem.gd")
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
var collection_filter_system = CollectionFilterSystemScript.new()
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
var collection_tabs := ["characters", "weapons", "passives", "evolutions", "enemies", "bosses", "field_drops", "field_gimmicks", "field_events"]
var collection_tab_names := ["キャラ", "武器", "パッシブ", "進化", "敵", "ボス", "ドロップ", "ギミック", "イベント"]
var blessing_expanded := false

func _ready() -> void:
	_sync_from_save()
	show_title()

func _unhandled_input(event: InputEvent) -> void:
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
	_add_label(root, JaText.TITLE, 42, Color(0.94, 0.98, 1.0))
	_add_label(root, JaText.SUBTITLE, 20, Color(0.68, 0.84, 1.0))

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	root.add_child(body)

	var menu := VBoxContainer.new()
	menu.custom_minimum_size = Vector2(330, 0)
	menu.add_theme_constant_override("separation", 8)
	body.add_child(menu)
	_add_menu_button(menu, "開始", request_start, Color(0.52, 1.0, 1.0))
	_add_menu_button(menu, "キャラクター選択", show_character_select)
	_add_menu_button(menu, "解放 / 強化", show_shop, Color(1.0, 0.82, 0.28))
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
	_add_label(info_box, "マウスで開始/選択できます。Enter/C/U/L/A/S/R/H/I/Esc のキーボード操作も有効です。", 17, Color(0.66, 0.76, 0.88), HORIZONTAL_ALIGNMENT_LEFT)

func request_start() -> void:
	if save_system.load_help_seen():
		start_game()
	else:
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
	_add_label(root, "遊び方", 42, Color(0.94, 0.98, 1.0))
	_add_label(root, JaText.HELP_BODY, 20, Color(0.80, 0.88, 0.96))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	root.add_child(row)
	_add_menu_button(row, "タイトルへ", show_title, Color(0.42, 0.82, 1.0))
	_add_menu_button(row, "開始", accept_help, Color(0.52, 1.0, 1.0))

func accept_help() -> void:
	save_system.save_help_seen(true)
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
	_add_label(parent, String(selected.get("description_ja", "")), 16, Color(0.82, 0.88, 0.96), HORIZONTAL_ALIGNMENT_LEFT)
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
		button.setup("%s\n%s" % [String(blessing.get("name_ja", blessing_id)), String(blessing.get("description_ja", ""))], Color(1.0, 0.86, 0.28) if blessing_id == selected_blessing_id else Color(0.46, 0.78, 1.0), Vector2(158, 72))
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
	var category_ids := shop_category_system.category_ids()
	shop_category_index = clampi(shop_category_index, 0, maxi(0, category_ids.size() - 1))
	var category_tabs := GridContainer.new()
	category_tabs.columns = 5
	category_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_tabs.add_theme_constant_override("h_separation", 8)
	category_tabs.add_theme_constant_override("v_separation", 6)
	root.add_child(category_tabs)
	for i in range(category_ids.size()):
		var category_id = String(category_ids[i])
		var tab = CrystalButtonScript.new()
		tab.setup(shop_category_system.category_name(category_id), Color(1.0, 0.84, 0.30) if i == shop_category_index else Color(0.42, 0.82, 1.0), Vector2(164, 42))
		tab.pressed.connect(_select_shop_category.bind(i))
		category_tabs.add_child(tab)
	var current_category = String(category_ids[shop_category_index]) if not category_ids.is_empty() else "characters"
	_add_label(root, "おすすめ：%s" % shop_category_system.recommendation(current_category), 17, Color(0.58, 1.0, 0.78), HORIZONTAL_ALIGNMENT_LEFT)
	var scroll := _scroll(root)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size.x = 900
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
			button.setup("%s　%s　費用：%s" % [meta_system.display_name(char_id, save_data), "解放済み" if unlocked else String(data.get("role_ja", "")), JaText.format_int(cost)], Color(1.0, 0.82, 0.36), Vector2(0, 58))
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
			var condition_text = "条件達成" if condition_ok else "条件：%s %s" % [String(item.get("required_stat", "")), str(item.get("required_value", 0))]
			var text = "%s　Lv%d/%d\n%s　次：%s　費用：%s\nおすすめ：%s　%s" % [
				String(item.get("name_ja", sink_id)), current, max_level,
				String(item.get("description_ja", "")), String(item.get("effect_per_level_ja", "")),
				"MAX" if current >= max_level else JaText.format_int(cost),
				String(item.get("recommend_ja", "")), condition_text
			]
			var button = CrystalButtonScript.new()
			button.setup(text, Color(0.52, 1.0, 0.76) if condition_ok else Color(0.58, 0.62, 0.72), Vector2(0, 88))
			button.disabled = current >= max_level or not condition_ok or int(save_data.get("crystal_currency", 0)) < cost
			button.pressed.connect(_purchase_currency_sink.bind(sink_id))
			body.add_child(button)

func _select_shop_category(index: int) -> void:
	shop_category_index = clampi(index, 0, shop_category_system.category_ids().size() - 1)
	show_shop()

func show_collection() -> void:
	_sync_from_save()
	_clear()
	screen_mode = "collection"
	title_visible = false
	help_visible = false
	_add_background(Color(0.028, 0.036, 0.054))
	var root := _page_box(42, 26, 42, 30)
	_add_top_bar(root, "図鑑", "カテゴリをクリックまたは←/→で切替", show_title)
	var tabs := GridContainer.new()
	tabs.columns = 5
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_theme_constant_override("h_separation", 8)
	tabs.add_theme_constant_override("v_separation", 6)
	root.add_child(tabs)
	for i in range(collection_tabs.size()):
		var button = CrystalButtonScript.new()
		button.setup(String(collection_tab_names[i]), Color(1.0, 0.86, 0.28) if i == collection_tab_index else Color(0.42, 0.82, 1.0), Vector2(150, 40))
		button.pressed.connect(_select_collection_tab.bind(i))
		tabs.add_child(button)
	var filters := GridContainer.new()
	filters.columns = 7
	filters.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filters.add_theme_constant_override("h_separation", 6)
	filters.add_theme_constant_override("v_separation", 5)
	root.add_child(filters)
	for i in range(collection_filter_system.FILTER_IDS.size()):
		var filter_button = CrystalButtonScript.new()
		filter_button.setup(String(collection_filter_system.FILTER_NAMES[i]), Color(0.58, 1.0, 0.76) if i == collection_filter_index else Color(0.34, 0.60, 0.82), Vector2(112, 34))
		filter_button.pressed.connect(_select_collection_filter.bind(i))
		filters.add_child(filter_button)
	var sorts := HBoxContainer.new()
	sorts.add_theme_constant_override("separation", 6)
	root.add_child(sorts)
	_add_label(sorts, "並び替え", 15, Color(0.82, 0.88, 0.96), HORIZONTAL_ALIGNMENT_LEFT)
	for i in range(collection_filter_system.SORT_IDS.size()):
		var sort_button = CrystalButtonScript.new()
		sort_button.setup(String(collection_filter_system.SORT_NAMES[i]), Color(1.0, 0.84, 0.30) if i == collection_sort_index else Color(0.42, 0.82, 1.0), Vector2(118, 34))
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
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.custom_minimum_size.x = 940
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
	var scroll := _scroll(root)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size.x = 920
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	for id in meta_system.quests.keys():
		var quest_id := String(id)
		var quest: Dictionary = meta_system.quests[quest_id]
		var done := bool(completed.get(quest_id, false))
		var card = AchievementCardScript.new()
		card.setup(String(quest.get("name_ja", quest_id)), String(quest.get("description_ja", "")), _reward_text(quest.get("reward", {})), done)
		body.add_child(card)

func show_settings() -> void:
	_sync_from_save()
	_clear()
	screen_mode = "settings"
	title_visible = false
	help_visible = false
	_add_background(Color(0.028, 0.038, 0.060))
	var root := _page_box(90, 40, 90, 46)
	_add_top_bar(root, "設定", "マウスで変更できます。シード空欄ならランダム。", show_title)
	var settings: Dictionary = save_data.get("settings", {})
	var row := GridContainer.new()
	row.columns = 2
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size.x = 840
	row.add_theme_constant_override("h_separation", 12)
	row.add_theme_constant_override("v_separation", 10)
	root.add_child(row)
	_add_toggle(row, "画面揺れ", "screen_shake", bool(settings.get("screen_shake", true)))
	_add_toggle(row, "ダメージ数字", "damage_numbers", bool(settings.get("damage_numbers", true)))
	_add_toggle(row, "ジェム吸収音", "gem_sound", bool(settings.get("gem_sound", true)))
	_add_toggle(row, "無限強化自動", "auto_infinite", bool(settings.get("auto_infinite", true)))
	_add_toggle(row, "自動回収ドローン", "auto_recall_drone", bool(settings.get("auto_recall_drone", false)))
	_add_toggle(row, "フルスクリーン", "fullscreen", bool(settings.get("fullscreen", false)))
	_add_toggle(row, "長押し倍速", "speed_hold_enabled", bool(settings.get("speed_hold_enabled", true)))
	_add_toggle(row, "通知ログ", "notification_log_enabled", bool(settings.get("notification_log_enabled", true)))
	_add_toggle(row, "武器HUD", "weapon_hud_enabled", bool(settings.get("weapon_hud_enabled", true)))
	_add_toggle(row, "パッシブHUD", "passive_hud_enabled", bool(settings.get("passive_hud_enabled", true)))
	_add_choice(row, "倍速キー", "speed_hold_key", String(settings.get("speed_hold_key", "left_shift")), ["left_shift", "tab", "space", "middle_mouse"])
	_add_choice(row, "倍速倍率", "speed_multiplier", float(settings.get("speed_multiplier", 2.0)), [1.5, 2.0])
	_add_choice(row, "ボス警告", "boss_alert_intensity", String(settings.get("boss_alert_intensity", "strong")), ["normal", "strong"])
	_add_choice(row, "エフェクト量", "effect_density", String(settings.get("effect_density", "normal")), ["low", "normal", "high"])
	_add_slider(root, "BGM音量", "bgm_volume", float(settings.get("bgm_volume", 0.85)))
	_add_slider(root, "SE音量", "se_volume", float(settings.get("se_volume", 0.90)))
	_add_slider(root, "UI拡大率", "ui_scale", float(settings.get("ui_scale", 1.0)), 0.85, 1.25)
	var seed_row := HBoxContainer.new()
	seed_row.add_theme_constant_override("separation", 10)
	root.add_child(seed_row)
	_add_label(seed_row, "シード入力", 18, Color(0.88, 0.94, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	seed_input = LineEdit.new()
	seed_input.text = String(settings.get("seed_text", ""))
	seed_input.placeholder_text = "空欄ならランダム"
	seed_input.custom_minimum_size = Vector2(360, 42)
	seed_input.text_submitted.connect(_set_seed_text)
	seed_row.add_child(seed_input)
	_add_menu_button(seed_row, "保存", func(): _set_seed_text(seed_input.text), Color(0.52, 1.0, 1.0))
	_add_menu_button(root, "セーブ初期化へ", show_reset, Color(1.0, 0.34, 0.42), true)

func show_reset() -> void:
	_clear()
	screen_mode = "reset"
	title_visible = false
	help_visible = false
	_add_background(Color(0.040, 0.026, 0.030))
	var root := _page_box(170, 82, 170, 82)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	_add_label(root, "セーブ初期化", 38, Color(1.0, 0.54, 0.42))
	_add_label(root, "進行状況・通貨・解放・図鑑を初期化します。\n設定と遊び方既読だけは残ります。\n実行には RESET または 初期化 の入力が必要です。", 21, Color(0.94, 0.88, 0.86))
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
	_add_menu_button(row, "初期化を実行", func(): _confirm_reset(reset_input.text), Color(1.0, 0.34, 0.42), true)
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
	var meta_result: Dictionary = meta_system.update_after_run(save_system, summary)
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

func _toggle_auto_infinite() -> void:
	_update_setting("auto_infinite", not auto_infinite_enabled)

func _update_setting(key: String, value) -> void:
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
	button.setup(label, accent, Vector2(0, 48), danger)
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
	button.setup("%s: %s" % [title, str(value)], Color(0.42, 0.82, 1.0), Vector2(0, 48))
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
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.offset_left = -120 + i * 170
		rect.offset_top = 80 + i * 38
		rect.offset_right = -840 + i * 170
		rect.offset_bottom = -520 + i * 38
		add_child(rect)

func _add_background(color: Color) -> void:
	var bg := ColorRect.new()
	bg.color = color
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

func _page_box(left: int, top: int, right: int, bottom: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = left
	box.offset_top = top
	box.offset_right = -right
	box.offset_bottom = -bottom
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	return box

func _scroll(parent: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	ui_layout_fix.prepare_scroll(scroll)
	parent.add_child(scroll)
	return scroll

func _add_label(parent: Control, text: String, size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = text
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
		"弱点：%s" % String(data.get("weakness_ja", "なし"))
	]
	if not unlocked:
		lines.append(meta_system.unlock_text(character_id, save_data))
	return "\n".join(lines)

func _json_dict(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func _clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	current_screen = null
