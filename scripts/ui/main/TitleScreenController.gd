extends RefCounted
class_name TitleScreenController

func actions() -> Array:
	return [
		{"id": "start", "label": "ゲーム開始", "tier": 1, "accent": Color(0.52, 1.0, 1.0)},
		{"id": "characters", "label": "キャラクター選択", "tier": 2, "accent": Color(0.70, 0.86, 1.0)},
		{"id": "shop", "label": "解放 / 強化", "tier": 2, "accent": Color(1.0, 0.82, 0.28)},
		{"id": "loadout", "label": "武器・パッシブ管理", "tier": 2, "accent": Color(0.58, 1.0, 0.74)},
		{"id": "collection", "label": "図鑑", "tier": 3, "accent": Color(0.70, 0.86, 1.0)},
		{"id": "quests", "label": "実績", "tier": 3, "accent": Color(0.48, 1.0, 0.66)},
		{"id": "settings", "label": "設定", "tier": 4, "accent": Color(0.70, 0.78, 1.0)},
		{"id": "help", "label": "遊び方", "tier": 4, "accent": Color(0.70, 0.78, 1.0)},
		{"id": "reset", "label": "セーブ初期化", "tier": 4, "accent": Color(1.0, 0.34, 0.42), "danger": true},
		{"id": "quit", "label": "終了", "tier": 4, "accent": Color(0.50, 0.58, 0.70)}
	]

func status_lines(save_data: Dictionary, selected_name: String, blessing_name: String) -> Array:
	var stats: Dictionary = save_data.get("stats", {})
	return [
		"現在：%s / %s" % [selected_name, blessing_name],
		"クリスタル貨：%s" % str(int(save_data.get("crystal_currency", 0))),
		"最高生存：%.0f秒" % float(stats.get("best_survival", 0.0))
	]
