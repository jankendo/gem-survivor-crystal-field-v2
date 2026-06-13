extends Control
class_name ResultView

const JaText = preload("res://scripts/ui/JaText.gd")
const CrystalButtonScript = preload("res://scripts/ui/components/CrystalButton.gd")
const InputModeSystemScript = preload("res://scripts/systems/InputModeSystem.gd")
const MobileSafeAreaSystemScript = preload("res://scripts/systems/MobileSafeAreaSystem.gd")
const MobileScrollSystemScript = preload("res://scripts/systems/MobileScrollSystem.gd")

signal retry_requested
signal title_requested
signal character_requested
signal shop_requested
signal collection_requested

var lines: Label
var score_line: Label
var best_update_label: Label
var scroll: ScrollContainer
var input_mode = InputModeSystemScript.new()
var mobile_safe_area = MobileSafeAreaSystemScript.new()
var mobile_scroll_system

func _ready() -> void:
	var settings: Dictionary = SaveSystem.new().load_data().get("settings", {})
	input_mode.configure(settings)
	mobile_scroll_system = MobileScrollSystemScript.new()
	add_child(mobile_scroll_system)
	mobile_scroll_system.configure(input_mode.is_touch_mode(), input_mode.is_touch_mode() and not input_mode.is_ios_touch())
	var bg = ColorRect.new()
	bg.color = Color(0.018, 0.024, 0.040)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center = VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	var viewport_size := get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	var safe := mobile_safe_area.safe_rect(viewport_size, float(settings.get("safe_area_margin", 0.0)))
	center.offset_left = maxf(36.0, safe.position.x)
	center.offset_right = -maxf(36.0, viewport_size.x - safe.end.x)
	center.offset_top = maxf(24.0, safe.position.y)
	center.offset_bottom = -maxf(24.0, viewport_size.y - safe.end.y)
	center.add_theme_constant_override("separation", 10)
	add_child(center)

	var title = Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = "ゲームオーバー"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42 if input_mode.is_touch_mode() else 56)
	title.add_theme_color_override("font_color", Color(1.0, 0.44, 0.32))
	center.add_child(title)

	score_line = Label.new()
	score_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_line.add_theme_font_size_override("font_size", 34 if input_mode.is_touch_mode() else 42)
	score_line.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32))
	center.add_child(score_line)

	best_update_label = Label.new()
	best_update_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	best_update_label.visible = false
	best_update_label.text = "最高スコア更新！"
	best_update_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_update_label.add_theme_font_size_override("font_size", 30)
	best_update_label.add_theme_color_override("font_color", Color(0.66, 1.0, 0.62))
	center.add_child(best_update_label)

	scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	center.add_child(scroll)
	if input_mode.is_touch_mode():
		mobile_scroll_system.register_scroll(scroll, MobileScrollSystemScript.AXIS_VERTICAL)

	lines = Label.new()
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.custom_minimum_size.x = 0 if input_mode.is_touch_mode() else 880
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lines.add_theme_font_size_override("font_size", 20)
	lines.add_theme_color_override("font_color", Color(0.86, 0.92, 0.98))
	lines.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(lines)

	var row = GridContainer.new()
	row.columns = 3 if input_mode.is_touch_mode() else 5
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("h_separation", 12)
	row.add_theme_constant_override("v_separation", 10)
	center.add_child(row)
	var retry_button = CrystalButtonScript.new()
	retry_button.setup("もう一度", Color(0.52, 1.0, 1.0), Vector2(160, 56 if input_mode.is_touch_mode() else 48))
	retry_button.pressed.connect(func(): retry_requested.emit())
	row.add_child(retry_button)
	var character_button = CrystalButtonScript.new()
	character_button.setup("キャラ変更", Color(0.70, 0.86, 1.0), Vector2(160, 56 if input_mode.is_touch_mode() else 48))
	character_button.pressed.connect(func(): character_requested.emit())
	row.add_child(character_button)
	var shop_button = CrystalButtonScript.new()
	shop_button.setup("強化へ", Color(1.0, 0.82, 0.34), Vector2(160, 56 if input_mode.is_touch_mode() else 48))
	shop_button.pressed.connect(func(): shop_requested.emit())
	row.add_child(shop_button)
	var collection_button = CrystalButtonScript.new()
	collection_button.setup("図鑑へ", Color(0.58, 1.0, 0.74), Vector2(160, 56 if input_mode.is_touch_mode() else 48))
	collection_button.pressed.connect(func(): collection_requested.emit())
	row.add_child(collection_button)
	var title_button = CrystalButtonScript.new()
	title_button.setup("タイトルへ", Color(1.0, 0.58, 0.42), Vector2(160, 56 if input_mode.is_touch_mode() else 48))
	title_button.pressed.connect(func(): title_requested.emit())
	row.add_child(title_button)
	if input_mode.keyboard_hints_allowed():
		var prompt = Label.new()
		prompt.text = "Enter：もう一度　Esc：タイトルへ"
		prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prompt.add_theme_font_size_override("font_size", 18)
		prompt.add_theme_color_override("font_color", Color(0.99, 0.76, 0.31))
		center.add_child(prompt)

func _unhandled_input(event: InputEvent) -> void:
	if input_mode.is_ios_touch():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER:
			retry_requested.emit()
		elif event.keycode == KEY_ESCAPE:
			title_requested.emit()

func show_summary(summary: Dictionary) -> void:
	if lines == null:
		await ready
	var score = int(summary.get("score", 0))
	var best = int(summary.get("best_score", score))
	var delta = int(summary.get("best_delta", maxi(best - score, 0)))
	best_update_label.visible = bool(summary.get("best_updated", false))
	score_line.text = "スコア：%s" % JaText.format_int(score)
	lines.text = "\n".join([
		"キャラクター：%s" % String(summary.get("character_name", "探鉱者ノア")),
		"マップシード：%s" % String(summary.get("map_seed_text", summary.get("map_seed", "ランダム"))),
		"生存時間：%s" % JaText.format_time(float(summary.get("survival_time", 0.0))),
		"称号：%s" % " / ".join(summary.get("title_badges", ["クリスタル挑戦者"])),
		"結果スタンプ：%s" % _join_or_none(summary.get("challenge_stamps", [])),
		"獲得クリスタル貨：+%s（所持 %s）" % [
			JaText.format_int(int(summary.get("currency_earned", 0))),
			JaText.format_int(int(summary.get("currency_total", 0)))
		],
		"新規実績：%s" % _join_or_none(summary.get("quests_completed", [])),
		"新キャラ解放：%s" % _name_list(summary.get("characters_unlocked", []), "res://data/characters.json"),
		"新武器解放：%s" % _name_list(summary.get("weapons_unlocked", []), "res://data/weapons.json"),
		"新パッシブ解放：%s" % _name_list(summary.get("passives_unlocked", []), "res://data/passives.json"),
		"熟練：Lv%d / %sPt" % [
			int(summary.get("mastery", {}).get("level", 0)),
			JaText.format_int(int(summary.get("mastery", {}).get("points", 0)))
		],
		"撃破数：%s" % JaText.format_int(int(summary.get("kills", 0))),
		"到達Lv：%d" % int(summary.get("level", 1)),
		"最大武器：%s" % String(summary.get("max_weapon", "魔弾 Lv1")),
		"進化武器数：%d" % int(summary.get("evolved_weapon_count", 0)),
		"過充電数：%d" % int(summary.get("overclock_count", 0)),
		"発動ビルド相性：%s" % _join_or_none(summary.get("synergy_history", summary.get("active_synergies", []))),
		"探索ドロップ：%d個 / ギミック発動：%d回" % [int(summary.get("field_drops_collected", 0)), int(summary.get("field_gimmicks_triggered", 0))],
		"動的ドロップ出現：%d個" % int(summary.get("dynamic_drops_spawned", 0)),
		"探索ランク：%s / 探索スコア：%d" % [String(summary.get("exploration_rank", "D")), int(summary.get("exploration_score", 0))],
		"探索報酬：+%d%% / チェーン貨ボーナス：+%d" % [int(round(float(summary.get("exploration_currency_bonus", 0.0)) * 100.0)), int(summary.get("exploration_chain_currency_bonus", 0))],
		"最大探索チェーン：x%d / 遠方回収：%d / 危険地帯回収：%d" % [int(summary.get("exploration_chain_max", 0)), int(summary.get("exploration_far_pickups", 0)), int(summary.get("exploration_danger_pickups", 0))],
		"イベント成功：%d / 失敗：%d" % [int(summary.get("field_event_successes", 0)), int(summary.get("field_event_failures", 0))],
		"近接撃破：%d / 感電爆発：%d" % [int(summary.get("melee_rush_kills", 0)), int(summary.get("shock_explosions", 0))],
		"契約：%s" % _contract_label(summary.get("rune_contracts", [])),
		"フィールドイベント：%d回" % int(summary.get("field_event_count", 0)),
		"回収ドローン：%d回" % int(summary.get("recall_drone_activations", 0)),
		"回収ジェム：%s" % JaText.format_int(int(summary.get("gems_collected", 0))),
		"ジェムEXP：%s" % JaText.format_int(int(summary.get("gem_exp_collected", 0))),
		"最大コンボ：%s" % JaText.format_int(int(summary.get("max_combo", 0))),
		"破壊クリスタル：%s" % JaText.format_int(int(summary.get("crystals_destroyed", 0))),
		"開封宝箱：%s" % JaText.format_int(int(summary.get("chests_opened", 0))),
		"最大ダメージ：%s" % JaText.format_int(int(summary.get("max_damage", 0))),
		"最高スコア：%s" % JaText.format_int(best),
		"自己ベストまであと：%s" % JaText.format_int(delta),
		"死因：%s" % String(summary.get("reason", "敵に囲まれました"))
	])

func _contract_label(value) -> String:
	if value is Array and not value.is_empty():
		return " / ".join(value)
	return "なし"

func _join_or_none(value) -> String:
	if value is Array and not value.is_empty():
		var parts: Array = []
		for item in value:
			parts.append(String(item))
		return " / ".join(parts)
	return "なし"

func _name_list(value, path: String) -> String:
	if not value is Array or value.is_empty():
		return "なし"
	var defs: Dictionary = {}
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
		if parsed is Dictionary:
			defs = parsed
	var names: Array = []
	for raw_id in value:
		var id = String(raw_id)
		names.append(String(defs.get(id, {}).get("name_ja", id)))
	return " / ".join(names)
