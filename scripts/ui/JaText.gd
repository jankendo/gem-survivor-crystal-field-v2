extends RefCounted
class_name JaText

const TITLE = "ジェムサバイバー：クリスタルフィールド"
const SUBTITLE = "結晶迷宮を探索し、危険な報酬でビルドを完成させる。"
const HELP_BODY = "遊び方\n\n1. WASD / 矢印キーで移動します。\n2. 攻撃は自動で行われます。\n3. 敵やクリスタル壁を壊すとジェムや宝箱が出ます。\n4. ジェムを吸収してレベルアップし、武器・パッシブ・進化の形を作ります。\n5. 遠くの部屋や危険地帯ほど強い報酬が見つかります。\n6. 危険な報酬を追うか、安全に育てるかを選びます。\n7. 回収ドローンが使用可能ならRで周囲のジェムを一気に吸えます。\n8. Escでポーズし、武器・パッシブ・進化条件・契約・設定を確認できます。\n9. ラン後はクリスタル貨でショップ商品を購入し、次の候補を増やします。\n\nコツ：\n壁を壊して道と報酬を作り、危険を選ぶほどラッシュとビルド完成が加速します。\nスターター以外の永久解放はショップ購入後に次回ランから候補に出現します。\n\nEnter：開始\nH：遊び方"
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
