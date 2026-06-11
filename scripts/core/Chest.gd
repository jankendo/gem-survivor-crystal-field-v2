extends RefCounted
class_name Chest

var position: Vector2 = Vector2.ZERO
var collected: bool = false
var pulse: float = 0.0
var rarity: String = "normal"
var source: String = ""
var age: float = 0.0
var ttl: float = 300.0

func _init(pos: Vector2 = Vector2.ZERO, chest_rarity: String = "normal", chest_source: String = "") -> void:
	position = pos
	rarity = chest_rarity
	source = chest_source
