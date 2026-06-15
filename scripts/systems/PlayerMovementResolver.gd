extends RefCounted
class_name PlayerMovementResolver

const SmoothWallSlideSystemScript = preload("res://scripts/systems/SmoothWallSlideSystem.gd")

var slide_system = SmoothWallSlideSystemScript.new()

func resolve(state, origin: Vector2, velocity: Vector2, delta: float, radius: float = 18.0) -> Dictionary:
	return slide_system.move(state, origin, velocity * delta, radius)
