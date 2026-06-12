extends RefCounted
class_name TouchSelectionSystem

signal option_selected(option_id: String)
signal reroll_requested
signal banish_requested(option_id: String)
signal skipped
signal closed

var options: Array = []
var selected_index := 0
var rerolls_remaining := 0
var banishes_remaining := 0
var can_skip := false

func configure(values: Array, rerolls: int = 0, banishes: int = 0, skip_allowed: bool = false) -> void:
	options = values.duplicate(true)
	selected_index = 0
	rerolls_remaining = maxi(0, rerolls)
	banishes_remaining = maxi(0, banishes)
	can_skip = skip_allowed

func select_index(index: int) -> String:
	if index < 0 or index >= options.size():
		return ""
	selected_index = index
	var option: Dictionary = options[index]
	var option_id := String(option.get("uid", option.get("id", "")))
	if option_id != "":
		option_selected.emit(option_id)
	return option_id

func select_id(option_id: String) -> bool:
	for index in range(options.size()):
		var option: Dictionary = options[index]
		if String(option.get("uid", option.get("id", ""))) == option_id:
			select_index(index)
			return true
	return false

func request_reroll() -> bool:
	if rerolls_remaining <= 0:
		return false
	rerolls_remaining -= 1
	reroll_requested.emit()
	return true

func request_banish() -> bool:
	if banishes_remaining <= 0 or options.is_empty():
		return false
	banishes_remaining -= 1
	var option: Dictionary = options[selected_index]
	var option_id := String(option.get("uid", option.get("id", "")))
	banish_requested.emit(option_id)
	return true

func request_skip() -> bool:
	if not can_skip:
		return false
	skipped.emit()
	return true

func request_close() -> void:
	closed.emit()
