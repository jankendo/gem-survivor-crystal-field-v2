extends RefCounted
class_name ExpGem

var position: Vector2 = Vector2.ZERO
var value: int = 1
var velocity: Vector2 = Vector2.ZERO
var attracting: bool = false
var radius: float = 7.0

func _init(pos: Vector2 = Vector2.ZERO, exp_value: int = 1) -> void:
	position = pos
	value = exp_value
