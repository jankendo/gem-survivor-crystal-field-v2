extends RefCounted
class_name JaText

const TITLE = "ジェムサバイバー：クリスタルフィールド"
const SUBTITLE = "壊して、吸って、限界を超えろ。"
const HELP_BODY = "遊び方\n\n1. WASD / 矢印キーで移動します。\n2. 攻撃は自動で行われます。\n3. 敵やクリスタル壁を壊すとジェムや宝箱が出ます。\n4. ジェムを吸収します。1.5秒以内に吸収し続けるとコンボが伸びます。\n5. レベルアップしたら3つの強化から選びます。候補が尽きても無限強化が出ます。\n6. 赤紫の危険地帯は敵が増えますが、ジェムとスコアも増えます。\n7. 回収ドローンがREADYならRで周囲のジェムを一気に吸えます。\n8. Escでポーズし、武器・パッシブ・進化条件・契約・設定を確認できます。\n9. 敵に触れるとHPが減り、0になると終了です。\n\nコツ：\n壁を壊して道と報酬を作り、危険地帯で高スコアを狙りましょう。\nクリスタル貨でキャラ解放と永続強化を進めると、次のランが少し楽になります。\n\nEnter：開始\nH：遊び方"
const CONTROLS = "WASD / 矢印：移動　R：回収ドローン　1/2/3：強化選択　Esc：ポーズ"

static func reward_name(reward: Dictionary) -> String:
	var level_text = " Lv%d" % int(reward.get("next_level", 1)) if reward.has("next_level") else ""
	return "%s%s" % [String(reward.get("name_ja", reward.get("name", ""))), level_text]

static func reward_description(reward: Dictionary) -> String:
	return String(reward.get("description_ja", reward.get("description", "")))

static func format_int(value: int) -> String:
	var text = str(value)
	var result = ""
	var count = 0
	for i in range(text.length() - 1, -1, -1):
		result = text.substr(i, 1) + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "," + result
	return result

static func format_time(seconds: float) -> String:
	var total = int(floor(seconds))
	return "%02d:%02d" % [int(floor(float(total) / 60.0)), total % 60]
