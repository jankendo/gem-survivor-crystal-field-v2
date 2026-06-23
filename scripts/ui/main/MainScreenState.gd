extends RefCounted
class_name MainScreenState

const SCREEN_TITLE := "title"
const SCREEN_CHARACTERS := "characters"
const SCREEN_SHOP := "shop"
const SCREEN_COLLECTION := "collection"
const SCREEN_QUESTS := "quests"
const SCREEN_SETTINGS := "settings"

var current := SCREEN_TITLE
var previous := ""

func set_screen(value: String) -> void:
	previous = current
	current = value

func is_menu_screen() -> bool:
	return current in [SCREEN_TITLE, SCREEN_CHARACTERS, SCREEN_SHOP, SCREEN_COLLECTION, SCREEN_QUESTS, SCREEN_SETTINGS]
