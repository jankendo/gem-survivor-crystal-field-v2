extends RefCounted
class_name NotificationLogSystem

const MAX_VISIBLE := 5
const MAX_HISTORY := 50

var enabled := true
var entries: Array = []
var history: Array = []
var visible_limit := MAX_VISIBLE

func configure(settings: Dictionary, platform: String = OS.get_name()) -> void:
	enabled = bool(settings.get("notification_log_enabled", true))
	var amount := String(settings.get("notification_log_amount", "standard"))
	visible_limit = 2 if amount == "low" else (3 if platform == "iOS" or String(settings.get("touch_ui_mode", "auto")) == "on" else MAX_VISIBLE)

func ingest(event: Dictionary, elapsed_seconds: float) -> void:
	if not enabled:
		return
	var text = _event_text(event)
	if text == "":
		return
	var entry = {
		"time": elapsed_seconds,
		"category": _category(event),
		"priority": _priority(event),
		"text": text,
		"life": 7.0
	}
	entries.push_front(entry)
	history.push_front(entry.duplicate(true))
	if entries.size() > visible_limit:
		entries.resize(visible_limit)
	if history.size() > MAX_HISTORY:
		history.resize(MAX_HISTORY)

func tick(delta: float) -> void:
	for entry in entries.duplicate():
		entry["life"] = float(entry.get("life", 0.0)) - delta
		if float(entry.get("life", 0.0)) <= 0.0:
			entries.erase(entry)

func visible_text() -> String:
	var lines: Array = []
	for entry in entries:
		lines.append("[%s] %s" % [_category_label(String(entry.get("category", "info"))), String(entry.get("text", ""))])
	return "\n".join(lines)

func history_text() -> String:
	if history.is_empty():
		return "通知履歴はありません。"
	var lines: Array = []
	for entry in history:
		var seconds = int(entry.get("time", 0.0))
		lines.append("%02d:%02d  [%s] %s" % [seconds / 60, seconds % 60, _category_label(String(entry.get("category", "info"))), String(entry.get("text", ""))])
	return "\n".join(lines)

func _event_text(event: Dictionary) -> String:
	var type = String(event.get("type", ""))
	match type:
		"boss_warning":
			return String(event.get("message", "ボス接近"))
		"boss_spawn":
			return "%s 出現" % String(event.get("name", "ボス"))
		"evolution":
			return "%sへ進化" % String(event.get("name", "武器"))
		"level_up":
			return "レベルアップ"
		"chest_drop":
			return "宝箱が出現"
		"chest_open":
			return String(event.get("message", "宝箱を開封"))
		"field_event_start":
			return "イベント開始: %s" % String(event.get("name", "フィールドイベント"))
		"field_event_success":
			return "イベント成功: %s" % String(event.get("name", "フィールドイベント"))
		"field_event_failed":
			return "イベント未達成: %s" % String(event.get("name", "フィールドイベント"))
		"room_discovered":
			return "新エリア: %s" % String(event.get("name", event.get("terrain", "不明")))
		"dynamic_drop_spawn":
			return "希少物資: %s" % String(event.get("name", event.get("id", "")))
		"crystal_overdrive":
			return "クリスタルオーバードライブ"
		"recall_drone_ready":
			return "回収ドローン READY"
		"player_damage":
			return "被ダメージ %d" % int(event.get("damage", 0)) if int(event.get("damage", 0)) >= 20 else ""
	return ""

func _category(event: Dictionary) -> String:
	var type = String(event.get("type", ""))
	if type.begins_with("boss"):
		return "boss"
	if type.begins_with("field_event") or type == "room_discovered":
		return "exploration"
	if type in ["evolution", "level_up", "crystal_overdrive"]:
		return "growth"
	if type in ["player_damage"]:
		return "danger"
	return "reward"

func _priority(event: Dictionary) -> int:
	var type = String(event.get("type", ""))
	return 100 if type in ["boss_warning", "boss_spawn"] else (80 if type in ["evolution", "field_event_start", "player_damage"] else 50)

func _category_label(category: String) -> String:
	match category:
		"boss":
			return "ボス"
		"exploration":
			return "探索"
		"growth":
			return "強化"
		"danger":
			return "危険"
		_:
			return "報酬"
