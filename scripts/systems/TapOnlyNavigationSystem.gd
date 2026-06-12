extends RefCounted
class_name TapOnlyNavigationSystem

const BANNED_TOUCH_TEXT := [
	"Press Enter",
	"Enter",
	"Esc",
	"1/2/3",
	"Fキー",
	"Rキー",
	"Shift",
	"Space",
	"キーボード",
	"右クリック"
]

func audit_screen(root: Node, require_back_or_confirm: bool = true) -> Array:
	var issues: Array = []
	var actionable := 0
	for node in _descendants(root):
		if node is BaseButton and node.visible and not node.disabled:
			var control := node as Control
			var rect := control.get_rect()
			var width := maxf(rect.size.x, control.custom_minimum_size.x)
			var height := maxf(rect.size.y, control.custom_minimum_size.y)
			var expands_horizontally := control.size_flags_horizontal != Control.SIZE_SHRINK_BEGIN
			if height >= 44.0 and (width >= 44.0 or expands_horizontally):
				actionable += 1
		if node is Label or node is RichTextLabel or node is Button:
			var text := String(node.text)
			for banned in BANNED_TOUCH_TEXT:
				if text.contains(banned):
					issues.append("禁止入力文言: %s" % banned)
	if require_back_or_confirm and actionable == 0:
		issues.append("44pt相当以上のタップ可能操作がありません")
	return issues

func sanitize_touch_text(value: String) -> String:
	var result := value
	for banned in BANNED_TOUCH_TEXT:
		result = result.replace(banned, "")
	return result.strip_edges()

func _descendants(root: Node) -> Array:
	var result: Array = []
	var pending: Array = [root]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		result.append(current)
		for child in current.get_children():
			pending.append(child)
	return result
