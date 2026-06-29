extends RefCounted
class_name SettingsScrollState

var valid := false
var scroll_vertical := 0
var anchor_id := ""

func capture(scroll: ScrollContainer, preferred_anchor: String = "") -> void:
	if scroll == null:
		return
	valid = true
	scroll_vertical = scroll.scroll_vertical
	anchor_id = preferred_anchor

func restore(scroll: ScrollContainer, bindings: Dictionary = {}) -> void:
	if not valid or scroll == null:
		return
	if anchor_id != "" and bindings.has(anchor_id):
		var target: Control = bindings[anchor_id]
		var delta := target.global_position.y - scroll.global_position.y
		scroll.scroll_vertical = maxi(0, scroll.scroll_vertical + int(delta))
		target.grab_focus()
	else:
		scroll.scroll_vertical = scroll_vertical
	valid = false
