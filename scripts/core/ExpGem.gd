extends RefCounted
class_name ExpGem

var position: Vector2 = Vector2.ZERO
var value: int = 1
var velocity: Vector2 = Vector2.ZERO
var attracting: bool = false
var radius: float = 7.0

func _init(pos: Vector2 = Vector2.ZERO, exp_value: int = 1) -> void:
	reset(pos, exp_value)

func reset(pos: Vector2 = Vector2.ZERO, exp_value: int = 1) -> void:
	position = pos
	value = exp_value
	velocity = Vector2.ZERO
	attracting = false
	radius = 7.0
